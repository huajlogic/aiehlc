/* aie_kernel_config.h — standalone AIE2PS (gen5) core-tile DMA config encoder.
 *
 * KERNELCONFIGOFFLOAD: let the AIE CORE self-configure its own DMA buffer
 * descriptors / locks / channel-start from inside kernel.cc via raw MMIO,
 * instead of the HOST programming them over the config bus.
 *
 * This header produces the SAME register (tile-local offset, value) words the
 * aie-rt gen5 driver writes via:
 *   - XAie_DmaWriteBd            -> _XAieMl_TileDmaWriteBdPrep (6 BD words)
 *   - XAie_LockSetValue          -> _XAieMl_LockSetValue        (1 lock word)
 *   - XAie_DmaChannelSetStartQueue-> start-queue                (1 channel word)
 *
 * It has NO XAie / driver dependency (only <stdint.h>), so it is includable by
 * kernel.cc (compiled with xchesscc for the AIE core) AND by the host
 * golden-diff unit test (test_kernel_config.cpp), which validates every word
 * against the real driver output captured from an XAie transaction.
 *
 * Field Lsb/Mask constants below are copied verbatim from
 * thirdparty/alib/aie-rt/driver/src/global/xaie2psgbl_params.h. Scope: 1D
 * contiguous core-tile S2MM/MM2S BDs (the shapes the offload emits); multi-dim
 * / compression / FIFO are not encoded (their descriptor defaults encode as 0).
 */
#ifndef AIE_KERNEL_CONFIG_H
#define AIE_KERNEL_CONFIG_H

#include <stdint.h>

/* ---- AIE2PS memory-module (tile-local) register offsets ---- */
#define AIE_KC_DMA_BD0_0 0x1D000u     /* MEMORY_MODULE_DMA_BD0_0 */
#define AIE_KC_DMA_BD_STRIDE 0x20u    /* per-BD IdxOffset */
#define AIE_KC_DMA_BD_NUM_WORDS 6u    /* XAIEML_TILEDMA_NUM_BD_WORDS */
#define AIE_KC_S2MM0_START_Q 0x1DE04u /* MEMORY_MODULE_DMA_S2MM_0_START_QUEUE */
#define AIE_KC_MM2S0_START_Q 0x1DE14u /* MEMORY_MODULE_DMA_MM2S_0_START_QUEUE */
#define AIE_KC_DMA_CH_STRIDE 0x8u     /* per-channel ChIdxOffset */
#define AIE_KC_LOCK0_VALUE 0x1F000u   /* MEMORY_MODULE_LOCK0_VALUE */
#define AIE_KC_LOCK_STRIDE 0x10u      /* per-lock */

/* One register write: tile-local byte offset + value. */
typedef struct {
    uint32_t off;
    uint32_t val;
} AieKcReg;

/* Emulate the driver's XAie_SetField(v, Lsb, Mask) = (v << Lsb) & Mask.
 * Signed field values (e.g. a lock acquire value of -1) are passed already
 * cast to uint32_t; the two's-complement bit pattern masks to the field. */
static inline uint32_t aie_kc_field(uint32_t v, uint32_t lsb, uint32_t mask) { return (v << lsb) & mask; }

/* Encode one core-tile DMA buffer descriptor into 6 register writes at
 * BD0_0 + bd_id*0x20. Mirrors _XAieMl_TileDmaWriteBdPrep exactly for the 1D
 * contiguous case.
 *
 *   out          : caller array of >= AIE_KC_DMA_BD_NUM_WORDS entries
 *   bd_id        : hardware BD index (0..15)
 *   dma_addr     : buffer start byte address (core DMA view)
 *   len          : buffer length in bytes
 *   next_bd      : chained next BD id, or <0 for none
 *   acq_id/rel_id: lock ids (both >=0 to program a lock, else no lock)
 *   acq_val/rel_val: signed acquire/release lock values
 *   en_packet    : nonzero to enable packet mode
 *   pkt_id/pkt_type: packet header fields (used only when en_packet)
 *   ooo_bd_id    : out-of-order BD id, or <0 for none
 *
 * Returns the number of register writes emitted (AIE_KC_DMA_BD_NUM_WORDS). */
