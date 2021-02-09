
if { ![GidUtils::IsTkDisabled] } {
    package require gid_wizard
    package require wcb
}
package require tdom

package provide gid_smart_wizard 0.4

# Singleton wizard library
namespace eval smart_wizard {
    # Namespace variables declaration
    variable wizDoc
    variable wizardid
    variable wizwindow
    variable wiznamespace
    variable wprops
    variable stepidlist
    variable stepsframes
    variable images_dir
    variable wizard_title
    variable wizard_icon
}

# 1- CONFIGURATION

proc smart_wizard::Init { } {

    variable wizDoc
    set wizDoc ""
    
    variable wizardid
    set wizardid ""
    
    variable wizwindow
    set wizwindow ""
    
    variable wprops
    catch {unset wprops}
    set wprops(dummy) 0
    
    variable stepidlist
    set stepidlist [list ]

    variable wiznamespace
    set wiznamespace ""
    
    variable stepsframes
    set stepsframes [dict create ]

    variable images_dir
    set images_dir ""
    
    variable wizard_title
    set wizard_title "Wizard"

    variable wizard_icon
    set wizard_icon ""
}

# Load the file.wiz with the wizard structure
proc smart_wizard::LoadWizardDoc {doc_path} {
    variable wizDoc
    set wizDoc [dom parse [tDOM::xmlReadFile $doc_path] ]
    #W "Wizdoc\n[$wizDoc asXML]"
}

# Mandatory for callbacks
proc smart_wizard::SetWizardNamespace {ns} {
    variable wiznamespace

    if {[namespace exists $ns]} {
        set wiznamespace $ns
    } else {
        error [_ "Namespace $ns not available\nCheck smart_wizard::SetWizardNamespace"]
    }
}

# Set the window name
proc smart_wizard::SetWizardWindowName {ns} {
    variable wizwindow
    set wizwindow $ns
}

# Set the window images directory
proc smart_wizard::SetWizardImageDirectory {path} {
    variable images_dir
    set images_dir $path
}

# Load a wizard document
proc smart_wizard::ImportWizardData {} {
    variable wizDoc
    variable wprops
    variable stepidlist
    variable wizardid
    variable stepsframes
    
    # ABSTRACT: Import all wizard data variables from XML 
    set xmlData $wizDoc
    #W [$KPriv(xmlWiz) asXML]
    set wizardid [[$xmlData selectNodes "/Wizard"] getAttribute "wizardid"]
    smart_wizard::SetWizardTitle [[$xmlData selectNodes "/Wizard"] getAttribute "title"]
    smart_wizard::SetWizardIcon [[$xmlData selectNodes "/Wizard"] getAttribute "icon"]
    set path "/Wizard/Steps"
    set stepNodes [$xmlData selectNodes "$path/Step"]
    set dataNodes [$xmlData selectNodes "$path/Step/Data"]
    set stepNumber 0
    #W "Sn $stepNodes"
    foreach stepNode $stepNodes dataNode $dataNodes {
        set i 0
        incr stepNumber 
        set stepId [$stepNode getAttribute id ""]
        set stepTitle [$stepNode getAttribute title "Step $stepNumber: $stepId"]
        set stepSubtitle [$stepNode getAttribute subtitle ""]
        set wprops($stepId,title) $stepTitle
        set wprops($stepId,subtitle) $stepSubtitle
        lappend stepidlist $stepId
        dict set stepsframes $stepId [dict create]        
        foreach frameNode [$dataNode selectNodes "./Frame"] {
            set frame_n [$frameNode getAttribute n $i]
            set position [$frameNode getAttribute position "left"]
            set row_span [$frameNode getAttribute row_span 1]
            set title [$frameNode getAttribute title ""]
            dict set stepsframes $stepId $frame_n [dict create ]
            dict set stepsframes $stepId $frame_n title $title
            dict set stepsframes $stepId $frame_n position $position
            dict set stepsframes $stepId $frame_n row_span $row_span
            set items_list [list]
            foreach node [$frameNode childNodes] {
                # For nodes with no children
                if {([$node nodeName] eq "Item") && (![$node hasChildNodes])} {
                    set n [smart_wizard::_ProcessItemNode $stepId $node]
                    lappend items_list $n
                    set wprops($stepId,$n,order) $i
                    incr i                
                }
                if {([$node nodeName] eq "Table") && ([$node hasChildNodes])} {
                    foreach item [$node childNodes] {
                        if {([$item nodeName] eq "Item") && (![$item hasChildNodes])} {
                            set n [smart_wizard::_ProcessItemNode $stepId $item]
                            lappend items_list $n
                            set wprops($stepId,$n,order) $i
                            incr i                
                        }
                    }
                }
            }
            dict set stepsframes $stepId $frame_n items $items_list
        }
    }
    catch {array unset wprops(dummy)}
}

