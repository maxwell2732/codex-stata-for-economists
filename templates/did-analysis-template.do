*------------------------------------------------------------------------------
* File:     dofiles/03_analysis/05_did.do
* Project:  [YOUR PROJECT NAME]
* Author:   [YOUR NAME]
* Purpose:  估计 DID 主规格、错位处理稳健规格和事件研究图。
* Inputs:   data/derived/analysis_sample.dta
* Outputs:  output/tables/did_twfe.csv
*           output/tables/did_twfe.tex
*           output/tables/did_csdid_simple.csv
*           output/figures/did_event_study.pdf
*           output/figures/did_event_study.png
* Log:      logs/03_analysis_05_did.log
*
* HOW TO USE:
*     1. Copy this file to dofiles/03_analysis/05_did.do.
*     2. Replace the variable names in Section 0.
*     3. Uncomment the call in dofiles/00_master.do after the data pipeline is ready.
*------------------------------------------------------------------------------

version 15
clear all
set more off
set varabbrev off

capture log close
capture mkdir "logs"
capture mkdir "output"
capture mkdir "output/tables"
capture mkdir "output/figures"

log using "logs/03_analysis_05_did.log", replace text
set seed 20260428

*--- 0. 项目配置 --------------------------------------------------------------
* 将这些占位变量名改成你的分析样本中的真实变量名。
local analysis_data "data/derived/analysis_sample.dta"
local outcome      outcome_var
local unit_id      unit_id
local time_var     year
local treated      treated
local first_treat  first_treat_year
local controls     "control1 control2"
local cluster_var  unit_id

* 事件研究窗口。根据数据长度和处理时间分布调整。
local lead_min = -5
local lag_max  = 5

*--- 1. 载入和核验分析样本 ----------------------------------------------------
use "`analysis_data'", clear

foreach var in `outcome' `unit_id' `time_var' `treated' `first_treat' ///
    `cluster_var' `controls' {
    capture confirm variable `var'
    if _rc {
        display as error "Missing required variable: `var'"
        exit 111
    }
}

isid `unit_id' `time_var', sort

display _n as text ">>> DID sample counts <<<"
tabulate `treated'
tabulate `first_treat' if `first_treat' < ., missing

*--- 2. TWFE 基准 DID ---------------------------------------------------------
* 标准误聚类在处理分配层级；如处理在更高层级分配，应改为更高层级变量。
reghdfe `outcome' `treated' `controls', ///
    absorb(`unit_id' `time_var') vce(cluster `cluster_var')
estimates store did_twfe

esttab did_twfe using "output/tables/did_twfe.csv", ///
    replace se r2 ar2 scalar(N) nomtitles label ///
    title("TWFE DID baseline")

esttab did_twfe using "output/tables/did_twfe.tex", ///
    replace se r2 ar2 scalar(N) nomtitles label ///
    title("TWFE DID baseline")

*--- 3. Callaway-Sant'Anna DID ------------------------------------------------
* 适用于错位处理时间和异质性处理效应；未处理组编码为 missing 或 0。
capture which csdid
if _rc {
    display as error "csdid is not installed; set INSTALL_DEPS = 1 in 00_master.do."
    exit 199
}

csdid `outcome' `controls', ///
    ivar(`unit_id') time(`time_var') gvar(`first_treat') ///
    method(dripw) notyet

estat simple
matrix did_simple = r(table)

preserve
clear
set obs 1
generate estimator = "Callaway-Santanna"
generate estimate = did_simple[1, 1]
generate se = did_simple[2, 1]
generate z = did_simple[3, 1]
generate p = did_simple[4, 1]
generate ci_low = did_simple[5, 1]
generate ci_high = did_simple[6, 1]
export delimited using "output/tables/did_csdid_simple.csv", replace
restore

*--- 4. 事件研究和预趋势 ------------------------------------------------------
estat event, window(`lead_min' `lag_max') estore(csdid_event)
estat pretrend, pre(`=abs(`lead_min')')

csdid_plot, name(did_event_study, replace)

graph export "output/figures/did_event_study.pdf", replace
graph export "output/figures/did_event_study.png", replace width(1600)

log close
