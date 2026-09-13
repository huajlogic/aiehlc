// Host unit tests for the pure row-control planner.
#include <cassert>
#include <cstdio>
extern "C" {
#include "aie_runtime_control_plan.h"
acr_rc acr_book_port(acr_portbook *, uint8_t col, uint8_t row, acr_port, uint8_t idx, int is_master);
acr_rc acr_plan_chain(acr_oplist *, acr_portbook *, uint8_t row, uint8_t col_lo, uint8_t col_hi, uint8_t ctrl_id);
acr_rc acr_plan_row_add(acr_state *, acr_oplist *, acr_portbook *, uint8_t shim_col, uint8_t row, uint8_t col_lo,
                        uint8_t col_hi, uint8_t ctrl_id);
}

static int count_kind(const acr_oplist *o, acr_op_kind k) {
    int c = 0;
    for (int i = 0; i < o->n; i++)
        if (o->ops[i].kind == k)
            c++;
    return c;
}

// Count master-enable ops on a column for a given master port.
static int count_master(const acr_oplist *o, uint8_t col, acr_port mport) {
    int c = 0;
    for (int i = 0; i < o->n; i++)
        if (o->ops[i].kind == ACR_OP_MASTER_EN && o->ops[i].col == col && o->ops[i].mport == mport)
            c++;
    return c;
}

// Count slot ops on a column.
static int count_slots(const acr_oplist *o, uint8_t col) {
    int c = 0;
    for (int i = 0; i < o->n; i++)
        if (o->ops[i].kind == ACR_OP_SLOT && o->ops[i].col == col)
            c++;
    return c;
}

// MSelEn of the (single) master-enable on a column for a given master port.
static int master_mselen(const acr_oplist *o, uint8_t col, acr_port mport) {
    for (int i = 0; i < o->n; i++)
        if (o->ops[i].kind == ACR_OP_MASTER_EN && o->ops[i].col == col && o->ops[i].mport == mport)
            return o->ops[i].mselen;
    return -1;
}

static int test_book() {
    acr_portbook b = {};
    assert(acr_book_port(&b, 3, 4, ACR_EAST, 0, /*master*/ 1) == ACR_OK);
    // same port+idx again => conflict
    assert(acr_book_port(&b, 3, 4, ACR_EAST, 0, 1) == ACR_ERR_PORT_CONFLICT);
    // different idx ok
    assert(acr_book_port(&b, 3, 4, ACR_EAST, 1, 1) == ACR_OK);
    // master and slave domains are independent
    assert(acr_book_port(&b, 3, 4, ACR_EAST, 0, /*slave*/ 0) == ACR_OK);
    return 0;
}

// Slot classes: an interior tile (col < col_hi) arms 3 slots (consume{00,10} +
// broadcast + transit-east); a spine head arms 4 (adds transit-north); the last
// tile (col_hi) arms 3 (only-last + whole-row + broadcast). Interior CTRL MSelEn
// == 0x3, last-tile CTRL == 0x7. A plain chain has no NORTH master and no CCT.
static int test_slot_classes() {
    // Spine chain via row_add: head on spine col 2 (4 slots), interior 3 (3),
    // last col 4 (3).
    acr_state s = {};
    acr_portbook b = {};
    acr_oplist o = {};
    assert(acr_plan_row_add(&s, &o, &b, 2, 3, 2, 4, /*ctrl_id*/ 0) == ACR_OK); // head row 3, cols 2..4
    assert(count_slots(&o, 2) == 4);                                           // spine head: +transit-north
    assert(count_slots(&o, 3) == 3);                                           // interior
    assert(count_slots(&o, 4) == 3);                                           // last tile
    for (uint8_t c = 2; c <= 3; c++) {                                         // interior CTRL
        assert(count_master(&o, c, ACR_CTRL) == 1);
        assert(master_mselen(&o, c, ACR_CTRL) == 0x3);
    }
    assert(count_master(&o, 4, ACR_CTRL) == 1); // last-tile CTRL
    assert(master_mselen(&o, 4, ACR_CTRL) == 0x7);
    // A plain chain: interior col 2 (3 slots, CTRL 0x3), last col 3 (3 slots,
    // CTRL 0x7); no NORTH climb, no CCT.
    acr_oplist op = {};
    acr_portbook pb = {};
    assert(acr_plan_chain(&op, &pb, 4, 2, 3, /*ctrl_id*/ 0) == ACR_OK);
    assert(count_slots(&op, 2) == 3);
    assert(master_mselen(&op, 2, ACR_CTRL) == 0x3);
    assert(count_slots(&op, 3) == 3);
    assert(master_mselen(&op, 3, ACR_CTRL) == 0x7);
    assert(count_kind(&op, ACR_OP_CCT) == 0);
    for (int i = 0; i < op.n; i++)
        assert(!(op.ops[i].kind == ACR_OP_MASTER_EN && op.ops[i].mport == ACR_NORTH));
    return 0;
}

