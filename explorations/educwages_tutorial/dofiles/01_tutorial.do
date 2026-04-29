*------------------------------------------------------------------------------
* File:     explorations/educwages_tutorial/dofiles/01_tutorial.do
* Project:  educwages tutorial — returns to schooling for Stata beginners
* Author:   [Instructor]
* Purpose:  A complete, heavily-commented walk-through for someone new to
*           Stata. Teaches:
*             (1) loading + describing a dataset
*             (2) summary statistics
*             (3) a histogram of years of education
*             (4) a scatter plot of education vs wages with a linear fit
*             (5) an OLS regression of wages on education
*             (6) a 2SLS IV regression using father's education as the
*                 instrument for own education
*             (7) an OLS-vs-IV comparison table
*             (8) one-way and two-way ANOVA, plus the bridge that shows
*                 ANOVA = OLS with categorical predictors
* Inputs:   data/raw/educwages.dta  (1,000 obs)
* Outputs:  explorations/educwages_tutorial/output/figures/edu_histogram.pdf|.png
*           explorations/educwages_tutorial/output/figures/edu_wage_scatter.pdf|.png
*           explorations/educwages_tutorial/output/tables/summary_stats.csv
*           explorations/educwages_tutorial/output/tables/ols_vs_iv.csv
*           explorations/educwages_tutorial/output/tables/ols_vs_iv.rtf
* Log:      explorations/educwages_tutorial/logs/01_tutorial.log
*
* HOW TO RUN (from the project root):
*     bash scripts/run_stata.sh explorations/educwages_tutorial/dofiles/01_tutorial.do
*
* Or, inside Stata interactively:
*     do explorations/educwages_tutorial/dofiles/01_tutorial.do
*------------------------------------------------------------------------------

* Stata is picky about three things at the top of every do-file. We do them
* in order so the rest of the script behaves predictably:

version 15                  // pin Stata version (this machine has Stata 15)
clear all                   // wipe any data, programs, and stored estimates
                            //   from previous runs in the same session
set more off                // don't pause every screenful of output
set varabbrev off           // disallow variable-name abbreviation; if you mistype
                            //   `educaton` instead of `education`, Stata will
                            //   stop you instead of guessing what you meant.

capture log close           // close any log left open from a previous (failed) run
                            //   `capture` swallows the error if there's no open log.

* Make sure the output + log folders exist BEFORE we open the log
* (idempotent — `capture` ignores the error if the folder is already there).
capture mkdir "explorations/educwages_tutorial/logs"
capture mkdir "explorations/educwages_tutorial/output"
capture mkdir "explorations/educwages_tutorial/output/figures"
capture mkdir "explorations/educwages_tutorial/output/tables"

log using "explorations/educwages_tutorial/logs/01_tutorial.log", replace text
                            //   `replace` overwrites an existing log file;
                            //   `text` makes it plain-text (so you can grep it).

* No randomness in this script, but it's a habit worth keeping — set the seed
* once at the top, and only at the top, of any do-file that uses RNG.
set seed 20260429


*--- 1. Load the data --------------------------------------------------------
* `use` reads a Stata `.dta` file into memory. After this, the dataset
* exists in RAM until you `clear` it or load another one.

use "data/raw/educwages.dta", clear

* `_N` is a built-in scalar holding the number of observations currently
* in memory. We display it so the log shows the sample size up front.
display _n as text "*** Observations: " as result _N as text " ***"

* `describe` lists every variable, its storage type, and its label. Always
* run this on a new dataset before touching it — you want to know what
* you're working with.
describe


*--- 2. Summary statistics ---------------------------------------------------

* 2a. Overall summary of every numeric variable.
*     `summarize` reports N, mean, SD, min, max for each variable.
*     `, detail` adds percentiles (1st, 5th, 25th, 50th, 75th, 95th, 99th)
*     plus skewness and kurtosis — useful for spotting outliers.
display _n as text ">>> Summary of all variables (with detail) <<<"
summarize wages education meducation feducation, detail

* 2b. Categorical breakdown for `union`. `tabulate` shows counts and
*     percentages. The value labels (No / Yes) make the output read like a
*     pivot table.
display _n as text ">>> Union membership <<<"
tabulate union

* 2c. Conditional means: how does mean wage differ by union status?
*     `tabstat ... by()` is the cleanest one-liner for "X by group".
display _n as text ">>> Mean education and wages, by union status <<<"
tabstat education wages, by(union) statistics(N mean sd min max) format(%9.2f)

