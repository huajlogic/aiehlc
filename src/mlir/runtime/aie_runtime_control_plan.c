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

/* Emit one packet-slot arm (ACR_OP_SLOT) on tile (c,row)'s ingress slave @sport.
 * A slot matches an incoming id iff (id & mask) == (pkt & mask), injecting the
 * packet into @arb with select value @msel. The ingress slave *port* is booked
 * once by the caller; the four slots are sub-resources of that one port. */
static acr_rc acr_emit_slot(acr_oplist *o, uint8_t c, uint8_t row, acr_port sport, uint8_t slot, uint8_t pkt,
                            uint8_t mask, uint8_t msel, uint8_t arb) {
    acr_op slotop = {.kind = ACR_OP_SLOT,
                     .col = c,
                     .row = row,
                     .sport = sport,
                     .sidx = 0,
                     .slot = slot,
                     .pkt_id = pkt,
                     .mask = mask,
                     .msel = msel,
                     .arbiter = arb};
    return acr_emit_op(o, &slotop);
}

/* Emit one packet-master enable (ACR_OP_MASTER_EN) on tile (c,row)'s @mport,
 * pulling every slot whose MSel bit is set in @mselen from arbiter @arb. Books
 * the master port (idx 0) first; keep_header is always set for control packets.
 *
 * NOTE on @arb: a master pulls only from packets injected into its OWN arbiter
 * (HW rule master.Arbitor == slot.Arbitor, xaie_ss.c). Because CTRL multicasts
 * with EAST (row-mcast slot) AND with NORTH (broadcast slot) off a *single*
 * slave slot each, and one slot injects into exactly one arbiter, CTRL/EAST/NORTH
 * must currently share one arbiter (ACR_ARB_CTRL). Splitting NORTH vs EAST onto
 * different arbiters would need a duplicate slot per multicast class, exceeding
 * ACR_NUM_SLOTS (4). @arb is parameterized so a future >4-slot layout can diverge
 * them, but all call sites pass ACR_ARB_CTRL today. */
static acr_rc acr_emit_master(acr_oplist *o, acr_portbook *b, uint8_t c, uint8_t row, acr_port mport, uint8_t mselen,
                              uint8_t arb) {
    acr_rc rc = acr_book_port(b, c, row, mport, 0, /*master*/ 1);
    if (rc != ACR_OK)
        return rc;
    acr_op m = {.kind = ACR_OP_MASTER_EN,
                .col = c,
                .row = row,
                .mport = mport,
                .midx = 0,
                .msel = 0,
                .arbiter = arb,
                .mselen = mselen,
                .keep_header = 1};
    return acr_emit_op(o, &m);
}

/* Core chain derivation. Each tile in [col_lo..col_hi] arms a per-role slot table
 * on its ingress slave port; the runtime send-path selects the column subset via
 * the packet stream id ((class<<2)|@rowidx, see the header slot table):
 *   Interior tile (c < col_hi, includes the spine head):
 *     slot CONSUME   {classes 00,10} @rowidx (mask 0x17) -> CTRL + EAST
 *     slot BCAST     (id[4]=1)                            -> CTRL + EAST (+NORTH on head)
 *     slot TRANSIT_N (any row-mcast, spine head only)     -> NORTH climb
 *     slot TRANSIT_E {class 01} @rowidx (exact)           -> EAST only (forward past)
 *   Last tile (c == col_hi):
 *     slot ONLY_LAST {class 01} @rowidx (exact) -> CTRL
 *     slot WHOLE     {class 10} @rowidx (exact) -> CTRL
 *     slot BCAST     (id[4]=1)                  -> CTRL
 * Masters: interior CTRL 0x3, EAST 0xB (consume+bcast+transit-east) when not last,
 * NORTH 0x6 on the spine head; last-tile CTRL 0x7 (no EAST/NORTH). @head_ingress
 * is the slave port the leftmost tile (col_lo) receives on: WEST for a plain
 * chain, SOUTH when the head is the top of the vertical spine. @shim_col < 0
 * disables the NORTH climb / transit-north slot (plain chain). @row is the
 * physical AIE row (op coords); @rowidx is the add-order row index carried in
 * id[1:0]. @ctrl_id is retained for the emit layer's provenance logging. */
