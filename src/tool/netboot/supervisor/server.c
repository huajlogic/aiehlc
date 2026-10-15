/* TCP protocol (netboot_proto.h) on lwIP RAW. One request per connection.
 * The callbacks only move bytes; the work (SHA, placement, launch) runs from
 * server_poll() in the main loop, outside lwIP's call stack. */
#include <stdio.h>
#include <string.h>

#include "lwip/tcp.h"
#include "netboot.h"
#include "xil_printf.h"

struct conn {
    struct tcp_pcb *pcb;
    struct netboot_req req;
    uint32_t hdr_got;
    uint64_t payload_got;
    uint64_t t_first_ms;
    int ready; /* request complete, waiting for server_poll */
};

static struct conn s_c;
static int s_busy;

static void conn_reset(void) {
    memset(&s_c, 0, sizeof(s_c));
    s_busy = 0;
}

static void reply(int32_t rc, uint32_t rx_ms, uint32_t place_ms, const char *msg) {
    struct netboot_rep rep;
    memset(&rep, 0, sizeof(rep));
    rep.magic = NETBOOT_REP_MAGIC;
    rep.rc = rc;
    rep.bytes_rx = s_c.payload_got;
    rep.rx_ms = rx_ms;
    rep.place_ms = place_ms;
    rep.entry = g_nb.entry;
    rep.state = g_nb.state;
    rep.run_ms = g_nb.state == NETBOOT_ST_RUNNING ? (uint32_t)(nb_now_ms() - g_nb.run_start_ms) : 0;
    rep.runs = g_nb.runs;
    rep.msg_len = msg ? (uint32_t)strlen(msg) : 0;
    struct tcp_pcb *pcb = s_c.pcb;
    if (pcb) {
        tcp_write(pcb, &rep, sizeof(rep), TCP_WRITE_FLAG_COPY);
        if (rep.msg_len)
            tcp_write(pcb, msg, (u16_t)rep.msg_len, TCP_WRITE_FLAG_COPY);
        tcp_output(pcb);
        tcp_arg(pcb, NULL);
        tcp_recv(pcb, NULL);
        tcp_err(pcb, NULL);
        if (tcp_close(pcb) != ERR_OK)
            tcp_abort(pcb);
    }
    conn_reset();
}

static void on_err(void *arg, err_t err) {
    (void)arg;
    xil_printf("[netboot] connection error %d, request dropped\r\n", (int)err);
    conn_reset(); /* lwIP already freed the pcb */
}

static int header_ok(char *msg, size_t n) {
    const struct netboot_req *r = &s_c.req;
    if (r->magic != NETBOOT_REQ_MAGIC || r->version != NETBOOT_VERSION) {
        snprintf(msg, n, "bad magic/version");
        return 0;
    }
    if (r->cmd == NETBOOT_CMD_LOAD_RUN && (r->elf_size == 0 || r->elf_size > NB_STAGING_SIZE)) {
        snprintf(msg, n, "elf_size %llu exceeds staging %llu", (unsigned long long)r->elf_size,
                 (unsigned long long)NB_STAGING_SIZE);
        return 0;
    }
    return 1;
}

static err_t on_recv(void *arg, struct tcp_pcb *pcb, struct pbuf *p, err_t err) {
    if (!p) { /* peer closed before the request completed */
        if (!s_c.ready) {
            tcp_close(pcb);
            conn_reset();
        }
        return ERR_OK;
    }
    if (s_c.t_first_ms == 0)
        s_c.t_first_ms = nb_now_ms();
    uint8_t *stage = (uint8_t *)(uintptr_t)NB_STAGING_BASE;
    for (struct pbuf *q = p; q; q = q->next) {
        const uint8_t *src = (const uint8_t *)q->payload;
        uint32_t len = q->len;
        if (s_c.hdr_got < sizeof(s_c.req)) {
            uint32_t take = sizeof(s_c.req) - s_c.hdr_got;
            take = take < len ? take : len;
            memcpy((uint8_t *)&s_c.req + s_c.hdr_got, src, take);
            s_c.hdr_got += take, src += take, len -= take;
        }
        if (len && s_c.hdr_got == sizeof(s_c.req) && s_c.req.cmd == NETBOOT_CMD_LOAD_RUN) {
            uint64_t room = s_c.req.elf_size - s_c.payload_got;
            uint32_t take = (uint32_t)(len < room ? len : room);
            if (s_c.req.elf_size <= NB_STAGING_SIZE)
                memcpy(stage + s_c.payload_got, src, take);
            s_c.payload_got += take;
        }
    }
    tcp_recved(pcb, p->tot_len);
    pbuf_free(p);
    if (s_c.hdr_got == sizeof(s_c.req) && (s_c.req.cmd != NETBOOT_CMD_LOAD_RUN || s_c.payload_got >= s_c.req.elf_size ||
                                           s_c.req.elf_size > NB_STAGING_SIZE))
        s_c.ready = 1;
    return ERR_OK;
}

