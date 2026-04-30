*------------------------------------------------------------------------------
* File:     explorations/mroz_tutorial/dofiles/01_mroz_analysis.do
* Project:  MROZ 数据 Stata 入门教学示例
* Author:   Chen Zhu / Codex
* Purpose:  描述性统计、直方图、散点图、收入方差分析、工资 OLS、
*           以及劳动参与 Logit 回归。
* Inputs:   data/raw/MROZ.DTA
* Outputs:  explorations/mroz_tutorial/output/tables/ 下的 CSV 表格
*           explorations/mroz_tutorial/output/figures/ 下的 PDF 和 PNG 图像
* Log:      logs/mroz_tutorial_01_mroz_analysis.log
*------------------------------------------------------------------------------

version 15
clear all
set more off
set varabbrev off

capture log close
log using "logs/mroz_tutorial_01_mroz_analysis.log", replace text

*------------------------------------------------------------------------------
* 第 0 步：创建输出文件夹
*------------------------------------------------------------------------------
* mkdir 用来创建文件夹。capture 表示如果文件夹已经存在，就忽略这个小错误。
capture mkdir "explorations/mroz_tutorial"
capture mkdir "explorations/mroz_tutorial/output"
capture mkdir "explorations/mroz_tutorial/output/tables"
capture mkdir "explorations/mroz_tutorial/output/figures"

*------------------------------------------------------------------------------
* 第 1 步：读取数据
*------------------------------------------------------------------------------
* use 是读取 Stata 数据的命令。clear 表示先清空内存，再读入新数据。
use "data/raw/MROZ.DTA", clear

display "============================================================"
display "MROZ data loaded. First inspect variable definitions."
display "============================================================"

describe

*------------------------------------------------------------------------------
* 第 2 步：给关键变量贴标签
*------------------------------------------------------------------------------
* 标签不改变数据，只是让表格和图形更容易阅读。
* 命令里的图形文字使用英文，是为了避免 Stata 15 batch 模式处理中文图形文字不稳定。
label variable inlf     "In labor force"
label variable hours    "Hours worked in 1975"
label variable kidslt6  "Number of children under 6"
label variable kidsge6  "Number of children age 6-18"
label variable age      "Woman's age"
label variable educ     "Years of education"
label variable wage     "Estimated hourly wage"
label variable faminc   "Family income"
label variable exper    "Labor market experience"
label variable nwifeinc "Non-wife income, thousand dollars"
label variable lwage    "Log hourly wage"
label variable expersq  "Experience squared"

*------------------------------------------------------------------------------
* 第 3 步：统一图形风格
*------------------------------------------------------------------------------
* 这里集中设置以后所有图片的样式，避免每张图的颜色和字体不一致。
* Stata 15 对自定义 RGB 颜色的写法是 "R G B"。
local stata_blue `"49 145 255"'
local title_color `"27 40 56"'
local grid_color gs14

capture graph set window fontface "Arial"
capture graph set ps fontface "Arial"
set scheme s2color

*------------------------------------------------------------------------------
* 第 4 步：描述性统计
*------------------------------------------------------------------------------
* summarize 会显示样本量、均值、标准差、最小值和最大值。
* 这里同时把结果写入 CSV，方便以后放进报告或作业。
local desc_vars inlf hours age educ wage faminc kidslt6 kidsge6 exper nwifeinc

file open desc_out using ///
    "explorations/mroz_tutorial/output/tables/mroz_summary_stats.csv", ///
    write replace
file write desc_out "variable,label,N,mean,sd,min,max" _n

foreach var of local desc_vars {
    quietly summarize `var'
    local vlabel : variable label `var'
    file write desc_out "`var',`vlabel'," ///
        (r(N)) "," (r(mean)) "," (r(sd)) "," (r(min)) "," (r(max)) _n
}

file close desc_out

summarize `desc_vars'

*------------------------------------------------------------------------------
* 第 5 步：收入的方差分析
*------------------------------------------------------------------------------
* 方差分析用来比较多个组的均值是否相同。
* 这里把教育年限分成四组，然后比较不同教育组的家庭收入均值。
generate byte educ_group = .
replace educ_group = 1 if educ < 12
replace educ_group = 2 if educ == 12
replace educ_group = 3 if educ >= 13 & educ <= 15
replace educ_group = 4 if educ >= 16 & educ < .

label define educ_group_lbl ///
    1 "Less than high school" ///
    2 "High school" ///
    3 "Some college" ///
    4 "College or more"
label values educ_group educ_group_lbl
label variable educ_group "Education group"

tabulate educ_group, missing

preserve
collapse ///
    (count) N=faminc ///
    (mean) mean_faminc=faminc ///
    (sd) sd_faminc=faminc ///
    (min) min_faminc=faminc ///
    (max) max_faminc=faminc, ///
    by(educ_group)
decode educ_group, gen(educ_group_name)
order educ_group educ_group_name N mean_faminc sd_faminc min_faminc max_faminc
export delimited using ///
    "explorations/mroz_tutorial/output/tables/mroz_income_by_educ_group.csv", ///
    replace
restore

anova faminc i.educ_group

*------------------------------------------------------------------------------
* 第 6 步：Logit 回归
*------------------------------------------------------------------------------
* Logit 用来分析 0 和 1 的因变量。
* inlf 等于 1 表示参加劳动市场，等于 0 表示没有参加。
quietly logit inlf educ age kidslt6 kidsge6 nwifeinc exper expersq
estimates store logit_inlf

display "Logit N = " e(N)
display "Log likelihood = " e(ll)
display "LR chi-square = " e(chi2)
display "Pseudo R-squared = " e(r2_p)

matrix logit_table = r(table)'
matrix colnames logit_table = b se z pvalue ll ul df crit eform
svmat logit_table, names(col)

generate str32 term = ""
local coefnames : rownames logit_table
local i = 1
foreach name of local coefnames {
    replace term = "`name'" in `i'
    local ++i
}

