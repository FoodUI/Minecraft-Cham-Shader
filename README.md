# [Cham] 内透光影 Plus

给 Minecraft 用的**穿墙显示**光影包：玩家 / 箱子（含末影箱）/ 床 三路独立开关，
带夜视、去实体阴影和 OptiFine 设置面板。

> [!WARNING]
> 这是**纯客户端视觉外挂**。它只改本机 GPU 的深度输出，不修改游戏数据、不与服务端
> 交互、不产生网络包，但会让使用者在 PvP 中获得不公平的信息优势。
> 请只在单人存档或明确允许的服务器上使用；在对抗性服务器上使用属于作弊，
> 后果自负，与本项目作者无关。

---

## 功能

| 开关 | 作用 | 实现阶段 |
|---|---|---|
| 玩家透视 | 整段实体渲染前移 | `gbuffers_entities` |
| 箱子透视 | 箱子、末影箱、木桶、潜影盒 | `gbuffers_block` |
| 床透视 | 16 色床（1.12+）/ 单色床（1.11-） | `gbuffers_terrain` |
| 名称底板 | 保留 / 隐藏 / 半透明 三档 | `gbuffers_entities` |
| 夜视 | 全局满亮度 | 全部阶段 |
| 去掉实体阴影 | 移除脚下黑投影 | `gbuffers_entities` |
| 透视目标全亮 | 只让目标不受光照 | 全部阶段 |
| 透视目标免雾 | 远处目标不被雾染色 | 全部阶段 |
| F1 应急关闭 | 按 F1 同时关掉全部透视 | 全部阶段 |
| 调试着色 | 把判定为目标的像素涂品红 | 全部阶段 |

---

## 安装

1. 把 `[Cham]内透光影Plus.zip` 放进 `.minecraft/shaderpacks/`
2. 游戏内 `选项 → 视频设置 → 光影`，选择 `[Cham]内透光影Plus`
3. 点右下角 **光影设置** 打开面板

需要 OptiFine 或 Iris。只覆盖 4 个渲染阶段，其余走加载器内置回退，画面接近原版。

---

## 面板结构

```
光影设置
├─ <全开 / 全关>           一键档位
├─ [透视开关]              玩家 · 箱子 · 床
├─ [夜视与视觉]            名称底板 · 夜视 · 去掉实体阴影 · 目标全亮 · 目标免雾
└─ [高级]                  F1 应急关闭 · 调试着色
```

面板由 `#define` 生成：`settings.glsl` 里每个 `#define` 变成一个选项，
`shaders.properties` 决定布局，`lang/*.lang` 提供中英文标签与悬停说明。

---

## 原理

`gl_Position` 处于裁剪空间，GPU 之后才做透视除法：

```
NDC.z = clip.z / clip.w
depth = NDC.z * 0.5 + 0.5
```

把裁剪空间的 z 乘 0.01，`NDC.z` 就落进 `[-0.01, 0.01]`，深度被钉在 **0.5 附近**。
透视投影里深度是非线性的，`depth = 0.5` 在 `near = 0.05` 下只对应约 **0.1 格**，
于是比相机远 10 cm 以上的墙体全部在深度测试中判负，目标就画在了墙前面。

```glsl
if (hideGUI == false) {
    gl_Position.z *= 0.01;
}
```

因为乘的是正数，**目标之间的远近顺序仍然保留**，不会互相穿插。

代价是深度只剩缓冲区 1% 的精度：

| 距离 | 24 位可用级数 | 16 位可用级数 |
|---|---|---|
| 1 格 | 7991 | 31 |
| 5 格 | 270 | 1.1 |
| 10 格 | 67 | 0.3 |
| 20 格 | 17 | 0.1 |
| 60 格 | 1.9 | 0.0 |

1–10 格（PvP 常见距离）够用；20 格以外级数掉到个位数时，同一立方体的前后表面会
落进同一个量化桶，`GL_LEQUAL` 让最后绘制的面胜出，可能出现单面或闪烁。
想改善可换成仿射重映射 `ndc' = A·ndc - (1-A)`，A 取 0.7 时精度提升约 70 倍，
遮挡边界只从 10 cm 变成 17 cm。

---

## 已知限制

- **没有矿物透视**。MC 建区块网格时会剔除被不透明方块挡住的面，完全埋在石头里的
  矿物没有几何数据，着色器造不出面。要整块矿物透视得改方块模型（资源包去掉
  `cullface`），不是着色器能做的。
