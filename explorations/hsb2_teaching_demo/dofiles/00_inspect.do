*------------------------------------------------------------------------------
* File:     explorations/hsb2_teaching_demo/dofiles/00_inspect.do
* Purpose:  Print structure of hsb2.dta so we know which variables to use
*           in the teaching demo. Throwaway script.
*------------------------------------------------------------------------------

version 15
clear all
set more off
set varabbrev off
capture log close
log using "explorations/hsb2_teaching_demo/logs/00_inspect.log", replace text

use "data/raw/hsb2.dta", clear

display _n "*** describe ***"
describe

display _n "*** codebook (compact) ***"
codebook, compact

display _n "*** sample first 5 obs ***"
list in 1/5

log close
