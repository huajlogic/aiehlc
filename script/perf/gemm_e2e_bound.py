# Upper bound on end-to-end int8 GEMM throughput on the 4x4 AIE2PS mesh, MemTile-stationary B,
# K accumulated on core (C written once), A strips double-buffered in MemTile. Ignores launch cost.
PEAK=16*512*0.998e9
best={}
import sys, os
# Per-channel core input in B/cycle: 4 = the 32-bit stream; 2.7 = measured on palmyra
# (memtile -> core, DMA-only slope, 2026-11-20). AIEHLC_BOUND_CH=2.7 to use it.
CH = float(os.environ.get("AIEHLC_BOUND_CH", "4"))
for BW in [float(x)*1e9 for x in (sys.argv[1:] or ["7.4","11"])]:
    b=(0,)
    for K in range(64,4097,64):
        for Tn in range(64,8193,64):
            for tm in range(8,257,8):
                for tn in range(8,257,8):
                    if Tn % (4*tn): continue
                    for kc in (32,64,128):
                        core = 4*tm*tn + 2*kc*(tm+tn) + 2*tm*tn  # int32 acc + ping-pong A/B chunks + C int8 ping-pong
                        if core > 60*1024: continue
                        memt = K*Tn//4 + 2*4*tm*K             # B column slice + 2 x (4 row strips of A)
                        if memt > 512*1024: continue
                        r_core = min(512, CH*tn, CH*tm)       # MAC/cycle/core: A channel carries 1/tn B/MAC, B channel 1/tm
                        r_ddr  = BW/(1/K + 1/Tn)/(16*0.998e9) # A once per Tn, C once (int8), B ~once
                        r = min(r_core, r_ddr)/512
                        if r > b[0]: b=(r,K,Tn,tm,tn,kc,core,memt)
    best[BW]=b
for BW,b in best.items():
    print(f"DDR {BW/1e9:.1f} GB/s: max {b[0]*100:.1f}% of peak  K={b[1]} Tn={b[2]} tm={b[3]} tn={b[4]} kc={b[5]} core={b[6]} B memtile={b[7]} B")
