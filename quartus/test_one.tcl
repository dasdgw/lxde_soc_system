# TCL that reads from a pushbutton and writes to LEDS (via Avalon MM)
# First while loop writes to the LEDs where the LED pio is at address 0x180 (Qsys environment)
# This section  was only used for testing that the LEDS were writing correctly
# Second while loop reads and writes to the register of LEDS and thus the LEDs, depending on the pushbutton 
# The addresses after the $jtag_master need to match the base env in the Qsys 
# When using this code on other boards, what needs to be changed is
#	1) Base addresses of the LEDs
#	2) Base addresses of the PIOs
#	3) Verify that LEDS and PIOs are on the same master (eg in Qsys, the same memory master)
#	If this is not the case, the memory master needs to be changed
# The System Console test Message will show that the test is done, but the push buttons can be still pushed to change the LEDs
# as long as the board is not reprogrammed 

set sysid_base              0x10000
set sys_timestamp           0x10004
set led_base                0x10040
set hps_peripherals_base 0xFF200000

# Set the values to write to the LED pio.
#
set led_vals {0 1 2 4 8 16 32 64 128 64 32 16 8 4 2 5}
# 
set AvailableServices [get_service_types]

proc check_jtag {} {
    puts "\nscanning for devices ..."
    set jtag_debug_path [ lindex [get_service_paths jtag_debug] 0]
    if {$jtag_debug_path=={}} then {
	puts "no jtag device found! usb-blaster connected ? board powered ?"
    } else {
	puts "jtag found: $jtag_debug_path"
	open_service jtag_debug $jtag_debug_path
	puts "verifying jtag chain."
	set tdi [list 0x01 0x02 0x03 0x04 0x05 0x06 0x07 0x08 0x09 0x0a]
	puts "test data in  (tdi):\n$tdi"
	puts "test data out (tdo):"
	set tdo [jtag_debug_loop $jtag_debug_path $tdi]
	puts "$tdo"
    }
}

check_jtag

proc check_masters {} {
    set master_paths [get_service_paths master]

    # exit if no jtag masters are found
    if {$master_paths=={}} then {
	puts "no masters found! did you run 'make program' ?"
	puts "exiting ..."
	after 1000
	return -1
    } else {
	puts "masters found: $master_paths"
    }
}

set ret [check_masters]
#puts "$ret"

if {$ret!=-1} {
    # load design
    set work [pwd]
    puts ""
    puts "working dir: $work"
    puts "loading design ..."
    design_load $work
    puts "done"
     
    #opens the service master (needed for system console)
    set master_path [lindex [get_service_paths master] 0]
    puts "selected master: $master_path"
    open_service master $master_path
     
    puts ""
    set sys_id [master_read_32 $master_path $sysid_base 1]
    set sys_ts [master_read_32 $master_path $sys_timestamp 1]
#    set sys_ts_test [expr $sys_ts - 0x9306A1BB]
#    puts [format "%x"  $sys_ts_test]
#    puts [clock format $sys_ts_test]
    set sys_ts_human_readable [clock format $sys_ts]
    puts "sys_id:        $sys_id"
    puts "sys_ts_raw:    $sys_ts"
    puts "sys_ts_human:  $sys_ts_human_readable"
    puts ""

    puts "start test ..."
     
    proc led_loop {} {
        global master_path
        global led_base
        global led_vals
     
    #sets up loop value
    set loopcount 0x00
     
    #writes to LEDs going through the above values
    #used for testing, and thus the loopcount is very low
    #LED base address is 0x0001_0040 in Qsys, and thus set to 0x1_0040 in code
     
    while {$loopcount < 100} {
	foreach val $led_vals {
     	master_write_8 $master_path $led_base $val
     	#send_message info $loopcount 
     	incr loopcount
     	after 100
     	}
       }
    }
    led_loop;
    #sets up variables
     
    set lastSwitch 0x00
    set CurSwitch 0x00
    #note variable of loopcount1 (not variable of loopcount from above)
    set loopcount1 0x00
     
    #loop to read
    #reads from PIO (base address in Qsys is 0x1_00c0), and writes to LED (base address in Qsys is 0x1_0040)
     
     
    while {$loopcount1 < 100} {
     
     	# set the value to read from PIO starting from the base address and going up by 2 bytes
     
     	set CurSwitchs  [master_read_8 $master_path 0x100c0 0x2]  
     	send_message info $CurSwitchs
     
     	# set the setting of CurSwitch to be the first value in the index (eg 0 in the lindex) 
     	set CurSwitch [lindex $CurSwitchs 0 ]	

	
     	#compare the CurSwitch to be value (lastSwitch) and depending on the result
     	#write either value
     
     	if { $lastSwitch == $CurSwitch} {
     		# master_write_8 $master_path 0x1_0040 7
     		 master_write_8 $master_path $led_base $CurSwitch  
     		# 7 in binary is 0111
     		# send_message info "write the value of 7 (in binary)"
     		# send_message info "=CurSwitch" 
     		# send_message info $CurSwitch  		
     			
     	}
     	if { $lastSwitch != $CurSwitch} {
     		# master_write_8 $master_path 0x1_0040 8
     		 master_write_8 $master_path $led_base $CurSwitch  
     		# send_message info "write the value of 1 (in binary) "	
     		# send_message info "lastSwitch" 
     		# send_message info $lastSwitch  
     		 send_message info "CurSwitch" 
     		 send_message info $CurSwitch  		
     	}
     
     	set lastSwitch $CurSwitch 
     	incr loopcount1
      	 
    }
     
    #read the 2 byte at 0x1_00c0
     
    master_read_memory $master_path 0x100c0 2
     
    #print out a message that the test is done
    send_message info "System Console test done"
     
    #closes service master (needed for system console)
     
    #close_service master $master_path
    puts "test done."
    puts "execute led_loop to repeate led test"
}
#close_service
