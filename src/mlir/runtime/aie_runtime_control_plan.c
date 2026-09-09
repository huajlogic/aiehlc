#include "aie_runtime_control_plan.h"

/* Pure planner: derives per-tile stream-switch ops for a row-based control
 * connection with no XAie dependency. See the header for type docs. */

/* Return the port-usage bitmap cell for a tile's master or slave domain. */
static uint16_t *acr_book_cell(acr_portbook *b, uint8_t col, uint8_t row, int is_master) {
    uint16_t(*t)[64] = is_master ? b->master_used : b->slave_used;
    return &t[row][col];
}

/* Book master/slave port index @idx on tile (col,row). idx is unique within the
 * (col,row,is_master) domain, so @p is only advisory here. Rejects double-book. */
acr_rc acr_book_port(acr_portbook *b, uint8_t col, uint8_t row, acr_port p, uint8_t idx, int is_master) {
    (void)p;
    if (row > ACR_MAX_ROWS || col >= 64 || idx >= 16)
        return ACR_ERR_BOUNDS;
    uint16_t *cell = acr_book_cell(b, col, row, is_master);
    if (*cell & (uint16_t)(1u << idx))
        return ACR_ERR_PORT_CONFLICT;
    *cell |= (uint16_t)(1u << idx);
    return ACR_OK;
}
