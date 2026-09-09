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

/* Derive the packet-switch ops for one EAST chain [col_lo..col_hi] on @row.
 * @target_col < 0 selects broadcast (every tile consumes+forwards); otherwise
 * only @target_col consumes and tiles before it forward. Encodes design §5:
 *   - consume  => CTRL master idx0, keep-header, arb0/msel0/mselen=1, WEST slot0
 *                 id=ctrl_id
 *   - forward-only (unicast pass-through) => EAST master, keep-header,
 *                 arb1/msel1/mselen=2, WEST slot1 (msel1)
 *   - consume+forward (broadcast) => CTRL and EAST masters both on
 *                 arb0/msel0/mselen=1, sharing WEST slot0 id=ctrl_id
 * MSelEn is always 1<<slot_msel (master pulls only when the slot's msel bit set).
 * Books each WEST slave + master idx so a re-emit is rejected as a conflict. */
acr_rc acr_plan_chain(acr_oplist *o, acr_portbook *b, uint8_t row, uint8_t col_lo, uint8_t col_hi, int target_col,
                      uint8_t ctrl_id) {
    if (col_hi < col_lo || col_hi >= 64)
        return ACR_ERR_BOUNDS;
    if (target_col >= 0 && (target_col < col_lo || target_col > col_hi))
        return ACR_ERR_BOUNDS;

    for (uint8_t c = col_lo; c <= col_hi; c++) {
        int is_target = (target_col < 0) || (c == (uint8_t)target_col);
        int has_east = (target_col < 0) ? (c < col_hi) : (c < (uint8_t)target_col);
        int consume_and_forward = is_target && has_east; /* broadcast interior */

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
        /* Book the WEST slave *port* (idx 0); @slot is a sub-resource of that
         * port, not a separate port. Incoming slot matches ctrl_id (full 5-bit
         * mask). Each tile taps WEST once here, so one port booking suffices. */
        if ((rc = acr_book_port(b, c, row, ACR_WEST, 0, /*master*/ 0)) != ACR_OK)
            return rc;
        acr_op slotop = {.kind = ACR_OP_SLOT,
                         .col = c,
                         .row = row,
                         .sport = ACR_WEST,
                         .sidx = 0,
                         .slot = slot,
                         .pkt_id = ctrl_id,
                         .mask = 0x1F,
                         .msel = msel,
                         .arbiter = arbiter};
        if ((rc = acr_emit_op(o, &slotop)) != ACR_OK)
            return rc;
        acr_op slaveen = {.kind = ACR_OP_SLAVE_EN, .col = c, .row = row, .sport = ACR_WEST, .sidx = 0};
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
