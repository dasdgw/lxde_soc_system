set sysid_base 0x10000
set rgbmatrix_base 0x2000
 set rgbmatrix_size 0x2000
#set rgbmatrix_size 0x800
set hps_peripherals_base 0xFF200000

# set rgbmatrix_cols 32
# set rgbmatrix_cols 64
set rgbmatrix_cols 128
set rgbmatrix_rows 16
#pixel width in byte
set pixel_width 4

puts [get_service_paths master]
set mypath [ lindex [ get_service_paths master ] 0 ]
    open_service master $mypath
puts "jtag master: $mypath"

puts [jtag_debug_sample_reset $mypath]
puts [jtag_debug_sample_clock $mypath]
puts [jtag_debug_sample_clock $mypath]
puts [master_read_32  $mypath $sysid_base 1]
puts [master_read_32  $mypath $rgbmatrix_base 1]
puts [master_write_32  $mypath $rgbmatrix_base 0x0000FFFF]
puts "commands: cls red set_color <0xXXXXXXXX> corners put_pixel <X> <Y> put_pixel_hps <X> <Y>"

for {set x 0} {$x<$rgbmatrix_size} {incr x $pixel_width} {
    set address [expr $rgbmatrix_base + $x ]
    master_write_32  $mypath $address 0x0000FFFF
}

proc cls {} {
    global mypath
    global rgbmatrix_base
    global rgbmatrix_size
    global pixel_width
    global hps_peripherals_base
    
    for {set x 0} {$x<$rgbmatrix_size} {incr x $pixel_width} {
	set address [expr $hps_peripherals_base + $rgbmatrix_base + $x ]
	master_write_32  $mypath $address 0x00000000
    }
}

proc red {} {
    global mypath
    global rgbmatrix_base
    global rgbmatrix_size
    global pixel_width

    for {set x 0} {$x<$rgbmatrix_size} {incr x $pixel_width} {
	set address [expr $rgbmatrix_base + $x ]
	master_write_32  $mypath $address 0x000000FF
    }
}

proc set_color {color} {
    global mypath
    global rgbmatrix_base
    global rgbmatrix_size
    global pixel_width

    for {set x 0} {$x<$rgbmatrix_size} {incr x $pixel_width} {
	set address [expr $rgbmatrix_base + $x ]
	master_write_32  $mypath $address $color
    }
}

proc corners {} {
    global mypath
    global rgbmatrix_base
    global rgbmatrix_size
    global rgbmatrix_cols
    global rgbmatrix_rows
    global pixel_width

    put_pixel_hps 0 0
    put_pixel_hps 0 7
    put_pixel_hps 0 8
    put_pixel_hps 0 15
    put_pixel_hps 31 0
    put_pixel_hps 31 7
    put_pixel_hps 31 8
    put_pixel_hps 31 15
}

proc corners64 {} {
    global mypath
    global rgbmatrix_base
    global rgbmatrix_size
    global rgbmatrix_cols
    global rgbmatrix_rows
    global pixel_width

    put_pixel_hps 32 0
    put_pixel_hps 32 7
    put_pixel_hps 32 8
    put_pixel_hps 32 15
    put_pixel_hps 63 0
    put_pixel_hps 63 7
    put_pixel_hps 63 8
    put_pixel_hps 63 15
}

proc corners128 {} {
    put_pixel_hps 64 0
    put_pixel_hps 64 7
    put_pixel_hps 64 8
    put_pixel_hps 64 15
    put_pixel_hps 95 0
    put_pixel_hps 95 7
    put_pixel_hps 95 8
    put_pixel_hps 95 15
    
    put_pixel_hps 96 0
    put_pixel_hps 96 7
    put_pixel_hps 96 8
    put_pixel_hps 96 15
    put_pixel_hps 127 0
    put_pixel_hps 127 7
    put_pixel_hps 127 8
    put_pixel_hps 127 15
}

proc put_pixel {x y} {
    global mypath
    global rgbmatrix_base
    global rgbmatrix_size
    global rgbmatrix_cols
    global pixel_width

#    set address_x $x
#    set address_y [expr {32*$y} ]
    set address [expr {$rgbmatrix_base + [expr { [expr { $x + [expr {$rgbmatrix_cols * $y} ]}] * $pixel_width}]} ]
    master_write_32  $mypath $address 0x00EF0000

}


proc put_pixel_hps {x y} {
    global mypath
    global rgbmatrix_base
    global rgbmatrix_size
    global rgbmatrix_cols
    global pixel_width
    global hps_peripherals_base

#    set address_x $x
#    set address_y [expr {32*$y} ]

    set address [expr {$hps_peripherals_base + $rgbmatrix_base + [expr { [expr { $x + [expr {$rgbmatrix_cols * $y} ]}] * $pixel_width}]} ]
#    set address [expr ($hps_peripherals_base + $rgbmatrix_base + (($x + ($rgbmatrix_cols * $y)) * $pixel_width))
    master_write_32  $mypath $address 0x00EF0000

}
