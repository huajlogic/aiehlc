# BYOC → AIE 集成计划（方案 A：单 ELF）

把 TVM BYOC 分区出来的卷积子图接到 aiehlc 生成的 AIE kernel 上，**所有东西链进
同一个 `main.elf`**，由 TVM 的 graph executor 负责调度。

**spatial tiling / halo / mesh 切分 / 路由 / DMA / tile 预算 全部由 aiehlc
(`run_aie_pipeline`) 负责。** 本计划里我方代码不碰这些，只做翻译和接线。

---

## 0. 现状（已实测，不是推测）

BYOC 四块代码已写完并跑通（`src/frontend/tvmrelay/byoc/`）：

```
MergeComposite 匹配到 20 个 aie.qconv
标注 5 个下沉 AIE (上限 5)
分区出 5 个 AIE 子图
relay.build OK → 6 个 C 模块（1 TVM kernels + 5 AIE wrapper），430,743 字符
交叉编译通过 (aarch64-none-elf-gcc -fsyntax-only)
```

**但 wrapper 函数体是占位实现**（按元素搬运 + clamp），分类结果不正确。本计划
就是把它换成真的 AIE 调用。

已确认的下游兼容性：

| 环节 | 结论 | 证据 |
|---|---|---|
| `graph.json` | 无需改 | 5 个 AIE 子图是普通 `tvm_op` 节点，119 节点中正常排列 |
| `arm_build.py` driver | 无需改 | 按 `func_name` 生成调用，不关心实现者 |
| `split_layers.py` | 自动适配 | 切分正则就是 `extern "C" + TVM_DLL`，wrapper 自成 layer |
| `params.bin` | 无需改 | 177 条，与非 BYOC 一致 |
| `build_c` | **要改** | `lib.lib.get_source()` 在复合模块上抛 `Module[const_loader] does not support GetSource` |

---

## 1. 接口（已从代码中读出，不是假设）

### aiehlc 侧的入口

`orchestrate_conv_layer(..., host_func_suffix=name)` 产出：

```c
void host_canonicalized_<name>(XAie_DevInst* dev, void* in, void* params, void* out);
extern unsigned char _binary_kernel_<name>_start[];
```

调用契约（抄自 `orchestrator._emit_dispatcher`，它镜像 `aiehlc.cc:4711-4734`）：

```c
XAie_DevInst* dev = __Runtime_get_partition_dev(mesh.meshId);
__Runtime_set_kernel_elf(_binary_kernel_<name>_start);
__Runtime_sync_for_dev(dev, t0, s0);          // 每个 DDR 参数一次
__Runtime_sync_for_dev(dev, t1, s1);
host_canonicalized_<name>(dev, t0, t1, t2);
```

### params buffer 布局（`model.make_conv_params`）

```
[config:12B][weights:Cin*Cout*K*K][bn_scale:Cout][bn_bias:Cout]
 ^ 6 个 uint16 LE: H, W, Cin, Cout, K, stride
```

**这个 header 有 ~6 处读取方，必须锁步**（CLAUDE.md 已记录：一处读错会静默算错）。

### TVM 侧的入口（我生成的 wrapper）

```c
TVM_DLL int tvmgen_default_aie_main_0(void* args, int* type_codes, int num_args,
                                      void* out_value, int* out_type_code);
```

**我要实现的就是这两者之间的胶水。**

---

## 2. 我要写的四件事（都是翻译/接线）

### 2.1 几何抽取 — 从 Relay 子图读参数
从子图的 `nn.conv2d` attrs + `checked_type` 读出
`H/W/Cin/Cout/K/stride/padding/groups`。纯查属性。
**验收**：20 个卷积的几何与 `graph.json` shape 推出的值逐一相符。

### 2.2 `tensor_specs` 生成 — 声明张量，不决定怎么切
转成 `run_aie_pipeline` 要的 `[(shape, bits, is_input), ...]`。
**只声明"有哪些张量、多大、是输入还是输出"**；怎么切给 mesh 是 aiehlc 的事。

### 2.3 params blob 打包 — 真权重，不是占位
现有 `make_conv_params` 填的是交替 ±1 的**假权重**。要换成从 Relay Constant
读出的真 int8 权重 + 真 bias，按上面的布局打包。
**验收**：解包回来与 Relay Constant 逐字节相同。

### 2.4 ABI 胶水 — 唯一有实质工作的部分
`aie_codegen.py` 的 wrapper 函数体从"搬运 clamp"换成：

```c
TVM_DLL int tvmgen_default_aie_main_0(void* args, ...) {
    /* 1. 解包 DLTensor → 裸指针 */
    /* 2. __Runtime_set_kernel_elf(_binary_kernel_<name>_start); */
    /* 3. __Runtime_sync_for_dev(dev, p, size) 每个 DDR 参数 */
    /* 4. host_canonicalized_<name>(dev, in, params, out); */
}
```

---

## 3. 阶段划分

### 阶段 1 — 接通管线（低风险，先做）
- `build_c` 改为遍历模块树收集所有 `type_key=='c'` 的源码并拼接
  （**已验证**：6 个模块 → 430,743 字符 → 交叉编译通过）
- `deploy_flow` 加 `--byoc-aie [N]`，默认关
- **验收**：`N=0` 产出的 ELF 与非 BYOC 路径**逐字节相同**

### 阶段 2 — 单层真实 kernel（核心）
先只做 **1 层**（`N=1`），打通 2.1–2.4 全部四件事。
- 调 `run_aie_pipeline` 生成该层的 `host.cc`/`kernel.cc`/`routing.cc`/`.bcf`
- wrapper 换成真调用
- **验收**：该层输出与 TVM CPU 参考逐元素比对（允许量化误差，但不能是垃圾）
- **风险**：tile 放不下由 aiehlc 报错；我方不预判、不预先拒绝

### 阶段 3 — 链接整合
- `arm_build.py` 的 `SRCS` 加入 aiehlc 产出的 `.cc`
- kernel ELF 通过 `ld -r -b binary` 嵌入（复用 weights.bin 的现成机制）
- 设备生命周期：`main.c` 开头 `__Runtime_device_init`、结尾 teardown
- **验收**：`main.elf` 链接成功，板上跑完打印 `device_teardown done`

### 阶段 4 — 扩到 N 层 + 精度验证
- `N=5` → `N=20`
- 板上 top-5 与 CPU 参考比对，top-1 必须仍是 Samoyed(258)
- 用已有 timer 量 `inference` ms，对比纯 CPU 基线

### 阶段 5 — 收敛与文档
- **三条 AIE 路径必须合并**：`--aie-offload` / `--aiegraph` / `--byoc-aie`。
  前两条因 ONNX-PTQ 默认化已失效（0/28 eligible，已确认）。建议 BYOC 成为唯一
  路径，前两条标废弃。
- README + skill 记录 TVM 0.16 的三个坑

---

## 4. 已知风险

| 风险 | 性质 | 应对 |
|---|---|---|
| tile 放不下 | **aiehlc 负责** | 不预判；由 aiehlc 报错后再谈 |
| params header 6 处读取方不同步 | 静默算错 | 阶段 2 加解包回读断言 |
| 设备生命周期在 TVM 调度下的时机 | 未验证 | 阶段 3 的主要未知数：TVM 可能多次调用子图，init 不能重入 |
| int16 存储（非 int8） | 已知 | `target="c"` 无 int8 qnn legalization；与本计划正交 |

**最大未知数是阶段 3 的设备生命周期**——TVM graph executor 何时调用子图、是否
并发、`XAie_DevInst` 怎么共享。这是方案 A（单 ELF）相对方案 B 的主要代价。
