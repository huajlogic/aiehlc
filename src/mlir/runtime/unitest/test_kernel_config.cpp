// Host unit test for KERNELCONFIGOFFLOAD core-tile DMA MMIO encoding.
//
// Phase 1 (this file): prove we can capture the GOLDEN register writes the
// real aie-rt gen5 driver produces for a core-tile S2MM buffer-descriptor,
// host-native, with no hardware. The whole driver is compiled for x86 with the
// DEBUG IO backend; writes are captured structurally via the XAie transaction
// export (Write32 / BlockWrite32 ops), NOT by parsing printf output.
//
// Later phases diff a standalone encoder (include/aie_kernel_config.h) against
// these golden words.

#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <vector>

extern "C" {
#include "xaiengine.h"
}

// ---- AIE2PS (gen5) device geometry (matches include/aie_device_map.h) ----
#define KC_BASE_ADDR 0x20000000000ULL
#define KC_COL_SHIFT 25
#define KC_ROW_SHIFT 20
#define KC_NUM_COLS 36
#define KC_NUM_ROWS 7
#define KC_SHIM_ROW 0
#define KC_MEMTILE_ROW_ST 1
#define KC_MEMTILE_NUM_ROWS 2
#define KC_CORE_ROW_ST 3
#define KC_CORE_NUM_ROWS 4

// AIE2PS core-tile memory-module register offsets (tile-local).
#define KC_DMA_BD0_0 0x1D000u
#define KC_DMA_BD_STRIDE 0x20u
#define KC_DMA_S2MM0_START_Q 0x1DE04u

// One captured register write, decoded to tile-local coordinates.
struct CapWrite {
    uint8_t col;
    uint8_t row;
    uint32_t off; // tile-local byte offset
    uint32_t val;
};

// Walk an exported serialized-transaction buffer and collect every Write32 /
// BlockWrite32 as (col,row,tile_local_off,value). Rejects masked ops (the
// offload cannot express masked writes) by aborting the test.
static std::vector<CapWrite> parse_txn(const uint8_t *buf) {
    std::vector<CapWrite> out;
    const XAie_TxnHeader *hdr = reinterpret_cast<const XAie_TxnHeader *>(buf);
    const uint8_t *p = buf + sizeof(XAie_TxnHeader);
    for (uint32_t i = 0; i < hdr->NumOps; i++) {
        const XAie_OpHdr *op = reinterpret_cast<const XAie_OpHdr *>(p);
        switch (op->Op) {
        case XAIE_IO_WRITE: {
            const XAie_Write32Hdr *w = reinterpret_cast<const XAie_Write32Hdr *>(p);
            uint64_t regoff = w->RegOff;
            CapWrite c;
            c.col = (uint8_t)(regoff >> KC_COL_SHIFT);
            c.row = (uint8_t)((regoff >> KC_ROW_SHIFT) & ((1u << (KC_COL_SHIFT - KC_ROW_SHIFT)) - 1));
            c.off = (uint32_t)(regoff & ((1u << KC_ROW_SHIFT) - 1));
            c.val = w->Value;
            out.push_back(c);
            p += w->Size;
            break;
        }
        case XAIE_IO_BLOCKWRITE: {
            const XAie_BlockWrite32Hdr *bw = reinterpret_cast<const XAie_BlockWrite32Hdr *>(p);
            uint32_t nwords = (bw->Size - (uint32_t)sizeof(XAie_BlockWrite32Hdr)) / 4u;
            const uint32_t *data = reinterpret_cast<const uint32_t *>(p + sizeof(XAie_BlockWrite32Hdr));
            uint32_t base_off = bw->RegOff & ((1u << KC_ROW_SHIFT) - 1);
            for (uint32_t k = 0; k < nwords; k++) {
                CapWrite c;
                c.col = bw->Col;
                c.row = bw->Row;
                c.off = base_off + k * 4u;
                c.val = data[k];
                out.push_back(c);
            }
            p += bw->Size;
            break;
        }
        default:
            fprintf(stderr, "FAIL: unexpected txn op %u (masked/custom not supported by offload)\n", op->Op);
            exit(2);
        }
    }
    return out;
}

