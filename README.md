# 面向经济学实证研究的 Stata 可复现工作流

**作者：** 朱晨 | 中国农业大学  
**最后更新：** 2026-04-30

这是一个为经济学实证研究准备的 Stata 项目模板。核心目标是让一个研究项目从原始数据、清洗、变量构造、模型估计，到表格、图形和 Quarto 报告，都能被稳定复现、被日志验证，并且适合由 Codex 协助维护。

本仓库原本包含 Claude Code 配置；现在已经改为 **Codex 优先、Claude Code 兼容** 的结构。Codex 进入项目后应优先读取 `AGENTS.md`，原有 `.claude/` 和 `CLAUDE.md` 保留用于兼容 Claude Code，也可作为更详细的规则参考。

---

## 这个仓库做什么

本仓库提供一套 Stata 实证研究流水线：

- 原始数据放在 `data/raw/`，默认不提交。
- 中间数据放在 `data/derived/`，默认不提交。
- 主流水线入口是 `dofiles/00_master.do`。
- 正式 do-file 按阶段放入 `dofiles/01_clean/` 到 `dofiles/04_output/`。
- 表格输出到 `output/tables/`。
- 图形输出到 `output/figures/`。
- 报告使用 `reports/analysis_report.qmd`，通过 Quarto 渲染。
- 探索性分析、教学示例和一次性实验放在 `explorations/`。

这个模板不是一个已经完成的研究项目，而是一个可复用的研究项目骨架。当前正式流水线基本是骨架，`explorations/` 中包含两个可参考的教学示例。

---

## Codex 使用说明

Codex 的主说明文件是：

```text
AGENTS.md
```

Codex 后续维护本仓库时应遵守这些规则：

- 不改变 Stata 流水线的功能，除非用户明确要求。
- 新增或修改 Stata do-file 时，注释默认使用中文。
- 所有数值结论必须能追溯到 `logs/*.log` 或 `output/tables/*`。
- 没有日志或输出表格支撑时，不编造回归结果、标准误、样本量或描述统计。
- 不提交 `data/raw/`、`data/derived/`、Stata 日志或原始数据格式文件。
- 维护 `.gitignore` 的数据保护规则，不随意放松。
- 对 `.do`、`.qmd`、用户可见 Python 脚本做实质修改后，尽量运行质量检查。

Claude Code 兼容文件仍然存在：

- `CLAUDE.md`：Claude Code 的项目记忆入口。
- `.claude/`：Claude Code 的 agents、skills、rules、hooks。

这些文件不影响 Codex 使用。除非确定以后完全不使用 Claude Code，否则建议保留。

---

## 四个核心保证

| 保证 | 执行方式 |
|---|---|
| 可复现 | do-file 固定 Stata `version`，统一随机种子，使用相对路径，流水线从 `00_master.do` 启动 |
| 日志验证 | 数值结论必须来自 Stata log 或输出表格；无日志则不报告结果 |
| 数据保护 | `.gitignore` 阻止 raw/derived 数据、Stata 日志和数据文件误提交 |
| 发表级输出 | 表格通过 `esttab` 等工具输出，图形通过 `graph export` 输出为 `.pdf` 和 `.png` |

---

## 目录结构

```text
.
├── AGENTS.md                       # Codex 主说明文件
├── CLAUDE.md                       # Claude Code 兼容说明
├── MEMORY.md                       # 旧 Claude 工作流的长期记忆
├── .claude/                        # Claude Code agents、skills、rules、hooks
├── dofiles/
│   ├── 00_master.do                # 主流水线入口
│   ├── 01_clean/                   # 原始数据清洗
│   ├── 02_construct/               # 变量构造和样本构造
│   ├── 03_analysis/                # 回归、IV、DID、事件研究等
│   ├── 04_output/                  # 表格和图形汇总输出
│   └── _utils/                     # 可复用 Stata 工具代码
├── data/
│   ├── raw/                        # 原始数据，不提交
│   ├── derived/                    # 中间数据，不提交
│   └── README.md                   # 数据说明
├── logs/                           # Stata 日志，不提交
├── output/
│   ├── tables/                     # 结果表格，可提交
│   └── figures/                    # 结果图形，可提交
├── reports/                        # Quarto 报告
├── scripts/                        # 运行、复现和质量检查脚本
├── quality_reports/                # 计划、会话记录、合并报告
├── explorations/                   # 探索性分析和教学示例
└── templates/                      # 可复用模板
```

