*------------------------------------------------------------------------------
* File:     dofiles/03_analysis/06_ddml.do
* Project:  [YOUR PROJECT NAME]
* Author:   [YOUR NAME]
* Purpose:  使用 Double/Debiased Machine Learning 估计处理变量的部分线性模型。
* Inputs:   data/derived/analysis_sample.dta
* Outputs:  output/tables/ddml_partial_linear.csv
*           output/tables/ddml_partial_linear.tex
* Log:      logs/03_analysis_06_ddml.log
*
* HOW TO USE:
*     1. Copy this file to dofiles/03_analysis/06_ddml.do.
*     2. Replace the variable lists in Section 0.
*     3. Stata 15 users can run the rlasso learners from lassopack.
*     4. Stata 16+ users may optionally switch to pystacked learners.
*------------------------------------------------------------------------------

version 15
clear all
set more off
set varabbrev off

capture log close
capture mkdir "logs"
capture mkdir "output"
capture mkdir "output/tables"

log using "logs/03_analysis_06_ddml.log", replace text
set seed 20260428

*--- 0. 项目配置 --------------------------------------------------------------
* DDML 部分线性模型：Y = theta * D + g(X) + u。
local analysis_data "data/derived/analysis_sample.dta"
local outcome      outcome_var
local treatment    treatment_var
local controls     "control1 control2 control3"
local cluster_var  unit_id

* 交叉拟合折数和重复次数。最终结果建议用多个 reps 检查随机折分敏感性。
local kfolds = 5
local reps   = 3

*--- 1. 依赖检查 --------------------------------------------------------------
foreach cmd in ddml rlasso lasso2 cvlasso {
    capture which `cmd'
    if _rc {
        display as error "`cmd' is not installed; set INSTALL_DEPS = 1 in 00_master.do."
        exit 199
    }
}

* pystacked 需要 Stata 16+、Python 3 和 scikit-learn；本模板默认不用它。
capture which pystacked
if _rc {
    display as text "pystacked not available; using rlasso learners from lassopack."
}

*--- 2. 载入和核验分析样本 ----------------------------------------------------
use "`analysis_data'", clear

foreach var in `outcome' `treatment' `controls' `cluster_var' {
    capture confirm variable `var'
    if _rc {
        display as error "Missing required variable: `var'"
        exit 111
    }
}

drop if missing(`outcome', `treatment', `controls', `cluster_var')
display _n as text ">>> DDML analysis sample N: " as result _N

global Y `outcome'
global D `treatment'
global X `controls'

*--- 3. DDML 部分线性模型 -----------------------------------------------------
ddml init partial, kfolds(`kfolds') reps(`reps') ///
    fcluster(`cluster_var') mname(m_ddml)

* Stata 15 友好的默认学习器：rlasso。
ddml E[Y|X], mname(m_ddml): rlasso $Y $X
ddml E[D|X], mname(m_ddml): rlasso $D $X

* Stata 16+ 且 Python/scikit-learn 可用时，可替换为 pystacked，例如：
* ddml E[Y|X], mname(m_ddml): pystacked $Y $X, type(reg) ///
*     method(ols lassocv ridgecv)
* ddml E[D|X], mname(m_ddml): pystacked $D $X, type(reg) ///
*     method(ols lassocv ridgecv)

ddml crossfit, mname(m_ddml)
ddml estimate, mname(m_ddml) robust cluster(`cluster_var')
estimates store ddml_partial_linear

esttab ddml_partial_linear using "output/tables/ddml_partial_linear.csv", ///
    replace se scalar(N) nomtitles label ///
    title("DDML partial linear model")

esttab ddml_partial_linear using "output/tables/ddml_partial_linear.tex", ///
    replace se scalar(N) nomtitles label ///
    title("DDML partial linear model")

log close