static err_t on_accept(void *arg, struct tcp_pcb *pcb, err_t err) {
    if (err != ERR_OK || !pcb)
        return ERR_VAL;
    if (s_busy) { /* one request at a time */
        tcp_abort(pcb);
        return ERR_ABRT;
    }
    conn_reset();
    s_busy = 1;
    s_c.pcb = pcb;
    tcp_arg(pcb, &s_c);
    tcp_recv(pcb, on_recv);
    tcp_err(pcb, on_err);
    return ERR_OK;
}

int server_init(void) {
    struct tcp_pcb *pcb = tcp_new_ip_type(IPADDR_TYPE_ANY);
    if (!pcb)
        return -1;
    if (tcp_bind(pcb, IP_ANY_TYPE, NETBOOT_PORT) != ERR_OK)
        return -2;
    pcb = tcp_listen(pcb);
    if (!pcb)
        return -3;
    tcp_accept(pcb, on_accept);
    return 0;
}

static void handle_load_run(uint32_t rx_ms) {
    static char msg[256];
    uint8_t digest[32];
    const uint8_t *stage = (const uint8_t *)(uintptr_t)NB_STAGING_BASE;
    nb_sha256(stage, s_c.req.elf_size, digest);
    if (memcmp(digest, s_c.req.sha256, 32) != 0) {
        reply(-2, rx_ms, 0, "sha256 mismatch: upload corrupted, nothing placed");
        return;
    }
    g_nb.staged_size = s_c.req.elf_size;
    xil_printf("[netboot] LOAD_RUN %llu B received in %u ms, sha256 ok\r\n", (unsigned long long)s_c.req.elf_size,
               rx_ms);
    uint32_t place_ms = 0;
    int rc = nb_launch(s_c.req.timeout_ms, &place_ms, msg, sizeof(msg));
    reply(rc, rx_ms, place_ms, msg);
}

void server_poll(void) {
    static char msg[256];
    if (!s_busy || !s_c.ready)
        return;
    if (!header_ok(msg, sizeof(msg))) {
        reply(-1, 0, 0, msg);
        return;
    }
    uint32_t rx_ms = (uint32_t)(nb_now_ms() - s_c.t_first_ms);
    switch (s_c.req.cmd) {
    case NETBOOT_CMD_LOAD_RUN:
        handle_load_run(rx_ms);
        break;
    case NETBOOT_CMD_RERUN: {
        uint32_t place_ms = 0;
        int rc = g_nb.staged_size ? nb_launch(s_c.req.timeout_ms, &place_ms, msg, sizeof(msg)) : -3;
        reply(rc, 0, place_ms, g_nb.staged_size ? msg : "nothing staged; send LOAD_RUN first");
        break;
    }
    case NETBOOT_CMD_KILL:
        reply(nb_kill("KILL command"), 0, 0, "app core powered down");
        break;
    case NETBOOT_CMD_STATUS:
        snprintf(msg, sizeof(msg), "pm %s, staged %llu B, app core %s", apu_available() ? "ok" : "UNAVAILABLE",
                 (unsigned long long)g_nb.staged_size, apu_busy() ? "busy" : "free");
        reply(0, 0, 0, msg);
        break;
    default:
        reply(-1, 0, 0, "unknown command");
    }
}