# 2- WINDOW MANAGEMENT

# Set the wizard window title
proc smart_wizard::SetWizardTitle {t} {
    variable wizard_title
    set wizard_title $t
}

# Set the wizard window icon
proc smart_wizard::SetWizardIcon {icon} {
    variable wizard_icon
    set wizard_icon $icon
}

# Set the size of the wizard window - Note that the window must exist
proc smart_wizard::SetWindowSize {x y} {
    variable wizwindow
    if { [GidUtils::IsTkDisabled] } {
        #e.g. batch mode without windows
        return 1
    }

    if {[winfo exists $wizwindow]} {
        wm minsize $wizwindow $x $y
        wm maxsize $wizwindow $x $y
    }
}

# Create the wizard window
proc smart_wizard::CreateWindow {} {
    variable wizwindow
    variable wprops
    variable stepidlist
    variable wizardid
    variable wiznamespace
    variable wizard_title
    variable images_dir
    variable wizard_icon
    variable wprops
    # W "Step list:\n\t$stepidlist"
    if { [GidUtils::IsTkDisabled] } {
        #e.g. batch mode without windows
        return 1
    }

    # Destroy the window 
    if {[winfo exists $wizwindow]} {
         destroy $wizwindow
    }
    
    # Create the window
    # If gid esto, else lo otro
    #InitWindow $wizwindow [= "Wizard"] PreSmartWizardWindowGeom
   
    toplevel $wizwindow
    # Set window title
    wm title $wizwindow $wizard_title

    # Set window icon
    if {$wizard_icon ne ""} {
        set im [image create photo -file [file join $images_dir $wizard_icon]]
        wm iconphoto $wizwindow $im
    }

    # Center window
    wm withdraw $wizwindow
    
    # Revisar si queda muy feo
    # set x [expr {([winfo screenwidth .gid.central.s]-[winfo width .gid.central.s])/2}]
    # set y [expr {([winfo screenheight .gid.central.s]-[winfo height .gid.central.s])/2}]
    # if { $x < 0 } { set x 0 }
    # if { $y < 0 } { set y 0 }
    # WmGidGeom $wizwindow +$x+$y
    update
    wm deiconify $wizwindow

    #wm attributes $wizwindow -topmost 1

    # Window size
    smart_wizard::SetWindowSize 700 500
    
    # First destroy all defined command (snit step data type)
    #foreach cmdid [info commands ::Wizard::*] {
    #     $cmdid destroy
    #}
    
    # Create all the steps
    set i 0
    set nssteplist [list ]
    foreach stepId $stepidlist {
        incr i
        catch {$stepId destroy}
        lappend nssteplist ::smart_wizard::${stepId}
        ::gid_wizard::wizardstep $stepId -title $wprops($stepId,title) -subtitle $wprops($stepId,subtitle) -layout basic -body "${wiznamespace}::$stepId \$win"
    }
    
    # Render the wizard
    # W "Processed step list:\n\t$nssteplist"
    ::gid_wizard::wizard $wizwindow.w -steps $nssteplist
         
    # Start the wizard
    $wizwindow.w start
    
    bind $wizwindow <<WizNext>> [list smart_wizard::NextEvent %d]
}