static inline int aie_kc_encode_bd(AieKcReg *out, uint8_t bd_id, uint64_t dma_addr, uint32_t len, int next_bd,
                                   int acq_id, int acq_val, int rel_id, int rel_val, int en_packet, int pkt_id,
                                   int pkt_type, int ooo_bd_id) {
    uint32_t addr = (uint32_t)(dma_addr >> 2); /* AddrAlignShift = 2 */
    uint32_t nwords = len >> 2;                /* 32-bit transfer length */
    uint32_t base = AIE_KC_DMA_BD0_0 + (uint32_t)bd_id * AIE_KC_DMA_BD_STRIDE;

    /* word 0: base address | buffer length */
    uint32_t w0 = aie_kc_field(addr, 14u, 0x0FFFC000u) | aie_kc_field(nwords, 0u, 0x00003FFFu);

    /* word 1: compression | packet | out-of-order bd id (compression = 0) */
    uint32_t w1 = 0u;
    if (en_packet) {
        w1 |= aie_kc_field(1u, 30u, 0x40000000u);                 /* EnPkt */
        w1 |= aie_kc_field((uint32_t)pkt_type, 16u, 0x00070000u); /* PktType */
        w1 |= aie_kc_field((uint32_t)pkt_id, 19u, 0x00F80000u);   /* PktId */
    }
    if (ooo_bd_id >= 0)
        w1 |= aie_kc_field((uint32_t)ooo_bd_id, 24u, 0x3F000000u);

    /* words 2..4: multi-dim / iteration — all zero for a 1D contiguous BD
     * (StepSize defaults 1 -> encoded (StepSize-1)=0, Wrap defaults 0). */
    uint32_t w2 = 0u, w3 = 0u, w4 = 0u;

    /* word 5: valid | lock | next-bd */
    uint32_t w5 = aie_kc_field(1u, 25u, 0x02000000u); /* ValidBd (EnableBd) */
    if (acq_id >= 0 && rel_id >= 0) {
        w5 |= aie_kc_field((uint32_t)rel_val, 18u, 0x01FC0000u); /* LckRelVal */
        w5 |= aie_kc_field((uint32_t)rel_id, 13u, 0x0001E000u);  /* LckRelId */
        w5 |= aie_kc_field(1u, 12u, 0x00001000u);                /* LckAcqEn */
        w5 |= aie_kc_field((uint32_t)acq_val, 5u, 0x00000FE0u);  /* LckAcqVal */
        w5 |= aie_kc_field((uint32_t)acq_id, 0u, 0x0000000Fu);   /* LckAcqId */
    }
    if (next_bd >= 0) {
        w5 |= aie_kc_field(1u, 26u, 0x04000000u);                /* UseNxtBd */
        w5 |= aie_kc_field((uint32_t)next_bd, 27u, 0x78000000u); /* NxtBd */
    }

    out[0].off = base + 0x00u;
    out[0].val = w0;
    out[1].off = base + 0x04u;
    out[1].val = w1;
    out[2].off = base + 0x08u;
    out[2].val = w2;
    out[3].off = base + 0x0Cu;
    out[3].val = w3;
    out[4].off = base + 0x10u;
    out[4].val = w4;
    out[5].off = base + 0x14u;
    out[5].val = w5;
    return (int)AIE_KC_DMA_BD_NUM_WORDS;
}

/* Encode a lock initial-value write (LOCK0_VALUE + id*0x10). Mirrors
 * _XAieMl_LockSetValue: 6-bit signed lock value field. Returns 1. */
static inline int aie_kc_encode_lock(AieKcReg *out, uint8_t lock_id, int value) {
    out[0].off = AIE_KC_LOCK0_VALUE + (uint32_t)lock_id * AIE_KC_LOCK_STRIDE;
    out[0].val = aie_kc_field((uint32_t)value, 0u, 0x0000003Fu);
    return 1;
}

/* Start-queue value: start bd id [3:0] | (repeat-1) [23:16] | en-token [31].
 * S2MM_0_START_QUEUE and MM2S_0_START_QUEUE have identical layouts (both
 * MASK 0x80FF000F), so both directions share this; only the base offset
 * differs. Mirrors _XAie_DmaChannelSetStartQueuePrepare. */
static inline uint32_t aie_kc_start_q_val(uint8_t start_bd, uint32_t repeat, int en_token) {
    return aie_kc_field((uint32_t)start_bd, 0u, 0x0000000Fu) | aie_kc_field(repeat - 1u, 16u, 0x00FF0000u) |
           aie_kc_field(en_token ? 1u : 0u, 31u, 0x80000000u);
}

/* Encode an S2MM channel start-queue write (S2MM_0_START_QUEUE + ch*0x8).
 * Returns 1. */
static inline int aie_kc_encode_s2mm_start(AieKcReg *out, uint8_t ch, uint8_t start_bd, uint32_t repeat, int en_token) {
    out[0].off = AIE_KC_S2MM0_START_Q + (uint32_t)ch * AIE_KC_DMA_CH_STRIDE;
    out[0].val = aie_kc_start_q_val(start_bd, repeat, en_token);
    return 1;
}

/* Encode an MM2S channel start-queue write (MM2S_0_START_QUEUE + ch*0x8).
 * Same value layout as S2MM; this is what lets the core arm its own OUTGOING
 * DMA under KERNELCONFIGOFFLOAD. Returns 1. */
static inline int aie_kc_encode_mm2s_start(AieKcReg *out, uint8_t ch, uint8_t start_bd, uint32_t repeat, int en_token) {
    out[0].off = AIE_KC_MM2S0_START_Q + (uint32_t)ch * AIE_KC_DMA_CH_STRIDE;
    out[0].val = aie_kc_start_q_val(start_bd, repeat, en_token);
    return 1;
}

#endif /* AIE_KERNEL_CONFIG_H */
