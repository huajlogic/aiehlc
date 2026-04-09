// User-provided compute kernel (extracted from __global__ function)
void matmul(input_window_int8 *window_in_0, input_window_int8 *window_in_1, output_window_int8 *window_out_0) {

    unsigned coreid = get_coreid();
    int col = coreid >> 16;
    int row = coreid & 0x1F;

    for (int k = 0; k < 2; k++) {
        klog("CENk", k);
        int8_t *in0 = (int8_t *)acquire_input_window(window_in_0);
        int8_t *in1 = (int8_t *)acquire_input_window(window_in_1);
        int8_t *out = acquire_output_window(window_out_0);

        klog("IN0", (int8_t)(uintptr_t)in0);
        klog("IN1", (int8_t)(uintptr_t)in1);
        klog("OUT", (int8_t)(uintptr_t)out);

        // Kernel logic: read from both inputs, write to output
        for (int i = 0; i < BUF_SZ; i++) {
            if (k == 0 && i == 0) {
                in0[0] = row * 10 + col;
            }
            v4int8 data0 = *((v4int8 *)&in0[i * 4]);
            v4int8 data1 = *((v4int8 *)&in1[i * 4]);
            // Simple pass-through of input A for now (placeholder for GEMM)
            *((v4int8 *)&out[i * 4]) = data0;
        }
        klog("CLOP", BUF_SZ);

        release_input_window(window_in_0);
        release_input_window(window_in_1);
        release_output_window(window_out_0);
        klog("CEXT", 1);
    }
}
