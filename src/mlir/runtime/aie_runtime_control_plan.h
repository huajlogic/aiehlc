#ifndef AIE_RUNTIME_CONTROL_PLAN_H
#define AIE_RUNTIME_CONTROL_PLAN_H
#include <stdint.h>

/* Pure planner for row-based control connections. No XAie dependency so it can
 * be unit-tested on the host. The emit layer (aie_runtime.c) translates the
 * resulting acr_oplist into XAie stream-switch calls (packet-switch master/
 * slave enable, slave slot enable, circuit connection enable).
 * See docs/plans row-control-connection design doc. */

#define ACR_MAX_ROWS 16
#define ACR_MAX_OPS 256
#define ACR_NUM_SLOTS 4 /* NumSlaveSlots per port (xaie_ss.c:755) */

/* Direction/port tags, decoupled from XAie enums for pure testing. */
typedef enum { ACR_WEST, ACR_EAST, ACR_NORTH, ACR_SOUTH, ACR_CTRL } acr_port;

/* One emitted stream-switch operation (translated to XAie by the emit layer). */
typedef enum { ACR_OP_SLOT, ACR_OP_SLAVE_EN, ACR_OP_MASTER_EN, ACR_OP_CCT } acr_op_kind;
typedef struct {
    acr_op_kind kind;
    uint8_t col, row;
    acr_port sport;
    uint8_t sidx; /* slave side */
    acr_port mport;
    uint8_t midx; /* master side */
    uint8_t slot, pkt_id, mask, msel, arbiter, mselen;
    uint8_t keep_header; /* 1 => DONOT_DROP_HEADER */
} acr_op;

typedef struct {
    acr_op ops[ACR_MAX_OPS];
    int n;
} acr_oplist;

/* Per-tile used-port bitmaps for conflict rejection (requirement #7). */
typedef struct {
    uint16_t master_used[ACR_MAX_ROWS + 1][64]; /* [row][col] bit i => master idx i used */
    uint16_t slave_used[ACR_MAX_ROWS + 1][64];
} acr_portbook;

typedef enum { ACR_OK = 0, ACR_ERR_PORT_CONFLICT, ACR_ERR_SLOTS, ACR_ERR_BOUNDS, ACR_ERR_TILETYPE } acr_rc;

/* Pure mirror of the instance's shared-spine state, so the spine/row-add logic
 * can be host-unit-tested without the XAie-bearing __Runtime_CtrlRowFabric. */
typedef struct {
    uint8_t spine_top;          /* highest row with a pass-through hop (0 => none) */
    uint8_t rows[ACR_MAX_ROWS]; /* rows already configured (for idempotence) */
    uint8_t nrows;
} acr_state;

/* Pure planner API (defined in aie_runtime_control_plan.c). No XAie dependency. */

/* Book master/slave port index @idx on tile (col,row) for port @p; rejects a
 * double-book of the same (port,idx). Returns ACR_ERR_* on conflict/bounds. */
acr_rc acr_book_port(acr_portbook *b, uint8_t col, uint8_t row, acr_port p, uint8_t idx, int is_master);

/* Plain horizontal chain [col_lo..col_hi] on @row, head ingresses on WEST. When
 * @target_col < 0 the chain is a broadcast superset; otherwise it forwards up to
 * @target_col which consumes at CTRL. */
acr_rc acr_plan_chain(acr_oplist *o, acr_portbook *b, uint8_t row, uint8_t col_lo, uint8_t col_hi, int target_col,
                      uint8_t ctrl_id);

/* Ensure the shared vertical spine (column @shim_col) reaches @row, then build
 * the broadcast EAST chain [col_lo..col_hi]. Idempotent per row. */
acr_rc acr_plan_row_add(acr_state *s, acr_oplist *o, acr_portbook *b, uint8_t shim_col, uint8_t row, uint8_t col_lo,
                        uint8_t col_hi, uint8_t ctrl_id);
#endif