static acr_rc acr_plan_chain_ex(acr_oplist *o, acr_portbook *b, uint8_t row, uint8_t rowidx, uint8_t col_lo,
                                uint8_t col_hi, uint8_t ctrl_id, int shim_col, acr_port head_ingress) {
    if (col_hi < col_lo || col_hi >= 64)
        return ACR_ERR_BOUNDS;
    if (rowidx > ACR_MAX_ROW_IDX) /* target row index lives in id[1:0] */
        return ACR_ERR_BOUNDS;
    if (ACR_NUM_SLOTS < 4) /* spine head arms consume+bcast+transitN+transitE */
        return ACR_ERR_SLOTS;

    for (uint8_t c = col_lo; c <= col_hi; c++) {
        acr_port sport = (c == col_lo) ? head_ingress : ACR_WEST;
        int is_last = (c == col_hi);
        int has_east = !is_last;
        int is_spine_head = (shim_col >= 0) && (c == (uint8_t)shim_col) && (c == col_lo);

        acr_rc rc;
        /* Book the ingress slave *port* (idx 0) once; slots are sub-resources. */
        if ((rc = acr_book_port(b, c, row, sport, 0, /*master*/ 0)) != ACR_OK)
            return rc;

        if (is_last) {
            /* Last tile (col_hi): consume only-last + whole-row; no EAST/NORTH. */
            uint8_t only_id = (uint8_t)((ACR_CLASS_ONLY_LAST << 2) | rowidx);
            uint8_t whole_id = (uint8_t)((ACR_CLASS_WHOLE_ROW << 2) | rowidx);
            if ((rc = acr_emit_slot(o, c, row, sport, ACR_SLOT_ONLY_LAST, only_id, ACR_MASK_EXACT, ACR_MSEL_ONLY_LAST,
                                    ACR_ARB_CTRL)) != ACR_OK)
                return rc;
            if ((rc = acr_emit_slot(o, c, row, sport, ACR_SLOT_WHOLE, whole_id, ACR_MASK_EXACT, ACR_MSEL_WHOLE,
                                    ACR_ARB_CTRL)) != ACR_OK)
                return rc;
            if ((rc = acr_emit_slot(o, c, row, sport, ACR_SLOT_BCAST_LAST, ACR_ID_BCAST, ACR_MASK_BCAST,
                                    ACR_MSEL_BCAST_LAST, ACR_ARB_CTRL)) != ACR_OK)
                return rc;
        } else {
            /* Interior tile (c < col_hi): masked consume (classes 00,10) +
             * broadcast + transit-east (class 01, EAST-only) [+ transit-north on
             * the spine head]. */
            uint8_t consume_id = (uint8_t)((ACR_CLASS_ALL_BUT_LAST << 2) | rowidx); /* == rowidx */
            uint8_t te_id = (uint8_t)((ACR_CLASS_ONLY_LAST << 2) | rowidx);
            if ((rc = acr_emit_slot(o, c, row, sport, ACR_SLOT_CONSUME, consume_id, ACR_MASK_CONSUME, ACR_MSEL_CONSUME,
                                    ACR_ARB_CTRL)) != ACR_OK)
                return rc;
            if ((rc = acr_emit_slot(o, c, row, sport, ACR_SLOT_BCAST, ACR_ID_BCAST, ACR_MASK_BCAST, ACR_MSEL_BCAST,
                                    ACR_ARB_CTRL)) != ACR_OK)
                return rc;
            if (is_spine_head && (rc = acr_emit_slot(o, c, row, sport, ACR_SLOT_TRANSIT_N, ACR_ID_TRANSIT,
                                                     ACR_MASK_CLASS, ACR_MSEL_TRANSIT_N, ACR_ARB_CTRL)) != ACR_OK)
                return rc;
            if ((rc = acr_emit_slot(o, c, row, sport, ACR_SLOT_TRANSIT_E, te_id, ACR_MASK_EXACT, ACR_MSEL_TRANSIT_E,
                                    ACR_ARB_CTRL)) != ACR_OK)
                return rc;
        }

        acr_op slaveen = {.kind = ACR_OP_SLAVE_EN, .col = c, .row = row, .sport = sport, .sidx = 0, .pkt_id = ctrl_id};
        if ((rc = acr_emit_op(o, &slaveen)) != ACR_OK)
            return rc;

        if (is_last) {
            /* Last tile CTRL pulls only-last + whole-row + broadcast (0x7). */
            if ((rc = acr_emit_master(o, b, c, row, ACR_CTRL, (uint8_t)ACR_MSELEN_CTRL_LAST, ACR_ARB_CTRL)) != ACR_OK)
                return rc;
        } else {
            /* Interior CTRL pulls consume + broadcast (0x3). */
            if ((rc = acr_emit_master(o, b, c, row, ACR_CTRL, (uint8_t)ACR_MSELEN_CTRL, ACR_ARB_CTRL)) != ACR_OK)
                return rc;
            /* EAST forwards consume + broadcast + only-last transit (0xB) so every
             * class reaches its columns. */
            if (has_east &&
                (rc = acr_emit_master(o, b, c, row, ACR_EAST, (uint8_t)ACR_MSELEN_EAST, ACR_ARB_CTRL)) != ACR_OK)
                return rc;
            /* NORTH climbs the spine for broadcast + any transiting row-mcast,
             * head-on-spine-column only (0x6). */
            if (is_spine_head &&
                (rc = acr_emit_master(o, b, c, row, ACR_NORTH, (uint8_t)ACR_MSELEN_NORTH, ACR_ARB_CTRL)) != ACR_OK)
                return rc;
        }
    }
    return ACR_OK;
}

