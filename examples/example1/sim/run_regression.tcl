#==============================================================================
# run_regression.tcl - Full regression for example1 (AXI Data Transform)
# Location: example1/sim/run_regression.tcl
#
# Usage (Vivado Tcl console):
#   cd c:/evm/evm-sv/examples/example1/sim
#   source run_regression.tcl
#
# Author: Eric Dyer (Differential Audio Inc.)
#==============================================================================

source [file join [file dirname [info script]] "run_sim.tcl"]

set TESTS {basic_write_test  multi_xform_test  random_test}

puts ""
puts "============================================================"
puts "  EVM Example 1 Regression: axi_data_xform"
puts "  Tests: [llength $TESTS]"
puts "============================================================"

set pass_count 0
set fail_count 0
set results    {}

foreach test $TESTS {
    puts "\n--- $test ---"
    
    if {[catch {launch_simulation -simset sim_1 -mode behavioral -noclean_dir} err]} {
        puts "COMPILE ERROR: $err"
        lappend results [list $test COMPILE_ERROR]
        incr fail_count
        continue
    }
    
    restart
    
    if {[catch {run -all} run_err]} {
        puts "RUN ERROR: $run_err"
        lappend results [list $test FAIL]
        incr fail_count
    } else {
        lappend results [list $test PASS]
        incr pass_count
    }
    
    close_sim -force
}

puts ""
puts "============================================================"
puts "  REGRESSION SUMMARY"
puts "============================================================"
foreach r $results {
    set n [lindex $r 0]
    set s [lindex $r 1]
    puts "  \[[expr {$s eq {PASS} ? {PASS} : {FAIL}}]\] $n"
}
puts ""
puts "  Passed: $pass_count / [llength $TESTS]"
puts "  Failed: $fail_count / [llength $TESTS]"
if {$fail_count == 0} { puts "\n  ALL TESTS PASSED" } else { puts "\n  REGRESSION FAILED" }
puts "============================================================"