// EAST forwarding: interior tiles fan every class east (MSelEn 0xB = consume +
// broadcast + transit-east); the last tile does not forward EAST.
static int test_east_forward() {
    acr_oplist o = {};
    acr_portbook b = {};
    assert(acr_plan_chain(&o, &b, 4, 2, 4, /*ctrl_id*/ 0) == ACR_OK); // cols 2,3,4
    for (uint8_t c = 2; c <= 3; c++) {                                // interior
        assert(count_master(&o, c, ACR_EAST) == 1);
        assert(master_mselen(&o, c, ACR_EAST) == 0xB);
    }
    assert(count_master(&o, 4, ACR_EAST) == 0); // last tile: no further forward
    return 0;
}

// Slot table: interior tiles arm consume (pkt rowidx, mask 0x17, msel0), broadcast
// (0x10/0x10/msel1), transit-east (pkt 4|rowidx exact, msel3), and (spine head
// only) transit-north (0x00/0x10/msel2). The last tile (col_hi) arms two exact
// consume slots only-last (pkt 4|rowidx, msel0) and whole-row (pkt 8|rowidx,
// msel1) plus broadcast (0x10/0x10/msel2). Row index here is 0 (first add).
static int test_slot_table() {
    acr_state s = {};
    acr_portbook b = {};
    acr_oplist o = {};
    assert(acr_plan_row_add(&s, &o, &b, 2, 3, 2, 4, /*ctrl_id*/ 0) == ACR_OK); // head row 3, cols 2..4, rowidx 0
    const uint8_t rowidx = 0, col_hi = 4, head = 2;
    int saw_transit_n = 0, saw_transit_e = 0, saw_only_last = 0, saw_whole = 0;
    for (int i = 0; i < o.n; i++) {
        const acr_op *op = &o.ops[i];
        if (op->kind != ACR_OP_SLOT)
            continue;
        if (op->col == col_hi) { // last tile: slot index reuses last-tile enum
            switch (op->slot) {
            case ACR_SLOT_ONLY_LAST:
                assert(op->pkt_id == (uint8_t)((ACR_CLASS_ONLY_LAST << 2) | rowidx));
                assert(op->mask == ACR_MASK_EXACT);
                assert(op->msel == ACR_MSEL_ONLY_LAST);
                saw_only_last = 1;
                break;
            case ACR_SLOT_WHOLE:
                assert(op->pkt_id == (uint8_t)((ACR_CLASS_WHOLE_ROW << 2) | rowidx));
                assert(op->mask == ACR_MASK_EXACT);
                assert(op->msel == ACR_MSEL_WHOLE);
                saw_whole = 1;
                break;
            case ACR_SLOT_BCAST_LAST:
                assert(op->pkt_id == ACR_ID_BCAST);
                assert(op->mask == ACR_MASK_BCAST);
                assert(op->msel == ACR_MSEL_BCAST_LAST);
                break;
            default:
                assert(0 && "unexpected last-tile slot index");
            }
            continue;
        }
        switch (op->slot) { // interior tile
        case ACR_SLOT_CONSUME:
            assert(op->pkt_id == rowidx); // class 00 base | rowidx == rowidx
            assert(op->mask == ACR_MASK_CONSUME);
            assert(op->msel == ACR_MSEL_CONSUME);
            break;
        case ACR_SLOT_BCAST:
            assert(op->pkt_id == ACR_ID_BCAST);
            assert(op->mask == ACR_MASK_BCAST);
            assert(op->msel == ACR_MSEL_BCAST);
            break;
        case ACR_SLOT_TRANSIT_N: // spine head only
            assert(op->pkt_id == ACR_ID_TRANSIT);
            assert(op->mask == ACR_MASK_CLASS);
            assert(op->msel == ACR_MSEL_TRANSIT_N);
            assert(op->col == head);
            saw_transit_n = 1;
            break;
        case ACR_SLOT_TRANSIT_E:
            assert(op->pkt_id == (uint8_t)((ACR_CLASS_ONLY_LAST << 2) | rowidx));
            assert(op->mask == ACR_MASK_EXACT);
            assert(op->msel == ACR_MSEL_TRANSIT_E);
            saw_transit_e = 1;
            break;
        default:
            assert(0 && "unexpected interior slot index");
        }
    }
    assert(saw_transit_n && saw_transit_e && saw_only_last && saw_whole);
    return 0;
}

