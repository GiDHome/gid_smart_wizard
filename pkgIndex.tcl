proc LoadLibrary_gid_smart_wizard { dir } {
    foreach item {gid_smart_wizard.tcl} {
        source [file join $dir $item]
    }
}

package ifneeded gid_smart_wizard 0.1 [list LoadLibrary_gid_smart_wizard $dir]