* 2d. Save the summary table to disk so it can be cited / shared without
*     re-running Stata. We use `estpost summarize` together with `esttab`,
*     a publication-quality companion to `summarize`. The CSV is opened by
*     Excel, R, or any text editor.
estpost summarize wages education meducation feducation
esttab using "explorations/educwages_tutorial/output/tables/summary_stats.csv", ///
    replace ///
    cells("count(fmt(0)) mean(fmt(2)) sd(fmt(2)) min(fmt(2)) max(fmt(2))") ///
    nonumber nomtitle nonote ///
    label ///
    title("Summary statistics — educwages.dta")


*--- 3. Histogram of education years -----------------------------------------
* `histogram` is the workhorse for univariate distributions. Pedagogically
* useful options:
*   `frequency`     y-axis is counts (instead of density)
*   `width(1)`      one bin per year of education (since `education` is
*                   continuous but in year units, this gives a clean view)
*   `start(10)`     first bin starts at 10 years (the data minimum is 10.2)
*   `addlabels`     write the count above each bar
*   `xtitle/ytitle/title/note`  obvious cosmetic options
*   `scheme(s2color)`  Stata's modern color scheme

histogram education, ///
    frequency ///
    width(1) ///
    start(10) ///
    addlabels ///
    xtitle("Years of education") ///
    ytitle("Frequency") ///
    title("Distribution of education (educwages, n=1,000)") ///
    note("Source: data/raw/educwages.dta.") ///
    scheme(s2color)

* Always export to BOTH a vector format (PDF — for papers) AND a raster
* format (PNG — for slides / web). `replace` overwrites the file each run.
graph export "explorations/educwages_tutorial/output/figures/edu_histogram.pdf", replace
graph export "explorations/educwages_tutorial/output/figures/edu_histogram.png", replace width(1600)


*--- 4. Twoway scatter: education vs wages -----------------------------------
* `twoway` is Stata's general 2D plotting command. You combine "plot types"
* in parentheses; here we layer two:
*   (1) a `scatter` of (wages, education) — every dot is one worker
*   (2) an `lfit` (linear fit) — the OLS line of wages on education
*
* The result visually previews what the OLS regression in Section 5 will
* estimate. If the slope of the line looks positive, the OLS coefficient
* on education will be positive; if the cloud of points is wide around the
* line, the R² will be small.

twoway ///
    (scatter wages education, msymbol(oh) mcolor(navy%50)) ///
    (lfit    wages education, lcolor(maroon) lwidth(medthick)), ///
    xtitle("Years of education") ///
    ytitle("Annual wages (USD, thousands?)") ///
    title("Education vs wages, with OLS fit") ///
    subtitle("Each dot is one worker (n=1,000)") ///
    legend(order(1 "Worker" 2 "OLS linear fit") position(6) cols(2)) ///
    note("Source: data/raw/educwages.dta.") ///
    scheme(s2color)

graph export "explorations/educwages_tutorial/output/figures/edu_wage_scatter.pdf", ///
    replace
graph export "explorations/educwages_tutorial/output/figures/edu_wage_scatter.png", ///
    replace width(1600)


*--- 5. OLS regression: wages on education -----------------------------------
* The simplest "Mincer-style" regression:
*
*     wages_i = a + b * education_i + e_i
*
* `regress` (or just `reg`) estimates `a` and `b` by ordinary least squares
* and reports SEs, t-stats, p-values, and an R-squared.
*
* `vce(robust)` asks for heteroskedasticity-robust (Eicker–Huber–White)
* standard errors. With i.i.d. cross-sectional data we don't need clustered
* SEs (no panel structure here), but robust is a sensible default when the
* error variance might depend on `education`.

display _n as text ">>> OLS: wages on education (robust SE) <<<"
regress wages education, vce(robust)

* `estimates store` saves the result under a tag so we can build a
* comparison table later. Without this, each new `regress` overwrites the
* previous result.
estimates store m_ols

* Interpretation (the instructor will narrate this in class):
*   - The coefficient on `education` is the OLS estimate of the *average*
*     change in annual wages associated with one additional year of
*     schooling, holding nothing else constant.
*   - It is a `correlation` story, not necessarily a `causal` story:
*     unobserved ability, family background, etc., may drive both
*     education and wages, biasing the OLS estimate. That's why we run
*     IV next.


