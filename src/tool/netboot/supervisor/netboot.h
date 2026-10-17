/* netboot supervisor internals (runs on A78 core 0 from DDR_LOW1). */
#ifndef NETBOOT_H
#define NETBOOT_H

#include <stddef.h>
#include <stdint.h>

#include "netboot_proto.h"

/* Memory map, doc/design/lwip_elf_bootloader.md section 3 (as measured on the
 * board): the design's "unused DDR_LOW1" at 0x8_0000_0000 is a MIRROR of the 2 GB
 * DDR_LOW0 on this board, so the supervisor lives at the top of DDR_LOW0 and apps
 * must stay below NB_APP_LIMIT. */
#define NB_APP_BASE 0x0ULL
#define NB_APP_LIMIT 0x78000000ULL    /* supervisor image starts here (build.sh) */
#define NB_STAGING_BASE 0x7A200000ULL /* after the 2 MB BD-ring block at 0x7A000000 */
#define NB_STAGING_SIZE (0x80000000ULL - NB_STAGING_BASE)
/* An ELF larger than that (the Whisper engine embeds ~140 MB of weights) is
 * staged in the top of the APP window instead. Apps only reach it with .heap /
 * .stack (never file bytes or .bss: elf_place refuses that), so the upload is
 * safe to place, but the copy does not survive a run whose PT_LOAD reaches it:
 * nb_launch then drops it and RERUN needs a fresh LOAD_RUN. */
#define NB_STAGING_BIG_BASE 0x50000000ULL
#define NB_STAGING_BIG_SIZE (NB_APP_LIMIT - NB_STAGING_BIG_BASE)
#define NB_STAGING_MAX NB_STAGING_BIG_SIZE
static inline uint64_t nb_stage_base(uint64_t elf_size) {
    return elf_size <= NB_STAGING_SIZE ? NB_STAGING_BASE : NB_STAGING_BIG_BASE;
}

#define NB_DEFAULT_TIMEOUT_MS 600000U

/* time.c-free helpers in main.c */
uint64_t nb_now_ms(void);

/* apu.c: the app core, driven through the PLM (xilpm). */
int apu_init(void);
int apu_start(uint64_t entry);
int apu_kill(void);
int apu_available(void);
int apu_busy(void);          /* app core woken and not stopped since */
int apu_parked(int32_t *rc); /* finished app sits in park.S, reusable without the PLM */

/* park.S: the patched _exit lands here */
void nb_park(void);

/* elfload.c */
int elf_place(const uint8_t *img, uint64_t size, uint64_t *entry, char *msg, size_t msglen);
int elf_patch_exit(const uint8_t *img, uint64_t size, uint64_t park_addr);
int elf_reaches(const uint8_t *img, uint64_t size, uint64_t lo, uint64_t hi); /* any PT_LOAD memsz in [lo,hi) */

/* sha256.c */
void nb_sha256(const uint8_t *data, uint64_t len, uint8_t out[32]);

/* supervisor state (main.c), read by server.c */
struct nb_state {
    uint32_t state;       /* enum netboot_state */
    uint64_t staged_size; /* bytes of a validated ELF in staging, 0 = none */
    uint64_t entry;
    uint64_t run_start_ms;
    uint32_t timeout_ms;
    uint32_t runs;
};
extern struct nb_state g_nb;

/* Start (or restart) the staged image on the app core. 0 on success. */
int nb_launch(uint32_t timeout_ms, uint32_t *place_ms, char *msg, size_t msglen);
int nb_kill(const char *why);

/* server.c */
int server_init(void);
void server_poll(void);

#endif
