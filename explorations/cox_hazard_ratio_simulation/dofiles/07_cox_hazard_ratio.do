*------------------------------------------------------------------------------
* File:     explorations/cox_hazard_ratio_simulation/dofiles/07_cox_hazard_ratio.do
* Project:  Cox hazard ratio simulation exploration
* Author:   Codex
* Purpose:  Demonstrate Cox proportional hazards analysis with simulated data.
*
* Usage:    From project root:
*               scripts\run_stata.bat ///
*                   explorations\cox_hazard_ratio_simulation\dofiles\07_cox_hazard_ratio.do
*
* Inputs:   none; this do-file generates a small reproducible simulation sample
* Outputs:  explorations/cox_hazard_ratio_simulation/output/tables/
*           explorations/cox_hazard_ratio_simulation/output/figures/
* Log:      explorations/cox_hazard_ratio_simulation/logs/07_cox_hazard_ratio.log
*------------------------------------------------------------------------------

version 15
clear all
set more off
set varabbrev off
capture log close

local project_dir "explorations/cox_hazard_ratio_simulation"
local table_csv "`project_dir'/output/tables/cox_hazard_ratio_simulation.csv"
local table_tex "`project_dir'/output/tables/cox_hazard_ratio_simulation.tex"
local figure_pdf "`project_dir'/output/figures/cox_survival_curve_simulation.pdf"
local figure_png "`project_dir'/output/figures/cox_survival_curve_simulation.png"
local log_file "`project_dir'/logs/07_cox_hazard_ratio.log"

log using "`log_file'", replace text

set seed 20260428

*--- 0. Output folders ---------------------------------------------------------
capture mkdir "`project_dir'"
capture mkdir "`project_dir'/logs"
capture mkdir "`project_dir'/output"
capture mkdir "`project_dir'/output/tables"
capture mkdir "`project_dir'/output/figures"

*--- 1. Simulate a reproducible survival sample --------------------------------
local n = 600
set obs `n'

generate id = _n
generate treatment = runiform() < 0.5
generate female = runiform() < 0.5
generate age = round(rnormal(50, 10))
replace age = max(age, 25)
replace age = min(age, 80)

generate xb = -0.45 * treatment + 0.025 * (age - 50) - 0.15 * female
generate event_time = -ln(runiform()) / (0.08 * exp(xb))
generate censor_time = runiform() * 20
generate observed_time = min(event_time, censor_time)
generate event = event_time <= censor_time

label variable treatment "Treatment"
label variable female "Female"
label variable age "Age"
label variable observed_time "Observed time"
label variable event "Failure event"

*--- 2. Declare survival data --------------------------------------------------
stset observed_time, failure(event == 1) id(id)

*--- 3. Cox proportional hazards model ----------------------------------------
stcox treatment age female, vce(robust) hr
estimates store cox_simulation

*--- 4. Export hazard-ratio results -------------------------------------------
tempname table
file open `table' using "`table_csv'", write replace text
file write `table' ///
    "variable,hazard_ratio,log_hr_robust_se,z,p_value,ci_lower,ci_upper,N,failures" _n

foreach var in treatment age female {
    local b = _b[`var']
    local se = _se[`var']
    local z = `b' / `se'
    local p = 2 * normal(-abs(`z'))
    local hr = exp(`b')
    local ll = exp(`b' - invnormal(0.975) * `se')
    local ul = exp(`b' + invnormal(0.975) * `se')
    file write `table' "`var'," ///
        %9.4f (`hr') "," ///
        %9.4f (`se') "," ///
        %9.3f (`z') "," ///
        %9.4f (`p') "," ///
        %9.4f (`ll') "," ///
        %9.4f (`ul') "," ///
        %9.0f (e(N)) "," ///
        %9.0f (e(N_fail)) _n
}
file close `table'

tempname tex
file open `tex' using "`table_tex'", write replace text
file write `tex' "\begin{tabular}{lrrrrrr}" _n
file write `tex' "\hline" _n
file write `tex' ///
    "Variable & HR & Log-HR robust SE & z & p-value & 95\% CI low & 95\% CI high \\" _n
file write `tex' "\hline" _n

foreach var in treatment age female {
    local b = _b[`var']
    local se = _se[`var']
    local z = `b' / `se'
    local p = 2 * normal(-abs(`z'))
    local hr = exp(`b')
    local ll = exp(`b' - invnormal(0.975) * `se')
    local ul = exp(`b' + invnormal(0.975) * `se')
    file write `tex' "`var' & " ///
        %9.4f (`hr') " & " ///
        %9.4f (`se') " & " ///
        %9.3f (`z') " & " ///
        %9.4f (`p') " & " ///
        %9.4f (`ll') " & " ///
        %9.4f (`ul') " \\" _n
}
file write `tex' "\hline" _n
file write `tex' "\end{tabular}" _n
file close `tex'

*--- 5. Proportional-hazards diagnostic ---------------------------------------
capture noisily estat phtest, detail
if _rc {
    display as text "Note: estat phtest was not available for this specification."
}

*--- 6. Export survival curves -------------------------------------------------
sts graph, survival by(treatment) ///
    title("Survival curves by treatment", color("31 55 73") size(medsmall)) ///
    subtitle("Simulated sample", color("74 89 105") size(small)) ///
    xtitle("Analysis time", color("31 55 73") size(small)) ///
    ytitle("Survival probability", color("31 55 73") size(small)) ///
    legend(order(1 "Control" 2 "Treatment") rows(1) size(small) ///
        region(lcolor(white) fcolor(white))) ///
    plot1opts(lcolor("142 164 184") lpattern(dash) lwidth(medthin)) ///
    plot2opts(lcolor("49 145 255") lpattern(solid) lwidth(medthick)) ///
    graphregion(color(white) lcolor(white)) ///
    plotregion(color(white) lcolor(white)) ///
    ylabel(0(.2)1, angle(horizontal) labsize(small) labcolor("31 55 73") ///
        grid glcolor(gs14) glwidth(vthin)) ///
    xlabel(0(5)20, labsize(small) labcolor("31 55 73") nogrid) ///
    name(cox_survival_curve, replace)

graph export "`figure_pdf'", replace
graph export "`figure_png'", replace width(1800)

*--- 7. Done ------------------------------------------------------------------
display "Cox hazard ratio simulation complete."
display "Table CSV: `table_csv'"
display "Table TeX: `table_tex'"
display "Figure PDF: `figure_pdf'"
display "Figure PNG: `figure_png'"

log close