/* Public chain planner: plain horizontal chain, head tile ingresses on WEST, no
 * vertical spine climb (shim_col=-1). A plain chain is a single row => rowidx 0. */
acr_rc acr_plan_chain(acr_oplist *o, acr_portbook *b, uint8_t row, uint8_t col_lo, uint8_t col_hi, uint8_t ctrl_id) {
    return acr_plan_chain_ex(o, b, row, /*rowidx=*/0, col_lo, col_hi, ctrl_id, /*shim_col=*/-1, ACR_WEST);
}

/* True if @row is an already-configured chain head in @s. */
static int acr_row_is_head(const acr_state *s, uint8_t row) {
    for (uint8_t i = 0; i < s->nrows; i++)
        if (s->rows[i] == row)
            return 1;
    return 0;
}

/* Ensure the shared vertical spine (column @shim_col) reaches @row, then build
 * the EAST chain [col_lo..col_hi] on that row. Idempotent per requirement #5:
 *   - re-adding a row already in @s->rows emits nothing;
 *   - a higher row reuses the existing spine and only extends it upward.
 * @s->spine_top is the highest row that HAS a spine-up hop; to feed head @row's
 * SOUTH ingress the spine must pass through rows 1..row-1, so we extend up to
 * row-1 (NOT row itself): the head row taps SOUTH into its chain and must not
 * also drive the spine up on the same SOUTH slave port.
 *
 * A spine-up hop through a pure pass-through tile (NOT a configured head) is a
 * circuit-switched CCT, SOUTH-in -> NORTH-out (one ACR_OP_CCT). Circuit switching
 * is class-agnostic, so broadcast AND every row-multicast class climb through
 * unchanged. An already-configured head tile needs NO hop here: its own chain
 * planning already emitted a NORTH master (MSelEn 0x6) that climbs broadcast + any
 * transiting row-multicast up the spine, so we skip it in this loop. row==1 needs
 * no hop (fed by the shim's NORTH directly).
 *
 * The chain head (col_lo == shim_col) ingresses from the spine below (SOUTH) and,
 * because it sits on the spine column, emits its own NORTH climb master (broadcast
 * + transit) inside acr_plan_chain_ex, so a row-multicast targeting any row above
 * still reaches it. Each configured row is assigned its add-order index (0,1,2,..)
 * which travels in id[1:0]; the chain is built as the column-subset class superset
 * (all-but-last / only-last / whole-row + broadcast) and the per-transfer class +
 * target row index are carried by the control packet's stream id at send time. */
acr_rc acr_plan_row_add(acr_state *s, acr_oplist *o, acr_portbook *b, uint8_t shim_col, uint8_t row, uint8_t col_lo,
                        uint8_t col_hi, uint8_t ctrl_id) {
    if (row == 0 || shim_col >= 64)
        return ACR_ERR_BOUNDS;
    if (col_lo != shim_col) /* row entry is the vertical spine's left column */
        return ACR_ERR_BOUNDS;

    /* Idempotent: already configured -> emit nothing. */
    if (acr_row_is_head(s, row))
        return ACR_OK;

    if (s->nrows >= ACR_MAX_ROWS)
        return ACR_ERR_BOUNDS;
    /* The new row's add-order index travels in id[1:0]; cap at 4 configured rows. */
    if (s->nrows > ACR_MAX_ROW_IDX)
        return ACR_ERR_BOUNDS;

    /* Extend the spine's up-hops to row-1 (the head row taps SOUTH, it is not a
     * spine-up hop). row==1 needs none (fed by the shim's NORTH). A row that is
     * already a configured head fans the spine up via its own broadcast NORTH
     * master, so it needs no CCT here; only pure pass-through rows get a CCT. */
    uint8_t need_top = (uint8_t)(row - 1);
    if (need_top > s->spine_top) {
        for (uint8_t r = (uint8_t)(s->spine_top + 1); r <= need_top; r++) {
            if (acr_row_is_head(s, r))
                continue; /* head row already climbs via its own NORTH master */
            acr_op cct = {.kind = ACR_OP_CCT,
                          .col = shim_col,
                          .row = r,
                          .sport = ACR_SOUTH,
                          .sidx = 0,
                          .mport = ACR_NORTH,
                          .midx = 0};
            acr_rc crc = acr_emit_op(o, &cct);
            if (crc != ACR_OK)
                return crc;
        }
        s->spine_top = need_top;
    }

    /* Build the horizontal chain; head tile takes the spine input from SOUTH and
     * emits its broadcast NORTH climb master (head sits on shim_col == col_lo). */
    acr_rc rc = acr_plan_chain_ex(o, b, row, /*rowidx=*/s->nrows, col_lo, col_hi, ctrl_id, /*shim_col=*/(int)shim_col,
                                  ACR_SOUTH);
    if (rc != ACR_OK)
        return rc;

    s->rows[s->nrows++] = row;
    return ACR_OK;
}
