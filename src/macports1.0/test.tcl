# Global vars
set arguments ""
set test_name ""
set color_out ""
set tcl ""
set err ""

# Get tclsh path.
set autoconf ../../Mk/macports.autoconf.mk
set fp [open $autoconf r]
while {[gets $fp line] != -1} {
    if {[string match "TCLSH*" $line] != 0} {
        set tcl [lrange [split $line " "] 1 1]
    }
}

proc print_help {arg} {
    if { $arg == "tests" } {
        puts "The list of available tests is:"
	cd tests
	set test_suite [glob *.test]
        foreach test $test_suite {
            puts [puts -nonewline "  "]$test
        }
    } else {
        puts "Usage: tclsh test.tcl \[-debug level\] \[-t test\] \[-l\]\n"
        puts "  -debug LVL : sets the level of printed debug info \[0-3\]"
        puts "  -t TEST    : run a specific test"
        puts "  -nocolor   : disable color output (for automatic testing)"
        puts "  -l         : print the list of available tests"
        puts "  -h, -help  : print this message\n"
    }
}

# Process args
foreach arg $argv {
    if { $arg == "-h" || $arg == "-help" } {
        print_help ""
        exit 0
    } elseif { $arg == "-debug" } {
        set index [expr [lsearch $argv $arg] + 1]
        set level [lindex $argv $index]
        if { $level >= 0 && $level <= 3 } {
            append arguments "-debug " $level
        } else {
            puts "Invalid debug level."
            exit 1
        }
    } elseif { $arg == "-t" } {
        set index [expr [lsearch $argv $arg] + 1]
        set test_name [lindex $argv $index]
        set no 0
	cd tests
	set test_suite [glob *.test]
        foreach test $test_suite {
            if { $test_name != $test } {
                set no [expr $no + 1]
            }
        }
        if { $no == [llength $test_suite] } {
            print_help tests
            exit 1
        }
    } elseif { $arg == "-l" } {
        print_help tests
        exit 0
    } elseif { $arg == "-nocolor" } {
        set color_out "no"
    }
}


# Run tests
if { $test_name != ""} {
    set result [eval exec $tcl $test_name $arguments]
    puts $result

} else {
    cd tests
    set test_suite [glob *.test]

    foreach test $test_suite {
        set result [eval exec $tcl $test $arguments]
        set total [lrange [split $result "\t"] 2 2]
        set pass [lrange [split $result "\t"] 4 4]
        set skip [lrange [split $result "\t"] 6 6]
        set fail [lrange [split $result "\t\n"] 8 8]
        set errmsg [lrange [split $result "\n"] 2 2]

	# Format output
	if {$total < 10} { set total "0${total}"}
	if {$pass < 10} { set pass "0${pass}"}
	if {$skip < 10} { set skip "0${skip}"}
	if {$fail < 10} { set fail "0${fail}"}

        # Check for errors.
        if { $fail != 0 || $skip != 0 } {
            set err "yes"
        }

        set out ""
        if { ($fail != 0 || $skip != 0) && $color_out == "" } {
            # Color failed tests.
            append out "\x1b\[1;31mTotal:" $total " Passed:" $pass " Failed:" $fail " Skipped:" $skip "  \x1b\[0m" $test
        } else {
            append out "Total:" $total " Passed:" $pass " Failed:" $fail " Skipped:" $skip "  " $test
        }

        # Print results and constrints for auto-skipped tests.
        puts $out
        if { $skip != 0 } {
            set out "    Constraint: "
            append out [string trim $errmsg "\t {}"]
            puts $out
        }
    }
}

# Return 1 if errors were found.
if {$err != ""} {
    exit 1
}

return 0