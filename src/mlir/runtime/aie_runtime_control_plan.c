#include "aie_runtime_control_plan.h"

/* Pure planner: derives per-tile stream-switch ops for a row-based control
 * connection with no XAie dependency. See the header for type docs. */

/* Return the port-usage bitmap cell for a tile's master or slave domain. */
static uint16_t *acr_book_cell(acr_portbook *b, uint8_t col, uint8_t row, int is_master) {
    uint16_t(*t)[64] = is_master ? b->master_used : b->slave_used;
    return &t[row][col];
}

/* Book master/slave port index @idx on tile (col,row) for port @p. Distinct
 * port types (WEST/EAST/NORTH/SOUTH/CTRL) are independent physical ports, so the
 * booking bit folds the port type in: bit = p*3 + idx (idx < 3, 5 ports => 15
 * bits, fits uint16). Rejects double-book of the same (port,idx). */
acr_rc acr_book_port(acr_portbook *b, uint8_t col, uint8_t row, acr_port p, uint8_t idx, int is_master) {
    if (row > ACR_MAX_ROWS || col >= 64 || idx >= 3)
        return ACR_ERR_BOUNDS;
    uint16_t bit = (uint16_t)(1u << ((unsigned)p * 3u + idx));
    uint16_t *cell = acr_book_cell(b, col, row, is_master);
    if (*cell & bit)
        return ACR_ERR_PORT_CONFLICT;
    *cell |= bit;
    return ACR_OK;
}

/* Append one op, guarding the fixed capacity. */
static acr_rc acr_emit_op(acr_oplist *o, const acr_op *op) {
    if (o->n >= ACR_MAX_OPS)
        return ACR_ERR_BOUNDS;
    o->ops[o->n++] = *op;
    return ACR_OK;
}

/* Core chain derivation. @head_ingress is the slave port the *leftmost* tile
 * (col_lo) receives on: WEST for a plain chain, SOUTH when the chain head is the
 * top of the vertical spine (packet arrives from the tile below). Interior tiles
 * always ingress on WEST from their left neighbor. See acr_plan_chain for the
 * per-case (consume/forward/broadcast) encoding of design §5. */
static acr_rc acr_plan_chain_ex(acr_oplist *o, acr_portbook *b, uint8_t row, uint8_t col_lo, uint8_t col_hi,
                                int target_col, uint8_t ctrl_id, acr_port head_ingress) {
    if (col_hi < col_lo || col_hi >= 64)
        return ACR_ERR_BOUNDS;
    if (target_col >= 0 && (target_col < col_lo || target_col > col_hi))
        return ACR_ERR_BOUNDS;

    for (uint8_t c = col_lo; c <= col_hi; c++) {
        int is_target = (target_col < 0) || (c == (uint8_t)target_col);
        int has_east = (target_col < 0) ? (c < col_hi) : (c < (uint8_t)target_col);
        int consume_and_forward = is_target && has_east; /* broadcast interior */
        acr_port sport = (c == col_lo) ? head_ingress : ACR_WEST;

        /* The forwarded pass-through (forward-only) uses a distinct arbiter/msel
         * so it does not share the consume slot; consume and broadcast share
         * arb0/msel0. */
        uint8_t slot, msel, arbiter;
        if (!is_target && has_east) { /* forward-only pass-through */
            slot = 1;
            msel = 1;
            arbiter = 1;
        } else { /* consume, or consume+forward */
            slot = 0;
            msel = 0;
            arbiter = 0;
        }
        acr_rc rc;
        /* Book the ingress slave *port* (idx 0); @slot is a sub-resource of that
         * port, not a separate port. Incoming slot matches ctrl_id (full 5-bit
         * mask). Each tile taps its ingress port once here, so one booking. */
        if ((rc = acr_book_port(b, c, row, sport, 0, /*master*/ 0)) != ACR_OK)
            return rc;
        acr_op slotop = {.kind = ACR_OP_SLOT,
                         .col = c,
                         .row = row,
                         .sport = sport,
                         .sidx = 0,
                         .slot = slot,
                         .pkt_id = ctrl_id,
                         .mask = 0x1F,
                         .msel = msel,
                         .arbiter = arbiter};
        if ((rc = acr_emit_op(o, &slotop)) != ACR_OK)
            return rc;
        acr_op slaveen = {.kind = ACR_OP_SLAVE_EN, .col = c, .row = row, .sport = sport, .sidx = 0};
        if ((rc = acr_emit_op(o, &slaveen)) != ACR_OK)
            return rc;

        if (is_target) {
            if ((rc = acr_book_port(b, c, row, ACR_CTRL, 0, /*master*/ 1)) != ACR_OK)
                return rc;
            acr_op ctrlm = {.kind = ACR_OP_MASTER_EN,
                            .col = c,
                            .row = row,
                            .mport = ACR_CTRL,
                            .midx = 0,
                            .msel = 0,
                            .arbiter = 0,
                            .mselen = 1,
                            .keep_header = 1};
            if ((rc = acr_emit_op(o, &ctrlm)) != ACR_OK)
                return rc;
        }
        if (has_east) {
            /* Broadcast interior forwards on the consume slot (arb0/msel0);
             * unicast pass-through forwards on arb1/msel1. */
            uint8_t em = consume_and_forward ? 0 : msel;
            uint8_t ea = consume_and_forward ? 0 : arbiter;
            if ((rc = acr_book_port(b, c, row, ACR_EAST, 0, /*master*/ 1)) != ACR_OK)
                return rc;
            acr_op eastm = {.kind = ACR_OP_MASTER_EN,
                            .col = c,
                            .row = row,
                            .mport = ACR_EAST,
                            .midx = 0,
                            .msel = em,
                            .arbiter = ea,
                            .mselen = (uint8_t)(1u << em),
                            .keep_header = 1};
            if ((rc = acr_emit_op(o, &eastm)) != ACR_OK)
                return rc;
        }
    }
    return ACR_OK;
}