# Delete the wizard window
proc smart_wizard::DestroyWindow {} {
    variable wizwindow

    if { [GidUtils::IsTkDisabled] } {
        #e.g. batch mode without windows
        return 1
    }

    if {[info exists $wizwindow]} {
        if {[winfo exists $wizwindow]} {destroy $wizwindow}
    }
    return ""
}


# 3- DATA API

# Data access API - Set value of a property in a step
proc smart_wizard::SetProperty { stepid propid value } {
    set smart_wizard::wprops($stepid,$propid) $value
}

# Data access API - Get value of a property in a step
proc smart_wizard::GetProperty { stepid propid } {
    variable wprops
    set v ""
    catch {set v $wprops($stepid,$propid) }
    return $v
}

# Data access API - Get all the property of a step
proc smart_wizard::GetStepProperties { stepid } {
    variable wprops
    set lista [list ]
    foreach key [array names wprops] {
        if {[lindex [split $key ","] 0] eq $stepid} {if {[lindex [split $key ","] 1] ni $lista} {lappend lista [lindex [split $key ","] 1]}}
    }
    return $lista
}

# 4- STEP CONFIGURATION

# Automatic wizard - Auto generate the step
proc smart_wizard::AutoStep {win stepid} {
    variable stepsframes
    variable images_dir

    if { [GidUtils::IsTkDisabled] } {
        #e.g. batch mode without windows
        return 1
    }

    smart_wizard::SetWindowSize 650 500
    set entrywidth 10
    
    if {[winfo exists $win.left]} {destroy $win.left}
    if {[winfo exists $win.right]} {destroy $win.right}
    set left_frame [ttk::frame $win.left ]
    set right_frame [ttk::frame $win.right ]

    set properties [smart_wizard::GetStepProperties $stepid]
    #W $properties
    foreach frame [dict keys [dict get $stepsframes $stepid] ] {
        set frame_title [dict get $stepsframes $stepid $frame title]
        set position [dict get $stepsframes $stepid $frame position]
        set frame_id [string tolower $frame]
        set frame_path $left_frame
        if {$position eq "right"} {set frame_path $right_frame}
        if {$frame_title != ""} {
            set fr [ttk::labelframe $frame_path.$frame_id -text $frame_title ]
        } else {
            set fr [ttk::frame $frame_path.$frame_id -borderwidth 10]
        }
        foreach item [dict get $stepsframes $stepid $frame items] {
            set state [smart_wizard::GetProperty $stepid $item,state]
            if {$state eq "hidden"} {continue}
            set type [smart_wizard::GetProperty $stepid $item,type]
            set value [smart_wizard::GetProperty $stepid $item,value]
            set order [smart_wizard::GetProperty $stepid $item,order]
            set pn [smart_wizard::GetProperty $stepid $item,name]
            lappend listids $order
            set txt [= $pn]
            switch $type {
                integer - double {
                    set units [smart_wizard::GetProperty $stepid $item,units]
                    set lab$order [ttk::label $fr.l$order -text "${txt}:"]
                    set ent$order [ttk::entry $fr.e$order -textvariable ::smart_wizard::wprops($stepid,$item,value) -width $entrywidth]
                    if {$type eq "integer"} {
                        wcb::callback $fr.e$order before insert wcb::checkEntryForInt
                    } {
                        wcb::callback $fr.e$order before insert wcb::checkEntryForReal
                    }
                    if {$units ne ""} {
                        set un$order [ttk::label $fr.u$order -text $units]
                    }
                    set txt [= "Enter a value for $txt"]
                    tooltip::tooltip $fr.e$order "${txt}."
                    set lab "lab$order"
                    set ent "ent$order"
                    set uni ""
                    if {$units ne ""} {
                        set uni "un$order" 
                        grid [set $lab] [set $ent] [set $uni] -sticky ew
                    } {
                        grid [set $lab] [set $ent] -sticky ew
                    }
                }
                string {
                    set lab$order [ttk::label $fr.l$order -text "${txt}:"]
                    set ent$order [ttk::entry $fr.e$order -textvariable ::smart_wizard::wprops($stepid,$item,value) -width $entrywidth]
                    set txt [= "Enter a value for $txt"]
                    tooltip::tooltip $fr.e$order "${txt}."
                    set lab "lab$order"
                    set ent "ent$order"
                    set uni ""
                    grid [set $lab] [set $ent] -sticky ew
                    
                }
                combo {
                    set lab$order [ttk::label $fr.l$order -text "${txt}:"]
                    if {$value eq ""} {set ::smart_wizard::wprops($stepid,$item,value) [lindex $::smart_wizard::wprops($stepid,$item,values) 0]}
                    set ent$order [ttk::combobox $fr.e$order -values $::smart_wizard::wprops($stepid,$item,values) -textvariable ::smart_wizard::wprops($stepid,$item,value) -width $entrywidth -state readonly]
                    wcb::callback $fr.e$order before insert wcb::checkEntryForReal
                    if {$::smart_wizard::wprops($stepid,$item,onchange) ne ""} {
                        bind $fr.e$order <<ComboboxSelected>> [list $::smart_wizard::wprops($stepid,$item,onchange)]
                    }
                    set txt [= "Enter a value for $txt"]
                    tooltip::tooltip $fr.e$order "${txt}."
                    set lab "lab$order"
                    set ent "ent$order"
                    grid [set $lab] [set $ent] -sticky ew
                }
                button {
                    set but$order [ttk::button $fr.b$order -text $txt -command [list $value]]
                    set button "but$order"
                    grid [expr $$button] -columnspan 3 -sticky ew
                }
                label {
                    set lab$order [ttk::label $fr.l$order -textvariable ::smart_wizard::wprops($stepid,$item,value)]
                    set label "lab$order"
                    grid [expr $$label] -columnspan 3 -sticky ew
                }
                image {
                    set img_path [file join $images_dir $value]
                    set label [ttk::label $fr.i$order -image [gid_themes::GetImageModule $img_path] ]              
                    grid $label
                }
            }
        }
        grid $fr -sticky new -padx 2
    }
    grid $left_frame $right_frame -sticky n
}