*--- 6. IV (2SLS) regression: instrument education with father's education ---
* The endogeneity worry: people with higher unobserved ability (or richer
* families, or more motivation, or any of a dozen other factors that also
* affect wages directly) tend to acquire more schooling. So the OLS slope
* mixes the *causal* return to schooling with the bias from these
* unobservables. If ability raises both education and wages, OLS will
* overstate the return.
*
* Instrumental variables (IV) tries to isolate variation in `education`
* that is *unrelated* to the unobservables, by using a third variable Z
* (the "instrument") that satisfies two conditions:
*   (R) RELEVANCE: Z is correlated with education (testable; we want the
*       first-stage F statistic to be large, conventionally > 10).
*   (E) EXCLUSION: Z affects wages ONLY through its effect on education
*       (NOT testable; you have to argue it from theory / context).
*
* Here we use father's years of education (`feducation`) as Z.
*   - Relevance is plausible: people with more-educated fathers tend to
*     get more schooling themselves. We'll verify with the first-stage F.
*   - Exclusion is *not* clean — father's education correlates with family
*     income, social networks, and parenting environment, all of which can
*     plausibly affect wages directly. So treat this as a teaching example
*     of HOW to run 2SLS, not as a credible causal estimate. (Real papers
*     rely on compulsory-schooling laws, distance to college, twin differences,
*     etc.)
*
* `ivregress 2sls` is the built-in 2SLS command:
*     ivregress 2sls  Y  (X = Z) [other_X], options
*  - `Y` is the outcome (here `wages`).
*  - `(X = Z)` says: X (here `education`) is endogenous and is to be
*    instrumented by Z (here `feducation`).
*  - `vce(robust)` for heteroskedasticity-robust SEs (consistent with OLS).
*  - `first` prints the first-stage regression (X on Z + other regressors).

display _n as text ">>> First stage (manual): education on feducation <<<"
* Pedagogically useful to show the first stage explicitly first.
regress education feducation, vce(robust)
* The F statistic on the excluded instrument (`feducation`) should be
* large. With one instrument it equals the squared t-statistic on
* `feducation`. A standard rule of thumb is F > 10 (Stock-Yogo); modern
* work often demands much larger (Lee, McCrary, Moreira & Porter 2022).

display _n as text ///
    ">>> 2SLS: wages = a + b*education + e, instrument = feducation <<<"
ivregress 2sls wages (education = feducation), vce(robust) first
estimates store m_iv

* Interpretation:
*   - Under (R) and (E), the IV (2SLS) slope on `education` recovers the
*     *causal* return to schooling for the subgroup of workers whose
*     education is shifted by their father's education (a "Local Average
*     Treatment Effect" if effects are heterogeneous).
*   - Compare to OLS:
*       * If IV is *smaller* than OLS, ability bias was likely upward
*         (smart kids both got more schooling and earn more).
*       * If IV is *larger* than OLS, measurement error in education or a
*         compliers-vs-population effect may dominate.
*       * Big SE on IV is normal — IV throws away variation, so it's less
*         precise than OLS by construction.


*--- 7. Side-by-side OLS vs IV comparison table -----------------------------
* `esttab` (from the SSC `estout` package) makes a publication-style table
* from any number of stored estimates.
*   `b(%9.3f)`           coefficients to 3 decimal places
*   `se(%9.3f)`          standard errors in parentheses
*   `star(* 0.10 ...)`   significance stars at 10% / 5% / 1%
*   `stats(N r2)`        report N and R-squared at the bottom
*   `mtitles(...)`       column headers
*   `nonotes`            suppress automatic footnote

display _n as text ">>> Coefficient comparison: OLS vs IV <<<"
esttab m_ols m_iv, ///
    b(%9.3f) se(%9.3f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N r2, fmt(%9.0f %9.3f) labels("Observations" "R-squared")) ///
    mtitles("OLS" "IV (2SLS)") ///
    title("Returns to schooling: OLS vs IV (father's edu as instrument)") ///
    nonotes

* And the same table, exported to disk.
* CSV is for spreadsheets; RTF is for Word.
esttab m_ols m_iv using ///
    "explorations/educwages_tutorial/output/tables/ols_vs_iv.csv", ///
    replace ///
    b(%9.3f) se(%9.3f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N r2, fmt(%9.0f %9.3f) labels("Observations" "R-squared")) ///
    mtitles("OLS" "IV (2SLS)") ///
    title("Returns to schooling: OLS vs IV") ///
    plain

