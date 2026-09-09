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
#endif