/* Public chain planner: plain horizontal chain, head tile ingresses on WEST. */
acr_rc acr_plan_chain(acr_oplist *o, acr_portbook *b, uint8_t row, uint8_t col_lo, uint8_t col_hi, int target_col,
                      uint8_t ctrl_id) {
    return acr_plan_chain_ex(o, b, row, col_lo, col_hi, target_col, ctrl_id, ACR_WEST);
}

/* Ensure the shared vertical spine (column @shim_col) reaches @row, then build
 * the EAST chain [col_lo..col_hi] on that row. Idempotent per requirement #5:
 *   - re-adding a row already in @s->rows emits nothing;
 *   - a higher row reuses the existing spine and only extends it upward.
 * Spine hops are circuit-switched pass-through (one ACR_OP_CCT per new row
 * level, SOUTH-in -> NORTH-out). The chain head (col_lo == shim_col) ingresses
 * from the spine below (SOUTH). The chain is built as the broadcast superset so
 * both broadcast and single-target transfers can flow; per-transfer intent is
 * carried by the control packet's tile address. */
acr_rc acr_plan_row_add(acr_state *s, acr_oplist *o, acr_portbook *b, uint8_t shim_col, uint8_t row, uint8_t col_lo,
                        uint8_t col_hi, uint8_t ctrl_id) {
    if (row == 0 || row > ACR_MAX_ROWS || shim_col >= 64)
        return ACR_ERR_BOUNDS;
    if (col_lo != shim_col) /* row entry is the vertical spine's left column */
        return ACR_ERR_BOUNDS;

    /* Idempotent: already configured -> emit nothing. */
    for (uint8_t i = 0; i < s->nrows; i++)
        if (s->rows[i] == row)
            return ACR_OK;

    if (s->nrows >= ACR_MAX_ROWS)
        return ACR_ERR_BOUNDS;

    /* Extend the spine upward: one circuit pass-through hop per new row level. */
    if (row > s->spine_top) {
        for (uint8_t r = (uint8_t)(s->spine_top + 1); r <= row; r++) {
            acr_op cct = {.kind = ACR_OP_CCT,
                          .col = shim_col,
                          .row = r,
                          .sport = ACR_SOUTH,
                          .sidx = 0,
                          .mport = ACR_NORTH,
                          .midx = 0};
            acr_rc rc = acr_emit_op(o, &cct);
            if (rc != ACR_OK)
                return rc;
        }
        s->spine_top = row;
    }

    /* Build the horizontal chain; head tile takes the spine input from SOUTH. */
    acr_rc rc = acr_plan_chain_ex(o, b, row, col_lo, col_hi, /*broadcast*/ -1, ctrl_id, ACR_SOUTH);
    if (rc != ACR_OK)
        return rc;

    s->rows[s->nrows++] = row;
    return ACR_OK;
}