- **实体透视不区分玩家和生物**。整段实体一起前移，这是最初写法的行为。
- **箱子是整段开关**。`mc_Entity` 只在 terrain 类程序有效，`gbuffers_block` 拿不到
  方块 ID，所以告示牌、旗帜、信标光柱也会跟着透。
- **反转深度（reversed-Z）的版本会失效**，效果从"透视"变成"目标消失"。
- 只覆盖 4 个阶段，水面 / 粒子 / 手持物仍用回退，深度正常。

---

## 仓库结构

```
.
├── README.md
├── [Cham]内透光影Plus.zip      ← 打包产物，直接拖进 shaderpacks/
├── xray-plus/                 ← 光影包源码
│   └── shaders/
│       ├── shaders.properties     面板布局 + 一键档位
│       ├── block.properties       床 ID 映射（按 MC_VERSION 分支）
│       ├── entity.properties      玩家 / 投影 / 名称牌 ID
│       ├── settings.glsl          开关 + ID 常量
│       ├── gbuffers_terrain.vsh/fsh
│       ├── gbuffers_block.vsh/fsh
│       ├── gbuffers_entities.vsh/fsh
│       └── lang/{zh_cn,zh_CN,en_us}.lang
└── tools/
    ├── check_pack.py          静态自检（不启动游戏）
    └── build_pack.py          打包
```

```bash
python3 tools/check_pack.py     # 自检
python3 tools/build_pack.py     # 生成 zip
```

自检覆盖：选项 ↔ 面板 ↔ 语言文件三方对齐、varying 配对、`#ifdef` 宏都已定义、
`block.properties` 编号落在区间内且无重复、`entity.properties` 编号与着色器常量一致、
深度系数必须是 `0.01`、输出 alpha 不得包含光照图 alpha、括号平衡。

---

## AI 生成说明

本仓库分为两部分，来源不同：

### 原始部分（非 AI）

`[Cham]内透光影.zip` 是别人写的，作者署名 **Cham**，压缩包里只有
`gbuffers_entities.vsh` / `.fsh` 两个文件、共 87 行，**是明文 GLSL，没有混淆**。
它做的事情就是上面那一行 `gl_Position.z *= 0.01`，外加一堆从完整光影包抄来的样板
（法线编码、`DRAWBUFFERS:04`、死代码）。本项目沿用了它的核心写法和 `hideGUI` 开关逻辑。

### AI 生成部分

除上述 87 行之外，**本仓库的其余内容全部由 AI 生成**（DeepSeek Harness，模型
deepseek-flash），在对话中逐轮迭代而成，包括：

- 全部面板机制：`settings.glsl` 的选项定义、`shaders.properties` 的页面布局、
  `lang/*.lang` 的中英文标签
- 两个新增渲染阶段：`gbuffers_terrain`（床）、`gbuffers_block`（箱子）
- 实体 ID 映射 `entity.properties`、方块 ID 映射 `block.properties`
- 夜视、去实体阴影、名称底板样式、调试着色
- 名称牌发黑、玩家消失、底板纯黑等 bug 的定位与修复
- `tools/check_pack.py`、`tools/build_pack.py`、本 README

### 未经验证的部分

**这套光影没有在真实 Minecraft 里运行过。**所有结论来自代码阅读、GLSL/加载器文档
查阅和数学推导，验证方式是 `tools/check_pack.py` 的静态检查，它只能抓语法、
选项注册、常量一致性这类问题，抓不到"看起来是黑的"这种视觉问题。

因此：

- 实际效果、兼容性、性能都未经实测
- 遇到问题欢迎提 issue，附上 `logs/latest.log` 里的 `[Shaders]` 行
- 不要把这里的任何结论当作已证实的运行时行为

### 迭代中修正过的错误

为便于判断可信度，以下是 AI 生成过程中被现实纠正过的判断：

| 曾以为 | 实际 |
|---|---|
| "没混淆所以没有可分析的东西" | 核心逻辑确实只有 1 行，但样板代码会掩盖它 |
| 深度压缩只影响精度 | 压缩到 1% 会让立方体六面落进同一量化桶，且不可逆 |
| 名称底板是未受光层 | 底板是**受光**绘制的，用 `unlit` 判定从未命中 |
| 整 vec4 相乘能保留 alpha | 光照图 alpha 是 0，整 vec4 相乘会让实体全透明 |
| `entityId` 能稳定区分玩家 | 取决于加载器是否支持 `entity.properties`，最终放弃用它筛选 |
