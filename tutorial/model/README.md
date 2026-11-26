# Whole models on the AIE

These tutorials take a complete network from a model file to a board run with
**aiegraph**. The A78 runs the C code that TVM generates, and the layers you
choose run on the AIE. Read them in order: chapter 1 needs no board and puts a
single layer on the AIE; the later chapters put every weighted layer of a
network on the AIE and run on a real board.

## Chapters

| # | Tutorial | Model | What runs on the AIE | You learn |
|---|---|---|---|---|
| 1 | [Quickstart: download ResNet-18 and offload its first conv2d](01_quickstart_resnet18.md) | ResNet-18 (ONNX zoo), int8 | the first conv2d (7x7 stem), one local AIE kernel | the aiegraph flow step by step: `load` -> `embedded_convert` -> `detect` -> `offload_check` (x86 proof) -> `offload` -> `build` -> `run` |
| 2 | [ResNet-18: classify real images](02_resnet18.md) | ResNet-18, 1x3x224x224 -> 1000 logits | all 20 Conv layers and the Gemm (bf16 `gemm_kacc`) | group offload of a whole CNN with `aiegraph.cnn.offload_all()`, board run, comparison with onnxruntime |
| 3 | [tiny-SD UNet: generate an orange](03_tiny-sdm-unet.md) | bk-sdm-tiny UNet, 256x256 | conv, Linear and attention | a hand-written offload declaration for a non-CNN model; text encoder and VAE on the host, every UNet step on the board |
| 4 | [YOLOv26: object detection](04_yolov26.md) | yolo26n, 1x3x640x640 | all 102 Conv layers, 8 of them depthwise | a model with a detection post-processing tail (`TAIL_OP`), boxes compared with onnxruntime |

## Before you start

- Chapter 1 needs only `pip install -e .` from the repo root; Vitis only for
  its build steps, a board only for its last step.
- Chapters 2-4 share their setup (branch, BSP workspace, aiehlc build): see
  sections 1-3 of [chapter 3](03_tiny-sdm-unet.md).
- The general aiegraph API reference is the
  [aiegraph user guide](../../doc/tutorial_aiegraph.md).
