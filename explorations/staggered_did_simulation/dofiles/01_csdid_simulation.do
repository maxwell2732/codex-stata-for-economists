*------------------------------------------------------------------------------
* File:     explorations/staggered_did_simulation/dofiles/01_csdid_simulation.do
* Project:  Staggered DID simulation
* Author:   Codex
* Purpose:  构造错位处理时间的面板模拟数据，并用 csdid 测试现代 DID 工作流。
* Inputs:   None; simulated data
* Outputs:  explorations/staggered_did_simulation/output/tables/csdid_simple_att.csv
*           explorations/staggered_did_simulation/output/tables/csdid_event_att.csv
*           explorations/staggered_did_simulation/output/figures/csdid_event_study.pdf
*           explorations/staggered_did_simulation/output/figures/csdid_event_study.png
* Log:      explorations/staggered_did_simulation/logs/01_csdid_simulation.log
*
* HOW TO RUN (from project root):
*     scripts\run_stata.bat explorations\staggered_did_simulation\dofiles\01_csdid_simulation.do
*------------------------------------------------------------------------------

version 15
clear all
set more off
set varabbrev off

capture log close
capture mkdir "explorations/staggered_did_simulation/logs"
capture mkdir "explorations/staggered_did_simulation/output"
capture mkdir "explorations/staggered_did_simulation/output/tables"
capture mkdir "explorations/staggered_did_simulation/output/figures"

log using "explorations/staggered_did_simulation/logs/01_csdid_simulation.log", ///
    replace text

set seed 20260507

*--- 1. 依赖检查 --------------------------------------------------------------
foreach cmd in csdid reghdfe esttab {
    capture which `cmd'
    if _rc {
        display as error "`cmd' is required for this simulation."
        exit 199
    }
}

*--- 2. 构造错位处理时间的模拟面板 --------------------------------------------
local n_units = 600
local first_year = 2000
local last_year = 2009
local n_years = `last_year' - `first_year' + 1

set obs `n_units'
generate unit_id = _n
generate double unit_fe = rnormal(0, 1)
generate double x = rnormal(0, 1)
generate double u = runiform()
generate first_treat = .
replace first_treat = 2004 if u < 0.25
replace first_treat = 2006 if u >= 0.25 & u < 0.50
replace first_treat = 2008 if u >= 0.50 & u < 0.75

expand `n_years'
bysort unit_id: generate year = `first_year' + _n - 1
generate rel_time = year - first_treat if first_treat < .
generate treated = (first_treat < . & year >= first_treat)
generate double time_fe = 0.12 * (year - `first_year')

* 处理效应允许随相对处理时间增强，制造 TWFE 可能不稳健的异质动态效应。
generate double true_te = 0
replace true_te = 1 + 0.35 * rel_time if treated
replace true_te = 3.5 if true_te > 3.5 & treated

generate double eps = rnormal(0, 1)
generate double y = 2 + unit_fe + time_fe + 0.5 * x + true_te + eps

label variable y "Outcome"
label variable treated "Treated"
label variable first_treat "First treatment year"
label variable rel_time "Years relative to first treatment"

isid unit_id year, sort

display _n as text ">>> Treatment cohorts <<<"
tabulate first_treat, missing
display _n as text ">>> True average effect among treated observations <<<"
summarize true_te if treated

*--- 3. TWFE 基准作为对照 -----------------------------------------------------
reghdfe y treated x, absorb(unit_id year) vce(cluster unit_id)
estimates store twfe

esttab twfe using ///
    "explorations/staggered_did_simulation/output/tables/twfe_baseline.csv", ///
    replace se r2 scalar(N) nomtitles label title("TWFE baseline")

*--- 4. csdid 总体 ATT --------------------------------------------------------
csdid y x, ivar(unit_id) time(year) gvar(first_treat) ///
    method(reg) notyet

estat simple
matrix simple = r(table)

preserve
clear
set obs 1
generate estimator = "csdid_simple"
generate estimate = simple[1, 1]
generate se = simple[2, 1]
generate z = simple[3, 1]
generate p = simple[4, 1]
generate ci_low = simple[5, 1]
generate ci_high = simple[6, 1]
export delimited using ///
    "explorations/staggered_did_simulation/output/tables/csdid_simple_att.csv", ///
    replace
restore

*--- 5. csdid 事件研究 --------------------------------------------------------
estat event, window(-4 5)
matrix event = r(table)
local event_cols : colnames event
display _n as text ">>> Event-study columns from estat event <<<"
display "`event_cols'"

preserve
clear
local ncols = colsof(event)
set obs `ncols'
generate str32 term = ""
generate event_time = .
generate estimate = .
generate se = .
generate ci_low = .
generate ci_high = .

local j = 1
foreach col of local event_cols {
    replace term = "`col'" in `j'
    replace estimate = event[1, `j'] in `j'
    replace se = event[2, `j'] in `j'
    replace ci_low = event[5, `j'] in `j'
    replace ci_high = event[6, `j'] in `j'

    local rel = .
    if substr("`col'", 1, 2) == "Tm" {
        local rel = -real(substr("`col'", 3, .))
    }
    else if substr("`col'", 1, 2) == "Tp" {
        local rel = real(substr("`col'", 3, .))
    }
    replace event_time = `rel' in `j'
    local ++j
}

sort event_time
export delimited using ///
    "explorations/staggered_did_simulation/output/tables/csdid_event_att.csv", ///
    replace

twoway ///
    (rcap ci_low ci_high event_time, lcolor("100 116 139") lwidth(thin)) ///
    (connected estimate event_time, ///
        msymbol(circle) msize(small) mcolor("49 145 255") ///
        lcolor("49 145 255") lwidth(medthick)), ///
    xline(-1, lcolor("75 85 99") lpattern(dash)) ///
    yline(0, lcolor("75 85 99") lpattern(dash)) ///
    title("Simulated staggered DID event study", ///
        color("31 41 55") size(medsmall)) ///
    subtitle("csdid estimates with 95% confidence intervals", ///
        color("75 85 99") size(small)) ///
    xtitle("Years relative to treatment", size(small)) ///
    ytitle("ATT", size(small)) ///
    xlabel(-4(1)5, labsize(small) grid glcolor("229 231 235") glwidth(vthin)) ///
    ylabel(, labsize(small) angle(horizontal) grid glcolor("229 231 235") ///
        glwidth(vthin)) ///
    legend(off) ///
    graphregion(color(white)) ///
    plotregion(color(white) lcolor(white)) ///
    note("Source: simulated panel; cohorts treated in 2004, 2006, and 2008.", ///
        size(vsmall)) ///
    scheme(s2color)

graph export ///
    "explorations/staggered_did_simulation/output/figures/csdid_event_study.pdf", ///
    replace
graph export ///
    "explorations/staggered_did_simulation/output/figures/csdid_event_study.png", ///
    replace width(1600)

restore

log close