static int test_spine_reuse() {
    acr_state s = {};
    acr_portbook b = {};
    acr_oplist o1 = {};
    assert(acr_plan_row_add(&s, &o1, &b, 2, 3, 2, 4, 0) == ACR_OK); // rows 1..2 spine, head row 3
    assert(count_kind(&o1, ACR_OP_CCT) > 0);
    // Head row 3 sits on the spine column (2), so it emits its own NORTH climb
    // master (broadcast + transit, MSelEn 0x6).
    assert(count_master(&o1, 2, ACR_NORTH) == 1);
    assert(master_mselen(&o1, 2, ACR_NORTH) == 0x6);
    acr_oplist o2 = {};
    assert(acr_plan_row_add(&s, &o2, &b, 2, 3, 2, 4, 0) == ACR_OK); // re-add same row
    assert(o2.n == 0);                                              // idempotent: nothing new
    acr_oplist o3 = {};
    assert(acr_plan_row_add(&s, &o3, &b, 2, 5, 2, 4, 0) == ACR_OK); // higher row reuses spine 1..3
    // Spine rows 3,4 are extended. Row 3 is an ALREADY-configured head: it climbs
    // via its own NORTH master (emitted in o1), so o3 emits NOTHING at row 3.
    // Only row 4 (a pure pass-through) is a CCT.
    assert(count_kind(&o3, ACR_OP_CCT) == 1);
    for (int i = 0; i < o3.n; i++)
        assert(o3.ops[i].row != 3);
    return 0;
}

// A higher row reusing the shared spine must not re-emit anything at an
// already-configured head row: that head fans the spine up via the NORTH master
// (broadcast + transit) it emitted when it was first configured.
static int test_shared_head_fanout() {
    acr_state s = {};
    acr_portbook b = {};
    acr_oplist o1 = {};
    assert(acr_plan_row_add(&s, &o1, &b, 0, 3, 0, 1, 0) == ACR_OK); // head row 3, spine rows 1,2
    // Head-in-shim-col emits its own NORTH master (arb0, MSelEn 0x6).
    int found1 = 0;
    for (int i = 0; i < o1.n; i++) {
        const acr_op *op = &o1.ops[i];
        if (op->kind == ACR_OP_MASTER_EN && op->mport == ACR_NORTH && op->col == 0 && op->row == 3) {
            assert(op->arbiter == 0);
            assert(op->mselen == 0x6);
            assert(op->keep_header == 1);
            found1 = 1;
        }
    }
    assert(found1);
    acr_oplist o2 = {};
    assert(acr_plan_row_add(&s, &o2, &b, 0, 5, 0, 1, 0) == ACR_OK); // spine rows 3,4
    // No op at all at the shared head row 3 (neither CCT nor NORTH master).
    for (int i = 0; i < o2.n; i++)
        assert(o2.ops[i].row != 3);
    // Row 4 (not a head) stays a circuit pass-through.
    int cct4 = 0;
    for (int i = 0; i < o2.n; i++)
        if (o2.ops[i].kind == ACR_OP_CCT && o2.ops[i].row == 4)
            cct4 = 1;
    assert(cct4);
    // The new head row 5 emits its own NORTH master (broadcast + transit).
    assert(count_master(&o2, 0, ACR_NORTH) == 1);
    assert(master_mselen(&o2, 0, ACR_NORTH) == 0x6);
    return 0;
}

int main() {
    if (test_book() || test_slot_classes() || test_east_forward() || test_slot_table() || test_spine_reuse() ||
        test_shared_head_fanout())
        return 1;
    printf("PASS\n");
    return 0;
}
