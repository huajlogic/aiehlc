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
#define ACR_MAX_ROW_IDX 3 /* target row index lives in id[1:0] (0..3 => up to 4 rows) */

/* Three column-subset delivery classes select which columns of the target row
 * consume a non-broadcast packet, keyed by id[3:2]; id[1:0] = target row index
 * (add order). Broadcast is id[4]=1 (every column incl. last, every row).
 *   id = (class << 2) | rowidx.
 *   class 00 = all-but-last : every column EXCEPT col_hi
 *   class 01 = only-last    : only col_hi
 *   class 10 = whole-row    : every column incl. col_hi
 * Interior tiles (col < col_hi) arm a masked consume slot (classes 00,10) + a
 * broadcast slot + a transit-east slot (class 01, forwarded east but not
 * consumed); spine-head tiles add a transit-north climb slot. Last tiles (col_hi)
 * arm two exact consume slots (only-last, whole-row) + broadcast. */
#define ACR_CLASS_ALL_BUT_LAST 0
#define ACR_CLASS_ONLY_LAST 1
#define ACR_CLASS_WHOLE_ROW 2

/* Interior-tile slot indices (== MSel on that tile). */
#define ACR_SLOT_CONSUME 0   /* classes {00,10} @row K -> CTRL + EAST */
#define ACR_SLOT_BCAST 1     /* id[4]=1 -> CTRL + EAST (+NORTH on head) */
#define ACR_SLOT_TRANSIT_N 2 /* any row-mcast -> NORTH climb (spine head only) */
#define ACR_SLOT_TRANSIT_E 3 /* class 01 @row K -> EAST only (forward past) */

/* Last-tile slot indices (== MSel on that tile). */
#define ACR_SLOT_ONLY_LAST 0  /* class 01 @row K -> CTRL */
#define ACR_SLOT_WHOLE 1      /* class 10 @row K -> CTRL */
#define ACR_SLOT_BCAST_LAST 2 /* id[4]=1 -> CTRL */

/* MSel select value each slot injects (mirrors the slot index above). */
#define ACR_MSEL_CONSUME 0
#define ACR_MSEL_BCAST 1
#define ACR_MSEL_TRANSIT_N 2
#define ACR_MSEL_TRANSIT_E 3
#define ACR_MSEL_ONLY_LAST 0
#define ACR_MSEL_WHOLE 1
#define ACR_MSEL_BCAST_LAST 2

#define ACR_ARB_CTRL 0 /* single shared arbiter for all classes */

/* Reserved-bit id/mask scheme (5-bit stream id):
 *   [4]=bcast marker; [3:2]=class; [1:0]=target row index when [4]=0. */
#define ACR_ID_BCAST 0x10     /* [4]=1 */
#define ACR_MASK_BCAST 0x10   /* match on [4] only */
#define ACR_ID_TRANSIT 0x00   /* transit-north matches any row-mcast (bit4=0) */
#define ACR_MASK_CLASS 0x10   /* match on [4] only: row-mcast (0) vs broadcast (1) */
#define ACR_MASK_EXACT 0x1F   /* full 5-bit exact match */
#define ACR_MASK_CONSUME 0x17 /* match [4]=0,[2]=0,[1:0]=K ; ignore [3] -> classes 00 & 10 */

/* Per-master MSelEn bitmaps: which slot MSels each enabled master pulls. */
#define ACR_MSELEN_CTRL ((1u << ACR_MSEL_CONSUME) | (1u << ACR_MSEL_BCAST))                              /* 0x3 */
#define ACR_MSELEN_EAST ((1u << ACR_MSEL_CONSUME) | (1u << ACR_MSEL_BCAST) | (1u << ACR_MSEL_TRANSIT_E)) /* 0xB */
#define ACR_MSELEN_NORTH ((1u << ACR_MSEL_BCAST) | (1u << ACR_MSEL_TRANSIT_N))                           /* 0x6 */
#define ACR_MSELEN_CTRL_LAST                                                                                           \
    ((1u << ACR_MSEL_ONLY_LAST) | (1u << ACR_MSEL_WHOLE) | (1u << ACR_MSEL_BCAST_LAST)) /* 0x7 */

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

/* Plain horizontal chain [col_lo..col_hi] on @row, head ingresses on WEST. Every
 * tile arms the column-subset class slot superset on its ingress slave port keyed
 * by the packet stream id: id[3:2]=class (00 all-but-last, 01 only-last, 10 whole-
 * row), id[1:0]=target row index, id[4]=1 broadcast. Interior tiles arm a masked
 * consume slot (classes 00,10), a broadcast slot and a transit-east slot (class 01,
 * forwarded east but not consumed); the last tile (col_hi) arms two exact consume
 * slots (only-last, whole-row) plus broadcast. A plain chain passes row index 0 and
 * has no NORTH spine climb and no transit-north slot (shim_col=-1). */
acr_rc acr_plan_chain(acr_oplist *o, acr_portbook *b, uint8_t row, uint8_t col_lo, uint8_t col_hi, uint8_t ctrl_id);

/* Ensure the shared vertical spine (column @shim_col) reaches @row, then build the
 * column-subset EAST chain [col_lo..col_hi], assigning @row the next add-order
 * index (id[1:0]). Idempotent per row; caps at ACR_MAX_ROW_IDX+1 configured rows. */
acr_rc acr_plan_row_add(acr_state *s, acr_oplist *o, acr_portbook *b, uint8_t shim_col, uint8_t row, uint8_t col_lo,
                        uint8_t col_hi, uint8_t ctrl_id);
#endif
