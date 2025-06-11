for {set i 0} {$i < 1024} {incr i 1} { mwr [expr 0x80000000+$i*4] $i }