esttab m_ols m_iv using ///
    "explorations/educwages_tutorial/output/tables/ols_vs_iv.rtf", ///
    replace ///
    b(%9.3f) se(%9.3f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N r2, fmt(%9.0f %9.3f) labels("Observations" "R-squared")) ///
    mtitles("OLS" "IV (2SLS)") ///
    title("Returns to schooling: OLS vs IV") ///
    label


*--- 8. ANOVA: do mean wages differ across groups? ---------------------------
* ANOVA ("analysis of variance") generalizes the two-sample t-test to
* >= 2 groups. The null hypothesis is:
*     H0: mu_1 = mu_2 = ... = mu_k     (all group means are equal)
* against the alternative that at least one group mean differs. The F
* statistic compares between-group variation to within-group variation.
*
* For ANOVA we need at least one *categorical* predictor. `education` is
* continuous (years), so we first bin it into three tiers:
*   - Low      : <13 years   (less than some college)
*   - Mid      : 13-16 years (some college through bachelor's)
*   - High     : >16 years   (graduate study)
*
* `generate byte` creates a small-integer variable (1 byte each — saves
* memory). We initialize it to missing (.) and then fill in each tier.
* `label define` + `label values` attaches readable labels so the output
* prints "Low (<13)" instead of "1".

generate byte edu_cat = .
replace  edu_cat = 1 if education <  13
replace  edu_cat = 2 if education >= 13 & education <= 16
replace  edu_cat = 3 if education >  16
label define edu_cat_lbl 1 "Low (<13)" 2 "Mid (13-16)" 3 "High (>16)"
label values edu_cat edu_cat_lbl
label variable edu_cat "Education tier"

* Group means: a quick visual of what ANOVA will test. If the means look
* very different across rows, we expect ANOVA to reject H0; if they look
* similar, ANOVA will fail to reject.
display _n as text ">>> Wage means by education tier <<<"
tabstat wages, by(edu_cat) statistics(N mean sd) format(%9.2f)

* 8a. One-way ANOVA: wages explained by edu_cat alone.
* `anova` syntax:
*     anova OUTCOME factor1 [factor2 ...] [, options]
* Variables on the right are treated as CATEGORICAL by default.
display _n as text ">>> One-way ANOVA: wages by edu_cat <<<"
anova wages edu_cat

* Reading the output:
*   - "Model" row: between-group SS, df, F, p-value.
*     With one factor, the Model row equals the factor's row.
*   - "Residual" row: within-group SS, df.
*   - p < 0.05 means at least one group mean differs from the others.
*   - "Root MSE" is the residual SD; "R-squared" is between/total SS.

* 8b. Two-way ANOVA: add union as a second categorical predictor. This
*     tests whether wages vary by edu_cat *and* by union *separately*.
display _n as text ">>> Two-way ANOVA: wages by edu_cat + union (main effects) <<<"
anova wages edu_cat union

* 8c. Two-way ANOVA WITH interaction. `##` is Stata's "factorial"
*     operator: `A##B` expands to `A + B + A#B` (main effects + interaction).
*     A significant interaction means the wage gap between union and non-
*     union workers differs across education tiers.
display _n as text ">>> Two-way ANOVA with interaction (edu_cat##union) <<<"
anova wages edu_cat##union

* 8d. Bridge: ANOVA is *exactly* equivalent to OLS regression with the
*     same variables coded as categorical (`i.varname`). The model F
*     statistic and R-squared from `anova wages edu_cat` will match those
*     from `regress wages i.edu_cat`. ANOVA's column "Partial SS / df"
*     for each factor maps to the regression's joint test of that factor's
*     dummies (you can reproduce it with `testparm i.edu_cat`).
*
*     Why students should know this: in modern empirical economics,
*     researchers almost always use `regress` (or `reghdfe`) instead of
*     `anova` because regression generalizes naturally to mixing
*     categorical and continuous predictors. ANOVA is a special case.
display _n as text ">>> Bridge: regress wages i.edu_cat (same F, R-sq as 8a) <<<"
regress wages i.edu_cat


*--- 9. Done -----------------------------------------------------------------

display _n as text "Tutorial finished. Inspect:"
display as text "  log:     explorations/educwages_tutorial/logs/01_tutorial.log"
display as text "  figures: explorations/educwages_tutorial/output/figures/"
display as text "  tables:  explorations/educwages_tutorial/output/tables/"

log close
