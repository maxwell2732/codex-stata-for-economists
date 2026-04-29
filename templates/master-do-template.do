*------------------------------------------------------------------------------
* File:     dofiles/00_master.do
* Project:  [YOUR PROJECT NAME]
* Author:   [YOUR NAME]
* Purpose:  Pipeline orchestrator. Runs every stage of the analysis in
*           dependency order. This is the single canonical entry point for
*           reproducing the project end-to-end.
*
* Usage:    From project root:
*               bash scripts/run_pipeline.sh
*           or, equivalently:
*               bash scripts/run_stata.sh dofiles/00_master.do
*
* Inputs:   data/raw/**     (gitignored; provide your own)
* Outputs:  data/derived/**
*           output/tables/**, output/figures/**
*           logs/**
* Log:      logs/00_master.log + per-stage logs
*------------------------------------------------------------------------------

version 17                  // override per fork in CLAUDE.md
clear all
set more off
set varabbrev off
capture log close
log using "logs/00_master.log", replace text

set seed 20260428           // project-wide seed (date integer YYYYMMDD)

*--- 0. Configuration ---------------------------------------------------------

* Set to 1 the first time you clone the repo to install required user-written
* Stata commands. Set back to 0 for routine runs.
local INSTALL_DEPS = 0

* Set to 1 to run the EDA / exploratory stage. Off by default to keep the
* production pipeline fast and deterministic.
local RUN_EDA = 0

*--- 1. Environment snapshot --------------------------------------------------
* Record everything a reviewer needs to reproduce this run.

capture log close
log using "logs/00_master_environment.log", replace text

display "*** Environment snapshot ***"
display "Stata version:    " c(stata_version)
display "Stata flavor:     " c(flavor)
display "OS:               " c(os)
display "Username:         " c(username)
display "Date:             " c(current_date) " " c(current_time)
display "Working dir:      " c(pwd)

* User-written commands (paths confirm they're on the ado-path).
foreach cmd in reghdfe ftools estout esttab ivreg2 ranktest boottest {
    capture which `cmd'
    if _rc display "  MISSING: `cmd'  (run 'ssc install `cmd', replace')"
}

log close

*--- 2. Install dependencies (one-time) ---------------------------------------
if `INSTALL_DEPS' == 1 {
    log using "logs/00_master_install.log", replace text
    ssc install reghdfe, replace
    ssc install ftools, replace
    ssc install estout, replace
    ssc install ivreg2, replace
    ssc install ranktest, replace
    ssc install boottest, replace
    log close
}

*--- 3. Re-open master log ----------------------------------------------------
capture log close
log using "logs/00_master.log", append text

*--- 4. Stage 01: Clean -------------------------------------------------------
display ""
display "=========================================================="
display "  Stage 01: Clean raw data"
display "=========================================================="
local t0 = clock(c(current_time), "hms")

* Add per-do-file calls below as you build the pipeline. Each must be
* independently runnable (open its own log, use relative paths).
*
* Examples:
* do dofiles/01_clean/01_load_cps.do
* do dofiles/01_clean/02_clean_county_panel.do

local t1 = clock(c(current_time), "hms")
display "Stage 01 elapsed: " (`t1' - `t0') / 1000 " seconds"

*--- 5. Stage 02: Construct ---------------------------------------------------
display ""
display "=========================================================="
display "  Stage 02: Construct samples + variables"
display "=========================================================="
local t0 = clock(c(current_time), "hms")

* do dofiles/02_construct/01_build_sample.do
* do dofiles/02_construct/02_define_treatment.do

local t1 = clock(c(current_time), "hms")
display "Stage 02 elapsed: " (`t1' - `t0') / 1000 " seconds"

*--- 6. Stage 03: Analysis ----------------------------------------------------
display ""
display "=========================================================="
display "  Stage 03: Estimation"
display "=========================================================="
local t0 = clock(c(current_time), "hms")

* do dofiles/03_analysis/01_main_regression.do
* do dofiles/03_analysis/02_event_study.do
* do dofiles/03_analysis/03_iv_specification.do
* do dofiles/03_analysis/04_robustness.do

local t1 = clock(c(current_time), "hms")
display "Stage 03 elapsed: " (`t1' - `t0') / 1000 " seconds"

*--- 7. Stage 04: Output assembly ---------------------------------------------
display ""
display "=========================================================="
display "  Stage 04: Assemble tables + figures"
display "=========================================================="
local t0 = clock(c(current_time), "hms")

* do dofiles/04_output/01_main_tables.do
* do dofiles/04_output/02_main_figures.do

local t1 = clock(c(current_time), "hms")
display "Stage 04 elapsed: " (`t1' - `t0') / 1000 " seconds"

*--- 8. Optional EDA (off by default) -----------------------------------------
if `RUN_EDA' == 1 {
    display ""
    display "=========================================================="
    display "  Stage EDA: Exploratory data analysis"
    display "=========================================================="
    * do explorations/<name>/dofiles/eda.do
}

*--- 9. Done ------------------------------------------------------------------
display ""
display "=========================================================="
display "  Pipeline complete"
display "=========================================================="
display "Logs:    logs/"
display "Tables:  output/tables/"
display "Figures: output/figures/"
display "Next:    quarto render reports/analysis_report.qmd"

log close
