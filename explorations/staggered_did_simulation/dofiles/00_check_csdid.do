version 15
clear all
set more off
set varabbrev off

capture log close
capture mkdir "explorations/staggered_did_simulation/logs"
log using "explorations/staggered_did_simulation/logs/00_check_csdid.log", ///
    replace text

foreach cmd in csdid drdid event_plot reghdfe ftools esttab {
    display ">>> which `cmd'"
    capture which `cmd'
    if _rc {
        display as error "MISSING: `cmd'"
    }
}

log close
