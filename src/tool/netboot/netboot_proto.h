/* Wire protocol shared by the netboot supervisor (board) and netload.py (host).
 * Little endian, packed. Keep in step with netload.py's struct formats. */
#ifndef NETBOOT_PROTO_H
#define NETBOOT_PROTO_H

#include <stdint.h>

#define NETBOOT_PORT 5155
#define NETBOOT_REQ_MAGIC 0x3154424EU /* 'NBT1' */
#define NETBOOT_REP_MAGIC 0x3152424EU /* 'NBR1' */
#define NETBOOT_VERSION 1

enum netboot_cmd {
    NETBOOT_CMD_LOAD_RUN = 1, /* payload = ELF; kill app core, place, start */
    NETBOOT_CMD_RERUN = 2,    /* re-place the staged ELF and start again */
    NETBOOT_CMD_KILL = 3,     /* force the app core down */
    NETBOOT_CMD_STATUS = 4,
};

enum netboot_state {
    NETBOOT_ST_IDLE = 0,
    NETBOOT_ST_RUNNING = 1,
    NETBOOT_ST_KILLED = 2,  /* by KILL or replaced by a new LOAD_RUN */
    NETBOOT_ST_TIMEOUT = 3, /* watchdog fired */
    NETBOOT_ST_EXITED = 4,  /* app returned from main; core parked and reusable */
};

struct netboot_req { /* 64 bytes */
    uint32_t magic;
    uint32_t version;
    uint32_t cmd;
    uint32_t flags;
    uint64_t elf_size;
    uint32_t timeout_ms; /* watchdog for this run, 0 = default */
    uint32_t reserved;
    uint8_t sha256[32];
} __attribute__((packed));

struct netboot_rep { /* 48 bytes, then msg_len bytes of text */
    uint32_t magic;
    int32_t rc;
    uint64_t bytes_rx;
    uint32_t rx_ms;
    uint32_t place_ms;
    uint64_t entry;
    uint32_t state;
    uint32_t run_ms;
    uint32_t runs;
    uint32_t msg_len;
} __attribute__((packed));

#endif
