# Exploration: MROZ 教学示例

这个示例使用 `data/raw/MROZ.DTA` 演示 Stata 入门分析流程。脚本面向第一次学习 Stata 的大一学生，所有注释和解释尽量使用中文。

运行方式：

```bash
bash scripts/run_stata.sh explorations/mroz_tutorial/dofiles/01_mroz_analysis.do
```

或在 Windows PowerShell 中直接使用本机 Stata 15：

```powershell
& 'C:\Program Files (x86)\Stata15\Stata-64.exe' /b do 'explorations\mroz_tutorial\dofiles\01_mroz_analysis.do'
```

主要输出：

- `explorations/mroz_tutorial/output/tables/mroz_summary_stats.csv`
- `explorations/mroz_tutorial/output/tables/mroz_income_by_educ_group.csv`
- `explorations/mroz_tutorial/output/tables/mroz_ols_lwage.csv`
- `explorations/mroz_tutorial/output/tables/mroz_logit_inlf.csv`
- `explorations/mroz_tutorial/output/figures/mroz_faminc_histogram.pdf`
- `explorations/mroz_tutorial/output/figures/mroz_faminc_histogram.png`
- `explorations/mroz_tutorial/output/figures/mroz_wage_educ_scatter.pdf`
- `explorations/mroz_tutorial/output/figures/mroz_wage_educ_scatter.png`
- `logs/mroz_tutorial_01_mroz_analysis.log`
