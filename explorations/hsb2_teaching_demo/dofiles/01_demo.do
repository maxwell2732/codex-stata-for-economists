*------------------------------------------------------------------------------
* File:     explorations/hsb2_teaching_demo/dofiles/01_demo.do
* Project:  HSB2 teaching demonstration
* Author:   [Instructor]
* Purpose:  Walk an undergraduate audience through a complete (but compact)
*           Stata workflow:
*             (1) load + describe data
*             (2) summary statistics — overall and by group
*             (3) a histogram of writing scores
*             (4) OLS regression: how do test scores in other subjects
*                 predict writing performance?
* Inputs:   data/raw/hsb2.dta   (UCLA "High School and Beyond" sample, 200 obs)
* Outputs:  explorations/hsb2_teaching_demo/output/figures/write_histogram.pdf
*           explorations/hsb2_teaching_demo/output/figures/write_histogram.png
*           explorations/hsb2_teaching_demo/output/tables/coef_table.csv
* Log:      explorations/hsb2_teaching_demo/logs/01_demo.log
*
* HOW TO RUN (from the project root):
*     bash scripts/run_stata.sh explorations/hsb2_teaching_demo/dofiles/01_demo.do
*
* Or, inside Stata interactively:
*     do explorations/hsb2_teaching_demo/dofiles/01_demo.do
*------------------------------------------------------------------------------

version 15                  // pinned to match Chen's installed Stata 15
clear all
set more off
set varabbrev off
capture log close
log using "explorations/hsb2_teaching_demo/logs/01_demo.log", replace text

set seed 20260428           // reproducibility (no randomness used here, but
                            //   it's a habit worth teaching)

* Make sure output folders exist (idempotent; safe to re-run).
capture mkdir "explorations/hsb2_teaching_demo/output"
capture mkdir "explorations/hsb2_teaching_demo/output/figures"
capture mkdir "explorations/hsb2_teaching_demo/output/tables"


*--- 1. Load the data --------------------------------------------------------
* hsb2 is the UCLA "High School and Beyond" teaching dataset: 200 students
* with five test scores plus demographic / school-type variables.

use "data/raw/hsb2.dta", clear

display _n as text "*** Observations: " as result _N as text " ***"

* `describe` lists every variable, its storage type, and its label.
describe


*--- 2. Summary statistics ---------------------------------------------------

* 2a. Overall summary of every test score.
*     `summarize, detail` adds percentiles, skewness, and kurtosis — useful
*     for spotting outliers and checking near-normality before OLS.
display _n as text ">>> Summary of all test scores (with detail) <<<"
summarize read write math science socst, detail

* 2b. Categorical breakdowns. `tabulate` shows counts; the value labels make
*     the output read like a pivot table.
display _n as text ">>> Counts by sex / race / SES / school type / program <<<"
tabulate female
tabulate race
tabulate ses
tabulate schtyp
tabulate prog

* 2c. Conditional means. `tabstat` with `by()` is the cleanest way to show
*     "writing score by program" or similar comparisons.
display _n as text ">>> Mean writing score, by program type <<<"
tabstat write, by(prog) statistics(N mean sd min max) format(%9.2f)

display _n as text ">>> Mean test scores, by sex <<<"
tabstat read write math science socst, by(female) statistics(mean sd) format(%9.2f)


*--- 3. Histogram of writing scores ------------------------------------------
* `histogram` is the workhorse; we overlay a normal curve so students can see
* how close (or not) the distribution is to the normal assumption that OLS
* inference relies on.

histogram write, ///
    frequency ///
    normal ///
    title("Distribution of writing scores (HSB2, n=200)") ///
    subtitle("Overlay shows the matched-moments normal density") ///
    xtitle("Writing score") ///
    ytitle("Frequency") ///
    note("Source: UCLA High School and Beyond sample, 200 students.") ///
    scheme(s2color)

graph export "explorations/hsb2_teaching_demo/output/figures/write_histogram.pdf", replace
graph export "explorations/hsb2_teaching_demo/output/figures/write_histogram.png", replace width(1600)


*--- 4. OLS: how do other test scores predict writing? -----------------------
* Build up the model in three stages so students can see what each addition
* does to the coefficients and the model fit.
*
*   Spec 1: write = a + b1*read + e                  (simple bivariate)
*   Spec 2: + math + female                          (add controls)
*   Spec 3: + indicators for race and program        (add categoricals via i.)
*
* `i.varname` tells Stata to expand a categorical variable into a set of
* dummies, automatically dropping one level as the omitted reference category.

display _n as text ">>> Spec 1: simple bivariate regression <<<"
regress write read
estimates store m1

display _n as text ">>> Spec 2: add math score + female indicator <<<"
regress write read math i.female
estimates store m2

display _n as text ">>> Spec 3: add race and program (categorical) <<<"
regress write read math i.female i.race i.prog
estimates store m3

* Side-by-side coefficient table — built into Stata, no add-ons required.
display _n as text ">>> Coefficient comparison (Specs 1-3) <<<"
estimates table m1 m2 m3, ///
    b(%9.3f) se(%9.3f) ///
    stats(N r2 r2_a F) ///
    title("OLS: predicting writing score")

* Also write the same table to CSV for sharing / replication. The bare-bones
* approach (no `estout` package required) is to use `estimates restore` plus
* `outreg2` — but to keep the dependency footprint at zero we instead dump
* a compact CSV by hand from the saved estimates' coefficient vector.
preserve
    clear
    set obs 1
    foreach m in m1 m2 m3 {
        qui estimates restore `m'
        local n_`m'  = e(N)
        local r2_`m' = e(r2)
        local b_read_`m' = _b[read]
        local se_read_`m' = _se[read]
    }
    gen str20 spec  = ""
    gen      coef_read  = .
    gen      se_read    = .
    gen      r2         = .
    gen      n          = .
    set obs 3
    replace spec  = "m1: write ~ read"               in 1
    replace spec  = "m2: + math + female"            in 2
    replace spec  = "m3: + math + female + race+prog" in 3
    replace coef_read = `b_read_m1' in 1
    replace coef_read = `b_read_m2' in 2
    replace coef_read = `b_read_m3' in 3
    replace se_read   = `se_read_m1' in 1
    replace se_read   = `se_read_m2' in 2
    replace se_read   = `se_read_m3' in 3
    replace r2        = `r2_m1' in 1
    replace r2        = `r2_m2' in 2
    replace r2        = `r2_m3' in 3
    replace n         = `n_m1' in 1
    replace n         = `n_m2' in 2
    replace n         = `n_m3' in 3
    export delimited using "explorations/hsb2_teaching_demo/output/tables/coef_table.csv", replace
restore


*--- 5. Done -----------------------------------------------------------------

display _n as text "Pipeline finished. Inspect:"
display as text "  log:    explorations/hsb2_teaching_demo/logs/01_demo.log"
display as text "  figure: explorations/hsb2_teaching_demo/output/figures/write_histogram.pdf"
display as text "  table:  explorations/hsb2_teaching_demo/output/tables/coef_table.csv"

log close
