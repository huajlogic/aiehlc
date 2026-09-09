// Host unit tests for the pure row-control planner.
#include <cassert>
#include <cstdio>
extern "C" {
#include "aie_runtime_control_plan.h"
acr_rc acr_book_port(acr_portbook *, uint8_t col, uint8_t row, acr_port, uint8_t idx, int is_master);
acr_rc acr_plan_chain(acr_oplist *, acr_portbook *, uint8_t row, uint8_t col_lo, uint8_t col_hi,
                      int target_col /* -1 => broadcast all */, uint8_t ctrl_id);
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

static int test_unicast() {
    // target is col_hi; col_lo forwards, col_hi consumes.
    acr_oplist o = {};
    acr_portbook b = {};
    assert(acr_plan_chain(&o, &b, 4, 2, 3, /*target*/ 3, 5) == ACR_OK);
    // col 2 = forward-only: has EAST master, no CTRL master
    assert(count_master(&o, 2, ACR_EAST) == 1);
    assert(count_master(&o, 2, ACR_CTRL) == 0);
    // col 3 = consume-only: CTRL master, no EAST master
    assert(count_master(&o, 3, ACR_CTRL) == 1);
    assert(count_master(&o, 3, ACR_EAST) == 0);
    return 0;
}

static int test_broadcast() {
    // all tiles consume+forward except last (consume only).
    acr_oplist o = {};
    acr_portbook b = {};
    assert(acr_plan_chain(&o, &b, 4, 2, 4, /*broadcast*/ -1, 5) == ACR_OK);
    for (uint8_t c = 2; c <= 3; c++) { // interior: CTRL + EAST both
        assert(count_master(&o, c, ACR_CTRL) == 1);
        assert(count_master(&o, c, ACR_EAST) == 1);
    }
    assert(count_master(&o, 4, ACR_CTRL) == 1); // last consumes
    assert(count_master(&o, 4, ACR_EAST) == 0); // no further forward
    return 0;
}

static int test_msel_rule() {
    // every master MSelEn == 1<<msel of its slot.
    acr_oplist o = {};
    acr_portbook b = {};
    assert(acr_plan_chain(&o, &b, 4, 2, 3, 3, 5) == ACR_OK);
    for (int i = 0; i < o.n; i++)
        if (o.ops[i].kind == ACR_OP_MASTER_EN)
            assert(o.ops[i].mselen == (uint8_t)(1u << o.ops[i].msel));
    return 0;
}

static int test_spine_reuse() {
    acr_state s = {};
    acr_portbook b = {};
    acr_oplist o1 = {};
    assert(acr_plan_row_add(&s, &o1, &b, 2, 3, 2, 4, 5) == ACR_OK); // rows 1..3 spine
    assert(count_kind(&o1, ACR_OP_CCT) > 0);
    acr_oplist o2 = {};
    assert(acr_plan_row_add(&s, &o2, &b, 2, 3, 2, 4, 5) == ACR_OK); // re-add same row
    assert(o2.n == 0);                                              // idempotent: nothing new
    acr_oplist o3 = {};
    assert(acr_plan_row_add(&s, &o3, &b, 2, 5, 2, 4, 5) == ACR_OK); // higher row reuses spine 1..3
    // Spine rows 3,4 are added. Row 3 is an ALREADY-configured head (its SOUTH
    // ingress is a packet slave), so it fans the spine up with a packet NORTH
    // master, NOT a circuit CCT (HW cannot do both on one slave-port channel).
    // Only row 4 (a pure pass-through) is a CCT.
    assert(count_kind(&o3, ACR_OP_CCT) == 1);
    assert(count_master(&o3, 2, ACR_NORTH) == 1);
    return 0;
}

// A higher row reusing the shared spine must not emit a circuit CCT at an
// already-configured head row; it must fan the spine up with a packet NORTH
// master carrying both broadcast (msel0) and unicast (msel1) so both climb.
static int test_shared_head_fanout() {
    acr_state s = {};
    acr_portbook b = {};
    acr_oplist o1 = {};
    assert(acr_plan_row_add(&s, &o1, &b, 0, 3, 0, 1, 4) == ACR_OK); // head row 3, spine rows 1,2
    acr_oplist o2 = {};
    assert(acr_plan_row_add(&s, &o2, &b, 0, 5, 0, 1, 4) == ACR_OK); // spine rows 3,4
    // No CCT at the shared head row 3.
    for (int i = 0; i < o2.n; i++)
        assert(!(o2.ops[i].kind == ACR_OP_CCT && o2.ops[i].row == 3));
    // A packet NORTH master at (col0,row3), arb0, mselen = msel0|msel1, keep header.
    int found = 0;
    for (int i = 0; i < o2.n; i++) {
        const acr_op *op = &o2.ops[i];
        if (op->kind == ACR_OP_MASTER_EN && op->mport == ACR_NORTH && op->col == 0 && op->row == 3) {
            assert(op->arbiter == 0);
            assert(op->mselen == (uint8_t)((1u << 0) | (1u << 1)));
            assert(op->keep_header == 1);
            found = 1;
        }
    }
    assert(found);
    // Row 4 (not a head) stays a circuit pass-through.
    int cct4 = 0;
    for (int i = 0; i < o2.n; i++)
        if (o2.ops[i].kind == ACR_OP_CCT && o2.ops[i].row == 4)
            cct4 = 1;
    assert(cct4);
    return 0;
}

int main() {
    if (test_book() || test_unicast() || test_broadcast() || test_msel_rule() || test_spine_reuse() ||
        test_shared_head_fanout())
        return 1;
    printf("PASS\n");
    return 0;
}