---

## 常用命令

运行完整流水线：

```bash
bash scripts/run_pipeline.sh
```

运行单个 do-file：

```bash
bash scripts/run_stata.sh dofiles/03_analysis/main_regression.do
```

渲染 Quarto 报告：

```bash
quarto render reports/analysis_report.qmd
```

提交前检查数据安全：

```bash
python scripts/check_data_safety.py --staged $(git diff --cached --name-only)
```

给 do-file、报告或 Python 脚本打质量分：

```bash
python scripts/quality_score.py dofiles/path/file.do
python scripts/quality_score.py reports/analysis_report.qmd
python scripts/quality_score.py scripts/check_data_safety.py
```

---

## Stata 编码约定

正式 do-file 应满足以下要求：

- 文件开头写明 `version`。
- 使用 `set more off`。
- 使用 `set varabbrev off`，避免变量缩写导致静默错误。
- 每个可独立运行的 do-file 都应开启日志。
- 使用相对路径，不写死本机绝对路径。
- 涉及随机过程时设置随机种子。
- 回归结果如果要进入表格，应使用 `estimates store` 或 `est store` 保存。
- 图形导出为 `.pdf` 和 `.png`，不要提交 `.gph`。
- 新增或修改的 Stata 注释默认使用中文。

---

## 数据保护规则

默认不得提交：

- `data/raw/**`
- `data/derived/**`
- `logs/**`
- `*.log`
- `*.smcl`
- `*.gph`
- `*.dta`
- `*.sav`
- `*.por`
- `*.parquet`
- `*.feather`
- `data/**/*.csv`

允许提交的典型文件：

- `data/README.md`
- `data/raw/.gitkeep`
- `data/derived/.gitkeep`
- `output/tables/*.csv`
- `output/tables/*.tex`
- `output/figures/*.pdf`
- `output/figures/*.png`
- `output/figures/*.svg`

如果确实需要提交某个聚合数据或示例数据，必须明确说明原因，并通过 `.gitignore` 做最小范围白名单。

---

## 日志验证规则

所有研究结果相关的数值结论都必须有来源。

可以作为来源的文件包括：

- `logs/*.log`
- `output/tables/*.csv`
- `output/tables/*.tex`

不能作为最终依据的内容包括：

- 记忆中的数字。
- 未保存的交互式 Stata 输出。
- 截图中的结果。
- 没有日志支撑的手工推算。

如果没有日志或输出表格，应先运行相关 do-file，而不是直接报告结果。

---

## 探索性分析

`explorations/` 是沙盒目录，适合放：

- 教学示例。
- 临时探索。
- 复现练习。
- 尚未进入正式流水线的一次性脚本。

每个探索性子目录应尽量自包含，通常包括自己的：

- `README.md`
- `dofiles/`
- `logs/`
- `output/`

当某个探索性分析成熟后，可以迁移到正式流水线：把 do-file 移入 `dofiles/01_clean/` 到 `dofiles/04_output/`，并接入 `dofiles/00_master.do`。

---

## 当前示例

当前仓库包含两个探索性教学示例：

- `explorations/hsb2_teaching_demo/`：基于 UCLA HSB2 数据的本科教学示例，包含描述统计、直方图和 OLS 回归。
- `explorations/educwages_tutorial/`：面向 Stata 初学者的教育回报教学示例，包含描述统计、图形、OLS、IV 和 ANOVA。

这些示例用于展示工作流，不代表正式研究项目。

---

## 本地环境

常用工具：

| 工具 | 用途 |
|---|---|
| Codex | 代码与文档维护、Stata 工作流协助 |
| Claude Code | 可选兼容工具 |
| Stata | 运行 do-file |
| Python 3 | Miniconda，`C:\ProgramData\Miniconda3\python.exe`，用于数据安全检查和质量评分 |
| Quarto | 渲染报告 |
| Git/GitHub CLI | 版本控制和协作 |

本机 Stata 版本是 Stata 15，路径是：

```text
C:\Program Files (x86)\Stata15\Stata-64.exe
```

如果 Stata 不在 `PATH` 中，需要先加入路径。例如 Windows Git Bash 下：

```bash
export PATH="/c/Program Files (x86)/Stata15:$PATH"
```

然后可以运行：

```bash
bash scripts/run_stata.sh dofiles/00_master.do
```

---

## 许可证

MIT。