order term b se z pvalue ll ul
keep if term != ""
keep term b se z pvalue ll ul
export delimited using ///
    "explorations/mroz_tutorial/output/tables/mroz_logit_inlf.csv", ///
    replace

*------------------------------------------------------------------------------
* 第 7 步：OLS 回归
*------------------------------------------------------------------------------
* OLS 是最基础的线性回归。
* 因变量是 lwage，也就是小时工资的自然对数。
use "data/raw/MROZ.DTA", clear
quietly regress lwage educ exper expersq city kidslt6 kidsge6
estimates store ols_lwage

display "OLS N = " e(N)
display "OLS F statistic = " e(F)
display "OLS R-squared = " e(r2)
display "OLS adjusted R-squared = " e(r2_a)

matrix ols_table = r(table)'
matrix colnames ols_table = b se t pvalue ll ul df crit eform
svmat ols_table, names(col)

generate str32 term = ""
local coefnames : rownames ols_table
local i = 1
foreach name of local coefnames {
    replace term = "`name'" in `i'
    local ++i
}

order term b se t pvalue ll ul
keep if term != ""
keep term b se t pvalue ll ul
export delimited using ///
    "explorations/mroz_tutorial/output/tables/mroz_ols_lwage.csv", ///
    replace

*------------------------------------------------------------------------------
* 第 8 步：直方图
*------------------------------------------------------------------------------
* 直方图展示一个变量的分布。
* 按你的图形规范：背景白色，柱子为 Stata 风格蓝色，横向网格线浅灰且较细。
use "data/raw/MROZ.DTA", clear
histogram faminc, percent ///
    fcolor("`stata_blue'") lcolor("`stata_blue'") lwidth(vthin) ///
    graphregion(color(white)) plotregion(color(white) margin(medium)) ///
    bgcolor(white) ///
    title("Family income distribution", size(medium) color("`title_color'")) ///
    xtitle("Family income", size(small)) ///
    ytitle("Percent", size(small)) ///
    xlabel(, labsize(small)) ///
    ylabel(, labsize(small) grid glcolor(`grid_color') glwidth(vthin)) ///
    legend(off)

graph export "explorations/mroz_tutorial/output/figures/mroz_faminc_histogram.pdf", replace
graph export "explorations/mroz_tutorial/output/figures/mroz_faminc_histogram.png", replace width(1600)
graph drop _all

*------------------------------------------------------------------------------
* 第 9 步：散点图
*------------------------------------------------------------------------------
* 散点图展示两个变量之间的关系。
* 这里用教育年限 educ 作横轴，用小时工资 wage 作纵轴。
use "data/raw/MROZ.DTA", clear
scatter wage educ if wage < ., ///
    mcolor("`stata_blue'") mlcolor("`stata_blue'") msymbol(circle) msize(small) ///
    graphregion(color(white)) plotregion(color(white) margin(medium)) ///
    bgcolor(white) ///
    title("Education and hourly wage", size(medium) color("`title_color'")) ///
    xtitle("Years of education", size(small)) ///
    ytitle("Hourly wage", size(small)) ///
    xlabel(, labsize(small)) ///
    ylabel(, labsize(small) grid glcolor(`grid_color') glwidth(vthin)) ///
    legend(off)

graph export "explorations/mroz_tutorial/output/figures/mroz_wage_educ_scatter.pdf", replace
graph export "explorations/mroz_tutorial/output/figures/mroz_wage_educ_scatter.png", replace width(1600)
graph drop _all

*------------------------------------------------------------------------------
* 第 10 步：结束
*------------------------------------------------------------------------------
display "============================================================"
display "Analysis complete. Main outputs:"
display "Tables: explorations/mroz_tutorial/output/tables/"
display "Figures: explorations/mroz_tutorial/output/figures/"
display "Log: logs/mroz_tutorial_01_mroz_analysis.log"
display "============================================================"

log close