# Private 

# The wizard has the chance to implement the event related to the Next button
# This is the function that generates that event
proc smart_wizard::NextEvent {step} {
    variable wizardid
    variable stepidlist
    variable wiznamespace
    set stepId [lindex $stepidlist $step]
    if {[info procs ${wiznamespace}::Next$stepId] ne ""} {
        ${wiznamespace}::Next$stepId
    }
}

proc smart_wizard::_ProcessItemNode { step node } {
    variable wprops
    set n [$node getAttribute n ""]
    set pn [$node getAttribute pn $n]
    set v [$node getAttribute v ""]
    set t [$node getAttribute type ""]
    set s [$node getAttribute state ""]
    #W "::kwiz::wprops($stepId,$n,value)= $v -> $i"
    set wprops($step,$n,value) [subst -nocommands -novariables $v]
    set wprops($step,$n,type) $t
    set wprops($step,$n,name) $pn
    set wprops($step,$n,state) $s
    
    if {$t eq "combo"} {
        set values [$node getAttribute values ""]
        if {[string index $values 0] eq "\["} {set values [[string range $values 1 end-1]]} {set values [split $values ","]}
        set wprops($step,$n,values) $values

        set onchange [$node getAttribute onchange ""]
        set wprops($step,$n,onchange) $onchange
    }
    if {$t in {"double" "integer"}} {
        set xpath [$node getAttribute xpath ""]
        set wprops($step,$n,xpath) $xpath
        set units [$node getAttribute units ""]
        set wprops($step,$n,units) $units
    }
    return $n
}