// Mirror __Runtime_dma_bd_config for a core-tile S2MM ping/pong BD: emit the
// XAie driver calls that program one buffer descriptor. Runs inside an open
// transaction, so nothing hits HW.
static void emit_golden_core_bd(XAie_DevInst *dev, XAie_LocType loc, uint8_t bd_id, uint64_t dma_addr, uint32_t len,
                                int next_bd, int acq_id, int acq_val, int rel_id, int rel_val, int ooo_bd_id) {
    XAie_DmaDesc desc;
    XAie_DmaDescInit(dev, &desc, loc);
    XAie_DmaSetAddrLen(&desc, dma_addr, len);
    if (acq_id >= 0 && rel_id >= 0)
        XAie_DmaSetLock(&desc, XAie_LockInit((u16)acq_id, (s8)acq_val), XAie_LockInit((u16)rel_id, (s8)rel_val));
    if (next_bd >= 0)
        XAie_DmaSetNextBd(&desc, (uint16_t)next_bd, XAIE_ENABLE);
    if (ooo_bd_id >= 0)
        XAie_DmaSetOutofOrderBdId(&desc, (uint8_t)ooo_bd_id);
    XAie_DmaEnableBd(&desc);
    AieRC rc = XAie_DmaWriteBd(dev, &desc, loc, bd_id);
    if (rc != XAIE_OK) {
        fprintf(stderr, "FAIL: XAie_DmaWriteBd rc=%d\n", (int)rc);
        exit(3);
    }
}

int main(void) {
    XAie_SetupConfig(cfg, XAIE_DEV_GEN_AIE2PS, KC_BASE_ADDR, KC_COL_SHIFT, KC_ROW_SHIFT, KC_NUM_COLS, KC_NUM_ROWS,
                     KC_SHIM_ROW, KC_MEMTILE_ROW_ST, KC_MEMTILE_NUM_ROWS, KC_CORE_ROW_ST, KC_CORE_NUM_ROWS);

    XAie_InstDeclare(dev_inst, &cfg);
    AieRC rc = XAie_CfgInitialize(&dev_inst, &cfg);
    if (rc != XAIE_OK) {
        fprintf(stderr, "FAIL: XAie_CfgInitialize rc=%d\n", (int)rc);
        return 1;
    }

    // Capture: buffer register writes instead of executing them.
    rc = XAie_StartTransaction(&dev_inst, XAIE_TRANSACTION_DISABLE_AUTO_FLUSH);
    if (rc != XAIE_OK) {
        fprintf(stderr, "FAIL: XAie_StartTransaction rc=%d\n", (int)rc);
        return 1;
    }

    // Core tile at (col=0, row=3): S2MM ping BD 0 -> pong BD 1.
    XAie_LocType loc = XAie_TileLoc(0, KC_CORE_ROW_ST);
    const uint64_t ping_addr = 0x2000; // core DMA-view byte address
    const uint32_t len = 1024;         // bytes
    emit_golden_core_bd(&dev_inst, loc, /*bd_id=*/0, ping_addr, len, /*next_bd=*/1,
                        /*acq_id=*/0, /*acq_val=*/-1, /*rel_id=*/1, /*rel_val=*/1, /*ooo_bd_id=*/-1);

    uint8_t *txn = XAie_ExportSerializedTransaction(&dev_inst, 1, 0);
    if (!txn) {
        fprintf(stderr, "FAIL: XAie_ExportSerializedTransaction returned NULL\n");
        return 1;
    }

    std::vector<CapWrite> writes = parse_txn(txn);

    printf("captured %zu register writes for core-tile S2MM BD0:\n", writes.size());
    int bd0_words = 0;
    for (const CapWrite &c : writes) {
        printf("  (col=%u,row=%u) off=0x%05x = 0x%08x", c.col, c.row, c.off, c.val);
        if (c.off >= KC_DMA_BD0_0 && c.off < KC_DMA_BD0_0 + KC_DMA_BD_STRIDE) {
            printf("   [BD0 word %u]", (c.off - KC_DMA_BD0_0) / 4u);
            bd0_words++;
        }
        printf("\n");
    }

    free(txn);

    if (bd0_words != 6) {
        fprintf(stderr, "FAIL: expected 6 BD0 register words, captured %d\n", bd0_words);
        return 1;
    }
    printf("PASS: golden core-tile S2MM BD capture (6 words) works host-native\n");
    return 0;
}
