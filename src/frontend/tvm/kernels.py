###############################################################################
# Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""Raw-C compute kernel bodies for the scaled ResNet-18 AIE launches.

Each generator returns a *complete* ``void <func>(...) {...}`` C function that
``TilingLinalgPipeline::runPipeline`` writes verbatim to ``<func>.cc`` (see
``tilinglinalg_pipeline.cpp:1358`` — ``userKernelBody`` is emitted unchanged).

ABI (matches the pipeline's auto-generated compute kernel, ``:1378``):
    void <func>(input_window_int8 *window_in_0,
                input_window_int8 *window_in_1,      # optional 2nd input
                output_window_int8 *window_out_0) {
        int8_t *x = (int8_t *)acquire_input_window(window_in_0);
        ...
        release_input_window(window_in_0);
        release_output_window(window_out_0);
    }

The numeric math is a byte-for-byte C transcription of the four ``@aie_triton.jit``
kernels in ``example/tileprogram/design/triton/resnet18_triton.py`` and of the
numpy CPU references used to verify them. Two int16 wrap details are load-bearing
for bit-exactness with those references:

  * The convolution accumulator is ``int16_t`` and wraps at each ``+=`` step
    (large convs exceed int16 — that overflow is part of the defined result, so
    both the CPU ref and this kernel must wrap identically).
  * Q7 BN is ``(int16)(acc * bn_scale) >> 7`` — the *product* is truncated to
    int16 **before** the shift (numpy computes ``(np.int16(s)*np.int16(scale))>>7``
    in int16), so we cast to int16 before ``>>7``.

Config travels in the parameter buffer header (not as scalar kernel args, which
this ABI has no room for), so ONE body serves every conv/fc launch:
  * conv params:  [config:6 = {H,W,Cin,Cout,K,stride}][weights][bn_scale][bn_bias]
  * fc params:    [config:4 = {sp_h,sp_w,channels,nclass}][weights][bias]
Config bytes are read as ``uint8`` (matching the CPU ref's ``int(np.uint8(...))``).

The residual kernel has no param buffer, so its element count comes from the
pipeline's ``BUF_SZ_OUT_0`` macro (``passdfscheduletokernelapi.cpp:123``). That
macro is emitted in the same units the auto-generated kernel treats as vector
groups, i.e. total scalar elements == ``BUF_SZ_OUT_0 * 4`` (see the debug dump at
``tilinglinalg_pipeline.cpp:1441``); we follow that same convention.
"""


def _conv_body(func_name: str, relu: bool) -> str:
    """Conv2D + Q7 BN (+ optional ReLU) — one AIE tile, config from params header."""
    lo = "0" if relu else "-128"
    kind = "conv_bn_relu" if relu else "conv_bn"
    return f"""// {kind}: Conv2D + Q7 BatchNorm{' + ReLU' if relu else ''} (config read from params header)
void {func_name}(input_window_int8 *window_in_0, input_window_int8 *window_in_1,
                 output_window_int8 *window_out_0) {{
    int8_t *feat_in = (int8_t *)acquire_input_window(window_in_0);
    int8_t *params  = (int8_t *)acquire_input_window(window_in_1);
    int8_t *out     = (int8_t *)acquire_output_window(window_out_0);

    int H      = (int)(uint8_t)params[0];
    int W      = (int)(uint8_t)params[1];
    int Cin    = (int)(uint8_t)params[2];
    int Cout   = (int)(uint8_t)params[3];
    int K      = (int)(uint8_t)params[4];
    int stride = (int)(uint8_t)params[5];
    int pad  = K / 2;
    int outH = H / stride;
    int outW = W / stride;
    int wt_count = Cin * Cout * K * K;
    int8_t *weights  = &params[6];
    int8_t *bn_scale = &params[6 + wt_count];
    int8_t *bn_bias  = &params[6 + wt_count + Cout];

    for (int oc = 0; oc < Cout; oc++) {{
        for (int oh = 0; oh < outH; oh++) {{
            for (int ow = 0; ow < outW; ow++) {{
                int16_t acc = 0;
                for (int ic = 0; ic < Cin; ic++) {{
                    for (int kh = 0; kh < K; kh++) {{
                        for (int kw = 0; kw < K; kw++) {{
                            int ih = oh * stride + kh - pad;
                            int iw = ow * stride + kw - pad;
                            if (ih >= 0 && ih < H && iw >= 0 && iw < W) {{
                                int in_idx = ic * H * W + ih * W + iw;
                                int wt_idx = oc * Cin * K * K + ic * K * K + kh * K + kw;
                                acc += (int16_t)feat_in[in_idx] * (int16_t)weights[wt_idx];
                            }}
                        }}
                    }}
                }}
                // Q7 BN: (int16)(acc*scale) >> 7 + bias  (int16 wrap before shift)
                int16_t bn_out = (int16_t)(acc * (int16_t)bn_scale[oc]) >> 7;
                bn_out += (int16_t)bn_bias[oc];
                if (bn_out > 127) bn_out = 127;
                if (bn_out < {lo}) bn_out = {lo};
                out[oc * outH * outW + oh * outW + ow] = (int8_t)bn_out;
            }}
        }}
    }}

    release_input_window(window_in_0);
    release_input_window(window_in_1);
    release_output_window(window_out_0);
}}
"""


def conv_bn_relu_body(func_name: str) -> str:
    return _conv_body(func_name, relu=True)


def conv_bn_body(func_name: str) -> str:
    return _conv_body(func_name, relu=False)


def residual_add_relu_body(func_name: str) -> str:
    """Element-wise main + skip, then ReLU + saturate. Length from BUF_SZ_OUT_0."""
    return f"""// residual_add_relu: element-wise add of main+skip paths, then ReLU
void {func_name}(input_window_int8 *window_in_0, input_window_int8 *window_in_1,
                 output_window_int8 *window_out_0) {{
    int8_t *main_in = (int8_t *)acquire_input_window(window_in_0);
    int8_t *skip_in = (int8_t *)acquire_input_window(window_in_1);
    int8_t *out     = (int8_t *)acquire_output_window(window_out_0);

    int n = BUF_SZ_OUT_0 * 4;   // total scalar int8 elements in the output window
    for (int i = 0; i < n; i++) {{
        int16_t s = (int16_t)main_in[i] + (int16_t)skip_in[i];
        if (s > 127) s = 127;
        if (s < 0)   s = 0;
        out[i] = (int8_t)s;
    }}

    release_input_window(window_in_0);
    release_input_window(window_in_1);
    release_output_window(window_out_0);
}}
"""


def avgpool_fc_body(func_name: str) -> str:
    """Global average pool + FC classifier. Config from 4-byte fc params header."""
    return f"""// avgpool_fc: global average pool + FC classifier (config from fc params header)
void {func_name}(input_window_int8 *window_in_0, input_window_int8 *window_in_1,
                 output_window_int8 *window_out_0) {{
    int8_t *feat      = (int8_t *)acquire_input_window(window_in_0);
    int8_t *fc_params = (int8_t *)acquire_input_window(window_in_1);
    int8_t *logits    = (int8_t *)acquire_output_window(window_out_0);

    int spatial_h   = (int)(uint8_t)fc_params[0];
    int spatial_w   = (int)(uint8_t)fc_params[1];
    int channels    = (int)(uint8_t)fc_params[2];
    int num_classes = (int)(uint8_t)fc_params[3];
    int spatial_sz  = spatial_h * spatial_w;
    int8_t *fc_weights = &fc_params[4];
    int8_t *fc_bias    = &fc_params[4 + channels * num_classes];

    int8_t pooled[256];
    for (int c = 0; c < channels; c++) {{
        int16_t s = 0;
        for (int idx = 0; idx < spatial_sz; idx++)
            s += (int16_t)feat[c * spatial_sz + idx];
        pooled[c] = (int8_t)((int)s / spatial_sz);   // feat is >=0 here: trunc == floor
    }}

    for (int j = 0; j < num_classes; j++) {{
        int16_t acc = 0;
        for (int i = 0; i < channels; i++)
            acc += (int16_t)pooled[i] * (int16_t)fc_weights[i * num_classes + j];
        acc += (int16_t)fc_bias[j];
        if (acc > 127)  acc = 127;
        if (acc < -128) acc = -128;
        logits[j] = (int8_t)acc;
    }}

    release_input_window(window_in_0);
    release_input_window(window_in_1);
    release_output_window(window_out_0);
}}
"""


# Map plan op name -> (body generator, #input windows, #output windows).
KERNEL_BODIES = {
    "conv_bn_relu":      (conv_bn_relu_body, 2, 1),
    "conv_bn":           (conv_bn_body, 2, 1),
    "residual_add_relu": (residual_add_relu_body, 2, 1),
    "avgpool_fc":        (avgpool_fc_body, 2, 1),
}


def kernel_body_for(op: str, func_name: str) -> str:
    """Return the full C function body for plan op ``op`` named ``func_name``."""
    if op not in KERNEL_BODIES:
        raise ValueError(f"no kernel body for op {op!r}")
    return KERNEL_BODIES[op][0](func_name)


def kernel_windows_for(op: str) -> tuple:
    """Return ``(num_input_windows, num_output_windows)`` for plan op ``op``."""
    if op not in KERNEL_BODIES:
        raise ValueError(f"no kernel body for op {op!r}")
    _, nin, nout = KERNEL_BODIES[op]
    return nin, nout
