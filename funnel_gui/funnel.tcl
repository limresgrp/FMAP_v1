##
## Funnel 1.0
##
##
##
## Author: Sannian and Victor Mion
##
##
##

package provide funnel 1.0

package require tooltip

namespace eval Funnel:: {
  namespace export funnel
	
  # window handles
  variable w;

  variable funnel_mol -1

  variable var_pointax 1.0
  variable var_pointay 1.0
  variable var_pointaz 1.0
  variable var_pointbx 5.0
  variable var_pointby 5.0
  variable var_pointbz 5.0

  variable var_rcyl 1
  variable var_alpha 1
  variable var_zcc 5
  variable var_mode 1

  variable var_pickmode 0
  variable anchor "<fill>"

  variable var_vertexx 0
  variable var_vertexz 0
	
  variable var_pointloww_x 2.0
  variable var_pointloww_y 2.0
  variable var_pointloww_z 2.0
  variable var_pointupw_x 6.0
  variable var_pointupw_y 6.0
  variable var_pointupw_z 6.0

  variable loww 2.0
  variable upw 6.0
  variable mins 2.0
  variable maxs 6.0

  variable var_cylx 0
  variable var_cyly 0
  variable var_cylz 0

  variable var_disthp 0

  variable var_infx 0
  variable var_infy 0
  variable var_infz 0

  variable var_supx 0
  variable var_supy 0
  variable var_supz 0

  variable var_rsphere 1

  variable textfile "untitled.txt"

  variable skeleton
  variable query
  variable curtainsel
  variable var_id
	
  variable wholemolecules "<fill>"
  variable reference "<?>"
  variable k_funnel "<fill>"
  variable arg_meta "<fill>"
  variable sigma_meta "<fill>"
  variable height_meta "<fill>"
  variable pace_meta "<fill>"
  variable biasfactor "<fill>"
  variable grid_min "<fill>"
  variable grid_max "<fill>"
  variable grid_bin "<fill>"
  variable ct_bin "<fill>"
  variable ct_pace "<fill>"
  variable k_uwall "<fill>"
  variable k_lwall "<fill>"
}

#
# Create the window and initialize data structures
#
proc Funnel::funnel {} {
  variable w

  variable funnel_mol

  variable var_pointax
  variable var_pointay
  variable var_pointaz
  variable var_pointbx
  variable var_pointby
  variable var_pointbz

  variable var_rcyl
  variable var_alpha
  variable var_zcc
  variable var_mode
	
  variable anchor
	
  variable loww
  variable upw
  variable mins
  variable maxs

  variable skeleton
  variable query
  variable var_id

  # If already initialized, just turn on
  if { [winfo exists .funnel] } {
    wm deiconify $w
    return
  }

  set w [toplevel ".funnel"]
  wm title $w "Funnel"
  wm resizable $w 0 0
  bind $w <Destroy> {catch {Funnel::nuke}}
	
  setup

  #                                                 ---------- MENUBAR ----------
  frame $w.menubar -relief raised -bd 2

  menubutton $w.menubar.help -text Help -underline 0 -menu $w.menubar.help.menu
  menubutton $w.menubar.export -text Export -underline 0 -menu $w.menubar.export.menu

  menu $w.menubar.help.menu -tearoff no
  $w.menubar.help.menu add command -label "Help..." -command "vmd_open_url https://sites.google.com/site/vittoriolimongelli/gallery#TOC-Funnel-Metadynamics-FM-"
  $w.menubar.help config -width 5

  menu $w.menubar.export.menu -tearoff no
  $w.menubar.export.menu add command -label "Export for Plumed" -command "Funnel::exportPlumed"
  $w.menubar.export config -width 8

  pack $w.menubar.export -side left
  pack $w.menubar.help -side right
  #                                                 ---------- END MENUBAR ----------

  frame $w.middle
  #                                                 ---------- LEFTCONTAINER ----------
  frame $w.middle.leftcontainer

  frame $w.middle.leftcontainer.labels
  label $w.middle.leftcontainer.labels.labelfill -text "" -width 10
  label $w.middle.leftcontainer.labels.labelx -text "X" -width 10
  label $w.middle.leftcontainer.labels.labely -text "Y" -width 10
  label $w.middle.leftcontainer.labels.labelz -text "Z" -width 10

  pack $w.middle.leftcontainer.labels.labelfill $w.middle.leftcontainer.labels.labelx $w.middle.leftcontainer.labels.labely $w.middle.leftcontainer.labels.labelz -side left


  frame $w.middle.leftcontainer.pointa
  label $w.middle.leftcontainer.pointa.labela -text "Point A" -width 10
  spinbox $w.middle.leftcontainer.pointa.entryx -width 8 -textvariable Funnel::var_pointax -format %3.2f -from -999 -to 999 -increment 0.1 
  spinbox $w.middle.leftcontainer.pointa.entryy -width 8 -textvariable Funnel::var_pointay -format %3.2f -from -999 -to 999 -increment 0.1
  spinbox $w.middle.leftcontainer.pointa.entryz -width 8 -textvariable Funnel::var_pointaz -format %3.2f -from -999 -to 999 -increment 0.1
  tooltip::tooltip $w.middle.leftcontainer.pointa.labela "\
  Modify the starting point of the funnel (Ang).\n\
  Hint: pick an atom in the core of the protein."
	
  pack $w.middle.leftcontainer.pointa.labela $w.middle.leftcontainer.pointa.entryx $w.middle.leftcontainer.pointa.entryy $w.middle.leftcontainer.pointa.entryz -side left

  frame $w.middle.leftcontainer.pointb
  label $w.middle.leftcontainer.pointb.labela -text "Point B" -width 10
  spinbox $w.middle.leftcontainer.pointb.entryx -width 8 -textvariable Funnel::var_pointbx -format %3.2f -from -999 -to 999 -increment 0.1
  spinbox $w.middle.leftcontainer.pointb.entryy -width 8 -textvariable Funnel::var_pointby -format %3.2f -from -999 -to 999 -increment 0.1
  spinbox $w.middle.leftcontainer.pointb.entryz -width 8 -textvariable Funnel::var_pointbz -format %3.2f -from -999 -to 999 -increment 0.1
  tooltip::tooltip $w.middle.leftcontainer.pointb.labela "\
  Modify the second point to change\n\
  direction of the funnel (Ang).\n\
  Hint: pick an atom of the ligand."
	
  pack $w.middle.leftcontainer.pointb.labela $w.middle.leftcontainer.pointb.entryx $w.middle.leftcontainer.pointb.entryy $w.middle.leftcontainer.pointb.entryz -side left
	
  frame $w.middle.leftcontainer.minmax
  label $w.middle.leftcontainer.minmax.labelmin -text "Min fps.lp" -width 10
  spinbox $w.middle.leftcontainer.minmax.entrymin -width 8 -textvariable Funnel::mins -format %3.2f -from -999 -to 999 -increment 0.1
  tooltip::tooltip $w.middle.leftcontainer.minmax.entrymin "\
  Modify the lowest value that linepos\n\
  can take during the simulation (Ang).\n\
  Depending on position of point A, you\n\
  might want to go deeper inside the\n\
  protein or not (negative and positive\n\
  values, respectively)."
  label $w.middle.leftcontainer.minmax.labelmax -text "Max fps.lp" -width 10
  spinbox $w.middle.leftcontainer.minmax.entrymax -width 8 -textvariable Funnel::maxs -format %3.2f -from -999 -to 999 -increment 0.1
  tooltip::tooltip $w.middle.leftcontainer.minmax.entrymax "\
  Modify the highest value that linepos\n\
  can take during the simulation (Ang).\n\
  Allow at least 3-4 Ang of cylinder\n\
  volume to the ligand outside of the\n\
  electrostatic interactions with the\n\
  receptor"
	
  pack $w.middle.leftcontainer.minmax.labelmin $w.middle.leftcontainer.minmax.entrymin $w.middle.leftcontainer.minmax.labelmax $w.middle.leftcontainer.minmax.entrymax -side left

  pack $w.middle.leftcontainer.labels $w.middle.leftcontainer.pointa $w.middle.leftcontainer.pointb $w.middle.leftcontainer.minmax
  #                                                   ---------- END LEFTCONTAINER ----------

  #                                                   ---------- RIGHTCONTAINER ----------
  frame $w.middle.rightcontainer

    # *** ROW ZCC ***
    frame $w.middle.rightcontainer.zccrow
    label $w.middle.rightcontainer.zccrow.labelzcc -text "Zcc" -width 10
    spinbox $w.middle.rightcontainer.zccrow.entryzcc -width 10 -textvariable Funnel::var_zcc -format %3.2f -from -999 -to 999 -increment 0.1
    tooltip::tooltip $w.middle.rightcontainer.zccrow.entryzcc "\
    Modify the switching point between\n\
    the cone and the cylinder (value in\n\
    Ang with respect to A). Always include\n\
    the path where the ligand interacts with\n\
    the receptor inside the cone region."
    # *** END ROW ZCC ***

    pack $w.middle.rightcontainer.zccrow.labelzcc $w.middle.rightcontainer.zccrow.entryzcc -side left

    # *** ROW ALPHA ***
    frame $w.middle.rightcontainer.alpharow
    label $w.middle.rightcontainer.alpharow.labelalpha -text "Alpha" -width 10
    spinbox $w.middle.rightcontainer.alpharow.entryalpha -width 10 -textvariable Funnel::var_alpha -format %1.2f -from 0 -to 1.57 -increment 0.01
    tooltip::tooltip $w.middle.rightcontainer.alpharow.entryalpha "\
    Modify the width of the cone (rad).\n\
    Avoid having the lower base of the\n\
    cone overextending with respect to\n\
    the receptor"
    # *** END ROW ALPHA ***

    pack $w.middle.rightcontainer.alpharow.labelalpha $w.middle.rightcontainer.alpharow.entryalpha -side left

    # *** ROW RCYL ***
    frame $w.middle.rightcontainer.rcylrow
    label $w.middle.rightcontainer.rcylrow.labelrcyl -text "RCyl" -width 10
    spinbox $w.middle.rightcontainer.rcylrow.entryrcyl -width 10 -textvariable Funnel::var_rcyl -format %3.2f -from -999 -to 999 -increment 0.1
    tooltip::tooltip $w.middle.rightcontainer.rcylrow.entryrcyl "\
    Modify the radius of the cylinder (Ang).\n\
    You might want to increase the value for\n\
    higher fluctuations of the ligand (big\n\
    molecules)"
    # *** END ROW RCYL ***

    pack $w.middle.rightcontainer.rcylrow.labelrcyl $w.middle.rightcontainer.rcylrow.entryrcyl -side left

    # *** LOWER WALL ***
    frame $w.middle.rightcontainer.loww
    label $w.middle.rightcontainer.loww.labelloww -text "Low. wall" -width 10
    spinbox $w.middle.rightcontainer.loww.entryloww -width 10 -textvariable Funnel::loww -format %3.2f -from -999 -to 999 -increment 0.1
    tooltip::tooltip $w.middle.rightcontainer.loww.entryloww "\
    Modify the lower wall in the simulation.\n\
    It must be greater than Min fps.lp (the\n\
    same value is not recommended). Unit in Ang.\n\
    ATTENTION: if the ligand exceed Min, the\n\
    simulation will crash."
    # *** END LOWER WALL ***
	
    pack $w.middle.rightcontainer.loww.labelloww $w.middle.rightcontainer.loww.entryloww -side left
	
    # *** UPPER WALL ***
    frame $w.middle.rightcontainer.upw
    label $w.middle.rightcontainer.upw.labelupw -text "Up. wall" -width 10
    spinbox $w.middle.rightcontainer.upw.entryupw -width 10 -textvariable Funnel::upw -format %3.2f -from -999 -to 999 -increment 0.1
    tooltip::tooltip $w.middle.rightcontainer.upw.entryupw "\
    Modify the upper wall in the simulation.\n\
    It must be less than Max fps.lp (the same\n\
    value is not recommended). Unit in Ang.\n\
    ATTENTION: if the ligand exceed Max, the\n\
    simulation will crash."
    # *** END UPPER WALL ***
	
    pack $w.middle.rightcontainer.upw.labelupw $w.middle.rightcontainer.upw.entryupw -side left
	
	
  pack $w.middle.rightcontainer.zccrow $w.middle.rightcontainer.alpharow $w.middle.rightcontainer.rcylrow $w.middle.rightcontainer.loww $w.middle.rightcontainer.upw
  #                                                   ---------- END RIGHTCONTAINER ----------

  pack $w.middle.leftcontainer $w.middle.rightcontainer -side left

  #                                                   ---------- BOTTOMCONTAINER ----------
  frame $w.bottomcontainer

  frame $w.bottomcontainer.pickrow
  radiobutton $w.bottomcontainer.pickrow.pointabtn -text "Press key p and pick an atom from the screen to move point A (yellow)" -variable Funnel::var_pickmode -value 0
  tooltip::tooltip $w.bottomcontainer.pickrow.pointabtn "\
  Use this functionality to set point A\n\
  over a displayed atom in VMD. Follow\n\
  the instruction in the text to use."
  radiobutton $w.bottomcontainer.pickrow.pointbbtn -text "Press key p and pick an atom from the screen to move point B (green)" -variable Funnel::var_pickmode -value 1
  tooltip::tooltip $w.bottomcontainer.pickrow.pointbbtn "\
  Use this functionality to set point B\n\
  over a displayed atom in VMD. Follow\n\
  the instruction in the text to use."
  radiobutton $w.bottomcontainer.pickrow.anchor -text "Press key p and pick an atom from the screen to set anchor point" -variable Funnel::var_pickmode -value 2
  tooltip::tooltip $w.bottomcontainer.pickrow.anchor "\
  Use this functionality to set the anchor\n\
  point over a displayed atom in VMD. Follow\n\
  the instruction in the text to use."
  pack $w.bottomcontainer.pickrow.pointabtn $w.bottomcontainer.pickrow.pointbbtn $w.bottomcontainer.pickrow.anchor -fill x

  frame $w.bottomcontainer.radiocol
  radiobutton $w.bottomcontainer.radiocol.transparentbtn -text "Invisible mode" -variable Funnel::var_mode -value 0
  radiobutton $w.bottomcontainer.radiocol.opaquebtn -text "Transparent mode" -variable Funnel::var_mode -value 1
  pack $w.bottomcontainer.radiocol.transparentbtn $w.bottomcontainer.radiocol.opaquebtn -fill x

  pack $w.bottomcontainer.pickrow $w.bottomcontainer.radiocol -side left
  #                                                   ---------- END BOTTOMCONTAINER ----------

  #                                                   ---------- RESNAMEFRAME ----------
  frame $w.resname
  label $w.resname.labelid -text "ID"
  entry $w.resname.entryid -width 3 -textvariable Funnel::var_id
  if {[$w.resname.entryid get] == ""} {
    $w.resname.entryid insert 0 $funnel_mol
  }
  label $w.resname.labelsel -text "Ligand"
  entry $w.resname.entrysel -text "" -width 15 -textvariable Funnel::query
  tooltip::tooltip $w.resname.entrysel "\
  Insert the selection of the ligand in\n\
  VMD format.\n\
  Hint: resname MOL and noh"
  entry $w.resname.curtainsel -text "" -width 15 -textvariable Funnel::curtainsel
  menubutton $w.resname.curtain -relief raised -bd 2 -direction flush -menu $w.resname.curtain.menu
  tooltip::tooltip $w.resname.curtainsel "\
  Insert the appropriate selection or\n\
  value depending on the selected voice\n\
  in the menu."
  menu $w.resname.curtain.menu -tearoff no
  $w.resname.curtain.menu add command -label "wholemolecules" -command [namespace code {$w.resname.curtainsel delete 0 end; $w.resname.curtain configure -text "wholemolecules"}]
  $w.resname.curtain.menu add command -label "reference" -command [namespace code {$w.resname.curtainsel delete 0 end; $w.resname.curtainsel insert 0 [file tail [tk_getOpenFile]]; $w.resname.curtain configure -text "reference"; Funnel::assign_entry}]
  $w.resname.curtain.menu add command -label "k_funnel" -command [namespace code {$w.resname.curtainsel delete 0 end; $w.resname.curtain configure -text "k_funnel"}]
  $w.resname.curtain.menu add command -label "arg_meta" -command [namespace code {$w.resname.curtainsel delete 0 end; $w.resname.curtain configure -text "arg_meta"}]
  $w.resname.curtain.menu add command -label "sigma_meta" -command [namespace code {$w.resname.curtainsel delete 0 end; $w.resname.curtain configure -text "sigma_meta"}]
  $w.resname.curtain.menu add command -label "height_meta" -command [namespace code {$w.resname.curtainsel delete 0 end; $w.resname.curtain configure -text "height_meta"}]
  $w.resname.curtain.menu add command -label "pace_meta" -command [namespace code {$w.resname.curtainsel delete 0 end; $w.resname.curtain configure -text "pace_meta"}]
  $w.resname.curtain.menu add command -label "biasfactor" -command [namespace code {$w.resname.curtainsel delete 0 end; $w.resname.curtain configure -text "biasfactor"}]
  $w.resname.curtain.menu add command -label "grid_min" -command [namespace code {$w.resname.curtainsel delete 0 end; $w.resname.curtain configure -text "grid_min"}]
  $w.resname.curtain.menu add command -label "grid_max" -command [namespace code {$w.resname.curtainsel delete 0 end; $w.resname.curtain configure -text "grid_max"}]
  $w.resname.curtain.menu add command -label "grid_bin" -command [namespace code {$w.resname.curtainsel delete 0 end; $w.resname.curtain configure -text "grid_bin"}]
  $w.resname.curtain.menu add command -label "rct_ustride" -command [namespace code {$w.resname.curtainsel delete 0 end; $w.resname.curtain configure -text "rct_ustride"}]
  $w.resname.curtain.menu add command -label "k_uwall" -command [namespace code {$w.resname.curtainsel delete 0 end; $w.resname.curtain configure -text "k_uwall"}]
  $w.resname.curtain.menu add command -label "k_lwall" -command [namespace code {$w.resname.curtainsel delete 0 end; $w.resname.curtain configure -text "k_lwall"}]

  button $w.resname.btn -text "Apply" -width 10 -command "Funnel::displaySkeleton"
  button $w.resname.reset -text "Reset" -width 8 -command "Funnel::not_so_nuke"
  pack $w.resname.labelid $w.resname.entryid $w.resname.labelsel $w.resname.entrysel $w.resname.curtain $w.resname.curtainsel $w.resname.btn $w.resname.reset -side left
  #                                                   ---------- END RESNAMEFRAME ----------

  #                                                   ---------- TEXTFRAME ----------
  frame $w.txt
  text $w.txt.text -bg White -bd 2
  pack $w.txt.text
  #                                                   ---------- END TEXTFRAME ----------

  pack $w.menubar -padx 1 -fill x
  pack $w.middle $w.bottomcontainer
  pack $w.resname -fill x -padx 27
  pack $w.txt


  bind $w.middle.leftcontainer.pointa.entryx <Return> [namespace code {Funnel::handle_update_pointax}]
  bind $w.middle.leftcontainer.pointa.entryy <Return> [namespace code {Funnel::handle_update_pointay}]
  bind $w.middle.leftcontainer.pointa.entryz <Return> [namespace code {Funnel::handle_update_pointaz}]
  bind $w.middle.leftcontainer.pointb.entryx <Return> [namespace code {Funnel::handle_update_pointbx}]
  bind $w.middle.leftcontainer.pointb.entryy <Return> [namespace code {Funnel::handle_update_pointby}]
  bind $w.middle.leftcontainer.pointb.entryz <Return> [namespace code {Funnel::handle_update_pointbz}]
  bind $w.middle.rightcontainer.zccrow.entryzcc <Return> [namespace code {Funnel::handle_update_zcc}]
  bind $w.middle.rightcontainer.alpharow.entryalpha <Return> [namespace code {Funnel::handle_update_alpha}]
  bind $w.middle.rightcontainer.rcylrow.entryrcyl <Return> [namespace code {Funnel::handle_update_rcyl}]
  bind $w.middle.rightcontainer.loww.entryloww <Return> [namespace code {Funnel::handle_update_loww}]
  bind $w.middle.rightcontainer.upw.entryupw <Return> [namespace code {Funnel::handle_update_upw}]
  bind $w.middle.leftcontainer.minmax.entrymin <Return> [namespace code {Funnel::update}]
  bind $w.middle.leftcontainer.minmax.entrymax <Return> [namespace code {Funnel::update}]
  bind $w.resname.curtainsel <Return> [namespace code {Funnel::assign_entry}]
	
  #Using command trace to call function whenever the binded variables change
#  trace add variable Funnel::var_pointax write Funnel::handle_update_pointax
#  trace add variable Funnel::var_pointay write Funnel::handle_update_pointay
#  trace add variable Funnel::var_pointaz write Funnel::handle_update_pointaz
#  trace add variable Funnel::var_pointbx write Funnel::handle_update_pointbx
#  trace add variable Funnel::var_pointby write Funnel::handle_update_pointby
#  trace add variable Funnel::var_pointbz write Funnel::handle_update_pointbz
#  trace add variable Funnel::var_rcyl write Funnel::handle_update_rcyl
#  trace add variable Funnel::var_alpha write Funnel::handle_update_alpha
#  trace add variable Funnel::var_zcc write Funnel::handle_update_zcc
  trace add variable Funnel::var_mode write Funnel::handle_update_mode

  #Using command trace to use method atom_picked as a callback whenever the user pick an atom
  trace add variable ::vmd_pick_event write Funnel::atom_picked

}

proc Funnel::assign_entry {} {
  variable w
  variable funnel_mol
  variable wholemolecules
  variable reference
  variable k_funnel
  variable arg_meta
  variable sigma_meta
  variable height_meta
  variable pace_meta
  variable biasfactor
  variable grid_min
  variable grid_max
  variable grid_bin
  variable ct_bin
  variable ct_pace	
  variable k_uwall
  variable k_lwall
	
  if {[$w.resname.curtain cget -text] == "wholemolecules"} {
    set wholemolecules ""
    set temp [atomselect $funnel_mol "[$w.resname.curtainsel get]"]
    set temp2 [$temp get serial]
    set counter 1
    foreach item $temp2 {
      append wholemolecules $item
      if {$counter!=[llength $temp2]} {
	append wholemolecules ","
      }
      incr counter
    }
    unset temp
    unset temp2
  } elseif {[$w.resname.curtain cget -text] == "reference"} {
    set reference [$w.resname.curtainsel get]  
  } elseif {[$w.resname.curtain cget -text] == "k_funnel"} {
    set k_funnel [$w.resname.curtainsel get]  
  } elseif {[$w.resname.curtain cget -text] == "arg_meta"} {
    set arg_meta [$w.resname.curtainsel get]   
  } elseif {[$w.resname.curtain cget -text] == "sigma_meta"} {
    set sigma_meta [$w.resname.curtainsel get]   
  } elseif {[$w.resname.curtain cget -text] == "height_meta"} {
    set height_meta [$w.resname.curtainsel get] 
  } elseif {[$w.resname.curtain cget -text] == "pace_meta"} {
    set pace_meta [$w.resname.curtainsel get]  
  } elseif {[$w.resname.curtain cget -text] == "biasfactor"} {
    set biasfactor [$w.resname.curtainsel get]   
  } elseif {[$w.resname.curtain cget -text] == "grid_min"} {
    set grid_min [$w.resname.curtainsel get]
  } elseif {[$w.resname.curtain cget -text] == "grid_max"} {
    set grid_max [$w.resname.curtainsel get]
  } elseif {[$w.resname.curtain cget -text] == "grid_bin"} {
    set grid_bin [$w.resname.curtainsel get]
  } elseif {[$w.resname.curtain cget -text] == "rct_ustride"} {
    set ct_pace [$w.resname.curtainsel get]
  } elseif {[$w.resname.curtain cget -text] == "k_uwall"} {
    set k_uwall [$w.resname.curtainsel get]   
  } elseif {[$w.resname.curtain cget -text] == "k_lwall"} {
    set k_lwall [$w.resname.curtainsel get] 
  }
}

proc funnel_tk {} {
  Funnel::funnel
  return $Funnel::w
}

proc Funnel::setup {} {
  variable w
  variable funnel_mol
  variable skeleton
	
  set skeleton ""

  if {[molinfo list] == ""} {
    tk_messageBox -message "You have to provide a structure beforehand." -type ok -icon error
    catch {destroy $w}   
  } else {
    set funnel_mol [molinfo top get id]
#  set funnel_mol [mol new]
#  mol rename $funnel_mol {Funnel}
    drawFunnel $funnel_mol
  }

  lappend skeleton "# Remember to create empty HILLS and COLVAR files in case you are doing the first run with RESTART option.\n# <fill> = necessary an input.\n# <?> = necessary a file.\n"
  lappend skeleton "RESTART\n\n"
  lappend skeleton "WHOLEMOLECULES ENTITY0="
  lappend skeleton "lig: COM ATOMS="
  lappend skeleton "fps: FUNNEL_PS LIGAND=lig REFERENCE="
  lappend skeleton "FUNNEL ARG=fps.lp,fps.ld ZCC="
  lappend skeleton "KAPPA="
  lappend skeleton "# remove BIASFACTOR if you want to perform standard metadynamics\n"
  lappend skeleton "METAD ARG="
  lappend skeleton "LOWER_WALLS ARG=fps.lp AT=" 
  lappend skeleton "KAPPA="
  lappend skeleton "UPPER_WALLS ARG=fps.lp AT="
  lappend skeleton "KAPPA="
  lappend skeleton "PRINT STRIDE="

#  display resetview
}

proc Funnel::displaySkeleton {} {
  variable w
  variable skeleton

  variable var_pointax
  variable var_pointay
  variable var_pointaz

  variable var_pointbx
  variable var_pointby
  variable var_pointbz

  variable var_zcc
  variable var_alpha
  variable var_rcyl
  variable mins
  variable maxs
  variable loww
  variable upw
	
  variable anchor

  variable query
  variable var_id
	
  variable wholemolecules
  variable reference
  variable k_funnel
  variable arg_meta
  variable sigma_meta
  variable height_meta
  variable pace_meta
  variable biasfactor
  variable grid_min
  variable grid_max
  variable grid_bin
  variable ct_pace
	
  variable k_uwall
  variable k_lwall

  #check the fields are not empty
  if {!($query == "" && $var_id == "")} {
    #perform query to find the atoms composing the ligand 
    set lig [atomselect $var_id "$query"]
    puts $lig
    set ligatoms [$lig get serial]
    puts $ligatoms

    

    #insert the known values here such as the position of point a and point b
    set strout ""
    set index 0
    foreach elem $skeleton {
      append strout $elem
      if {$index == 4} {
        append strout $reference " ANCHOR=" $anchor " POINTS=" [roundPlumed $var_pointax] "," [roundPlumed $var_pointay] "," [roundPlumed $var_pointaz] "," [roundPlumed $var_pointbx] "," [roundPlumed $var_pointby] "," [roundPlumed $var_pointbz] "\n\n"
      } elseif {$index == 5} {
        append strout [roundPlumed $var_zcc] " ALPHA=" $var_alpha " RCYL=" [roundPlumed $var_rcyl] " MINS=" [roundPlumed $mins] " MAXS=" [roundPlumed $maxs] " " 
      } elseif {$index == 3} {
        set bound [llength $ligatoms]
        for {set i 0} {$i < $bound} {incr i} {
          set val [lindex $ligatoms $i]
          if {$i < ($bound-1)} {
            append strout $val ","
          } else {
            append strout $val
          }
        }
        append strout "\n\n"
      } elseif {$index == 9} {
	append strout [roundPlumed $loww] " "
      } elseif {$index == 11} {
	append strout [roundPlumed $upw] " "
      } elseif {$index == 2} {
	append strout $wholemolecules "\n\n"
      } elseif {$index == 6} {
        append strout $k_funnel " NBINS=500 NBINZ=500 FILE=BIAS LABEL=funnel\n\n"
      } elseif {$index == 8} {
	append strout $arg_meta " SIGMA=" $sigma_meta " HEIGHT=" $height_meta " PACE=" $pace_meta " TEMP=300 BIASFACTOR=" $biasfactor " GRID_MIN=" $grid_min " GRID_MAX=" $grid_max " GRID_BIN=" $grid_bin " CALC_RCT RCT_USTRIDE=" $ct_pace " LABEL=metad\n\n"     
      } elseif {$index == 10} {
	append strout $k_lwall " EXP=2 OFFSET=0 LABEL=lwall\n\n"
      } elseif {$index == 12} {
	append strout $k_uwall " EXP=2 OFFSET=0 LABEL=uwall\n\n"    
      } elseif {$index == 13} {
	append strout $pace_meta " ARG=* FILE=COLVAR"    
      }
      incr index
    }

    $w.txt.text delete 1.0 end 
    $w.txt.text insert end $strout
    unset strout
  }
}

proc Funnel::exportPlumed {} {
  variable textfile
  variable w

  set textfile [tk_getSaveFile]

  if {$textfile != ""} {
    set fd [open $textfile "w"]

    puts $fd [$w.txt.text get 1.0 end]

    close $fd
  }
}

proc Funnel::atom_picked {args} {
  # use the picked atom's index and molecule id
  global vmd_pick_atom vmd_pick_mol

  variable var_pointax
  variable var_pointay
  variable var_pointaz

  variable var_pointbx
  variable var_pointby
  variable var_pointbz

  variable var_pickmode
	
  variable anchor

  set atom [atomselect $vmd_pick_mol "index $vmd_pick_atom"]
  lassign [$atom get {resname resid}] resname resid

  set atom [atomselect $vmd_pick_mol "index $vmd_pick_atom"]
  set atom_coordinates [$atom get {x y z}]

  set pa {}
  lappend pa $var_pointax
  lappend pa $var_pointay
  lappend pa $var_pointaz

  set pb {}
  lappend pb $var_pointbx
  lappend pb $var_pointby
  lappend pb $var_pointbz

  set temp [lindex $atom_coordinates 0]

  if {$var_pickmode == 0} {
    set var_pointax [lindex [lindex $atom_coordinates 0] 0]
    set var_pointay [lindex [lindex $atom_coordinates 0] 1]
    set var_pointaz [lindex [lindex $atom_coordinates 0] 2]
  } elseif {$var_pickmode == 1} {
    set var_pointbx [lindex [lindex $atom_coordinates 0] 0]
    set var_pointby [lindex [lindex $atom_coordinates 0] 1]
    set var_pointbz [lindex [lindex $atom_coordinates 0] 2]
  } else {
    set anchor [$atom get serial]
  }

  Funnel::update
}

# It takes two lists as parameters
proc Funnel::drawFunnel {mol} {
  variable var_pointax
  variable var_pointay
  variable var_pointaz

  variable var_pointbx
  variable var_pointby
  variable var_pointbz

  variable var_vertexx
  variable var_vertexy
  variable var_vertexz
	
  variable var_pointloww_x
  variable var_pointloww_y
  variable var_pointloww_z
  variable var_pointupw_x
  variable var_pointupw_y
  variable var_pointupw_z

  variable var_disthp

  variable var_infx
  variable var_infy
  variable var_infz

  variable var_supx
  variable var_supy
  variable var_supz

  variable var_cylx
  variable var_cyly
  variable var_cylz

  variable var_rcyl
  variable var_mode
  variable var_rsphere
	
  variable loww
  variable upw

  set temp1 [Funnel::computeConeVertex]
  set temp2 [Funnel::computeCylinderBase]
  set temp3 [Funnel::computeWalls]

  if {$temp1 == 0} {
    puts "An error occurred while computing the form of the funnel."
  } elseif {$temp2 == 0} {
    puts "An error occurred while computing the form of the funnel."
  } elseif {$temp3 == 0} {
    puts "An error occurred while computing the walls."
  } else {
    #If we are in normal mode
    if {$var_mode == 1} {
      graphics $mol color yellow
      graphics $mol sphere "$var_pointax $var_pointay $var_pointaz" radius $var_rsphere resolution 100

      graphics $mol color green 
      graphics $mol sphere "$var_pointbx $var_pointby $var_pointbz" radius $var_rsphere resolution 100
	    
      graphics $mol color red 
      graphics $mol sphere "$var_pointloww_x $var_pointloww_y $var_pointloww_z" radius $var_rsphere resolution 100
      graphics $mol sphere "$var_pointupw_x $var_pointupw_y $var_pointupw_z" radius $var_rsphere resolution 100

      graphics $mol color orange
      graphics $mol cone "$var_pointax $var_pointay $var_pointaz" "$var_vertexx $var_vertexy $var_vertexz" radius $var_disthp resolution 100
      graphics $mol cylinder "$var_cylx $var_cyly $var_cylz" "$var_infx $var_infy $var_infz" radius $var_rcyl resolution 100
      graphics $mol material Transparent
    } elseif {$var_mode == 0} {
      graphics $mol color yellow
      graphics $mol sphere "$var_pointax $var_pointay $var_pointaz" radius $var_rsphere resolution 100

      graphics $mol color green 
      graphics $mol sphere "$var_pointbx $var_pointby $var_pointbz" radius $var_rsphere resolution 100
	    
      graphics $mol color red 
      graphics $mol sphere "$var_pointloww_x $var_pointloww_y $var_pointloww_z" radius $var_rsphere resolution 100
      graphics $mol sphere "$var_pointupw_x $var_pointupw_y $var_pointupw_z" radius $var_rsphere resolution 100

      graphics $mol color orange
      graphics $mol cylinder "$var_supx $var_supy $var_supz" "$var_infx $var_infy $var_infz" radius 0.01 resolution 100
    }
  }
}

proc Funnel::erase {} {
  variable funnel_mol

  graphics $funnel_mol delete all
}

proc Funnel::update {} {
  variable w
  variable var_pointax
  variable var_pointay
  variable var_pointaz
  variable var_pointbx
  variable var_pointby
  variable var_pointbz

  variable funnel_mol
  variable var_rsphere
  variable var_rcyl

  #round the points to the third decimal digits
  # puts "\[BEFORE\] var_pointax : $var_pointax"
  set var_pointax [roundThird $var_pointax]
  # puts "\[AFTER\] var_pointax : $var_pointax"
  set var_pointay [roundThird $var_pointay]
  set var_pointaz [roundThird $var_pointaz]
  set var_pointbx [roundThird $var_pointbx]
  set var_pointby [roundThird $var_pointby]
  set var_pointbz [roundThird $var_pointbz]

  if {[molinfo list] == ""} {
    tk_messageBox -message "You have to provide a structure beforehand." -type ok -icon error
  } else {
    set funnel_mol [molinfo top get id]
    $w.resname.entryid delete 0 end
    $w.resname.entryid insert 0 $funnel_mol
    Funnel::erase
    Funnel::drawFunnel $Funnel::funnel_mol
  }
}

proc Funnel::isnumeric value {
#    if {![catch {expr {abs($value)}}]} {
#        return 1
#    }
#    set value [string trimleft $value 0]
#    if {![catch {expr {abs($value)}}]} {
#        return 1
#    }
#    return 0
     return [catch {expr {abs($value)}}]
}

proc Funnel::checkMoleculesParameters {} {
  # variable funnel_mol

  # # puts "checkMoleculesParameters"

  # set funnel_center [molinfo $funnel_mol get center]
  # set funnel_center_matrix [molinfo $funnel_mol get center_matrix]
  # set funnel_rotate_matrix [molinfo $funnel_mol get rotate_matrix]
  # set funnel_scale_matrix [molinfo $funnel_mol get scale_matrix]
  # set funnel_global_matrix [molinfo $funnel_mol get global_matrix]
  # set funnel_alpha [molinfo $funnel_mol get alpha]
  # set funnel_beta [molinfo $funnel_mol get beta]
  # set funnel_gamma [molinfo $funnel_mol get gamma]
  # set funnel_a [molinfo $funnel_mol get a]
  # set funnel_b [molinfo $funnel_mol get b]
  # set funnel_c [molinfo $funnel_mol get c]

  # puts "\nfunnel_center : $funnel_center"
  # puts "funnel_center_matrix : $funnel_center_matrix"
  # puts "funnel_rotate_matrix : $funnel_rotate_matrix"
  # puts "funnel_scale_matrix : $funnel_scale_matrix"
  # puts "funnel_global_matrix : $funnel_global_matrix"
  # puts "funnel_alpha : $funnel_alpha\n"

  # set listmol [molinfo list]

  # foreach mol $listmol {
  #   set temp_center [molinfo $mol get center]
  #   set temp_center_matrix [molinfo $mol get center_matrix]
  #   set temp_rotate_matrix [molinfo $mol get rotate_matrix]
  #   set temp_scale_matrix [molinfo $mol get scale_matrix]
  #   set temp_global_matrix [molinfo $mol get global_matrix]
  #   set temp_alpha [molinfo $mol get alpha]
  #   set temp_beta [molinfo $mol get beta]
  #   set temp_gamma [molinfo $mol get gamma]
  #   set temp_a [molinfo $mol get a]
  #   set temp_b [molinfo $mol get b]
  #   set temp_c [molinfo $mol get c]

  #   puts "\n\t temp_center : $temp_center"
  #   puts "\t temp_center_matrix : $temp_center_matrix"
  #   puts "\t temp_rotate_matrix : $temp_rotate_matrix"
  #   puts "\t temp_scale_matrix : $temp_scale_matrix"
  #   puts "\t temp_global_matrix : $temp_global_matrix"
  #   puts "\ttemp_alpha : $temp_alpha\n"

  #   if {$temp_center != $funnel_center} {
  #     molinfo $funnel_mol set {center} $temp_center
  #   }

  #   if {$temp_center_matrix != $funnel_center_matrix} {
  #     molinfo $funnel_mol set {center_matrix} $temp_center_matrix
  #   }

  #   if {$temp_rotate_matrix != $funnel_rotate_matrix} {
  #     molinfo $funnel_mol set {rotate_matrix} $temp_rotate_matrix
  #   }

  #   if {$temp_scale_matrix != $funnel_scale_matrix} {
  #     molinfo $funnel_mol set {scale_matrix} $temp_scale_matrix
  #   }

  #   if {$temp_global_matrix != $funnel_global_matrix} {
  #     molinfo $funnel_mol set {global_matrix} $temp_global_matrix
  #   }

  #   if {$temp_alpha != $funnel_alpha} {
  #     molinfo $funnel_mol set alpha $temp_alpha
  #   }
  # }

}

proc Funnel::computeConeVertex {} { 
  # puts "Compute cone vertex"
  variable var_pointax
  variable var_pointay
  variable var_pointaz
  variable var_pointbx
  variable var_pointby
  variable var_pointbz

  variable var_rcyl
  variable var_alpha
  variable var_zcc

  variable var_vertexx
  variable var_vertexy
  variable var_vertexz

  variable var_disthp

  if {$var_alpha == 0} {
    puts "ERROR: The value of alpha can't be 0."
    return 0
  } else {
    # Compute the vertex of the cone given point A and B and zcc.
    # Remember zcc is the distance between pointa A and the start of the cylinder, that is also the end of the cone).
    set dist_AB [string range [expr sqrt( ($var_pointbx-$var_pointax)*($var_pointbx-$var_pointax) + ($var_pointby-$var_pointay)*($var_pointby-$var_pointay) +($var_pointbz-$var_pointaz)*($var_pointbz-$var_pointaz))] 0 3]

    set var_disthp [expr $var_rcyl + tan($var_alpha) * $var_zcc]

    set z_cone [expr $var_zcc + $var_rcyl / tan($var_alpha)]
    set t_cone [expr $z_cone / $dist_AB]
    set var_vertexx [expr $var_pointax + ($var_pointbx-$var_pointax)*$t_cone]
    set var_vertexy [expr $var_pointay + ($var_pointby-$var_pointay)*$t_cone]
    set var_vertexz [expr $var_pointaz + ($var_pointbz-$var_pointaz)*$t_cone]

    return 1
  }
}

proc Funnel::computeCylinderBase {} { 
  variable var_pointax
  variable var_pointay
  variable var_pointaz
  variable var_pointbx
  variable var_pointby
  variable var_pointbz

  variable var_rcyl
  variable var_alpha
  variable var_zcc

  variable var_vertexx
  variable var_vertexy
  variable var_vertexz

  variable var_cylx
  variable var_cyly
  variable var_cylz

  variable var_infx
  variable var_infy
  variable var_infz

  variable var_supx
  variable var_supy
  variable var_supz

  set dist_AB [string range [expr sqrt( ($var_pointbx-$var_pointax)*($var_pointbx-$var_pointax) + ($var_pointby-$var_pointay)*($var_pointby-$var_pointay) +($var_pointbz-$var_pointaz)*($var_pointbz-$var_pointaz))] 0 3]
  set t_cyl  [expr $var_zcc / $dist_AB] 

  set var_cylx  [expr $var_pointax + ($var_pointbx-$var_pointax)*$t_cyl]
  set var_cyly  [expr $var_pointay + ($var_pointby-$var_pointay)*$t_cyl]
  set var_cylz  [expr $var_pointaz + ($var_pointbz-$var_pointaz)*$t_cyl]

  set t_inf 30.0
  set var_infx [expr $var_pointax + ($var_pointbx-$var_pointax)*$t_inf]
  set var_infy [expr $var_pointay + ($var_pointby-$var_pointay)*$t_inf]
  set var_infz [expr $var_pointaz + ($var_pointbz-$var_pointaz)*$t_inf]

  set var_supx [expr $var_pointax + ($var_pointbx-$var_pointax)*(-$t_inf)]
  set var_supy [expr $var_pointay + ($var_pointby-$var_pointay)*(-$t_inf)]
  set var_supz [expr $var_pointaz + ($var_pointbz-$var_pointaz)*(-$t_inf)]
}

proc Funnel::handle_update_pointax {args} {
  variable var_pointax

  set temp [Funnel::isnumeric $Funnel::var_pointax]
  if {$temp != 0} {
    tk_messageBox -message "The value of point A coordinate x is not a number" -type ok -icon error
  } else {
#    Funnel::displaySkeleton
    Funnel::update
  }
}

proc Funnel::computeWalls {} {
  variable var_pointax
  variable var_pointay
  variable var_pointaz
  variable var_pointbx
  variable var_pointby
  variable var_pointbz
	
  variable loww
  variable upw
	
  variable var_pointloww_x
  variable var_pointloww_y
  variable var_pointloww_z
  variable var_pointupw_x
  variable var_pointupw_y
  variable var_pointupw_z
	
  set lowprop [expr $loww/(sqrt(($var_pointbx-$var_pointax)**2 + ($var_pointby-$var_pointay)**2 + ($var_pointbz-$var_pointaz)**2))]
  set upwprop [expr $upw/(sqrt(($var_pointbx-$var_pointax)**2 + ($var_pointby-$var_pointay)**2 + ($var_pointbz-$var_pointaz)**2))]
	
  set var_pointloww_x [expr $var_pointax + ($var_pointbx-$var_pointax)*$lowprop]
  set var_pointloww_y [expr $var_pointay + ($var_pointby-$var_pointay)*$lowprop]
  set var_pointloww_z [expr $var_pointaz + ($var_pointbz-$var_pointaz)*$lowprop]
  set var_pointupw_x [expr $var_pointax + ($var_pointbx-$var_pointax)*$upwprop]
  set var_pointupw_y [expr $var_pointay + ($var_pointby-$var_pointay)*$upwprop]
  set var_pointupw_z [expr $var_pointaz + ($var_pointbz-$var_pointaz)*$upwprop]
}

proc Funnel::handle_update_pointay {args} {
  variable var_pointay

  set temp [Funnel::isnumeric $Funnel::var_pointay]
  if {$temp != 0} {
    tk_messageBox -message "The value of point A coordinate y is not a number" -type ok -icon error
  } else {
#    Funnel::displaySkeleton
    Funnel::update
  }
}

proc Funnel::handle_update_pointaz {args} {
  variable var_pointaz

  set temp [Funnel::isnumeric $Funnel::var_pointaz]
  if {$temp != 0} {
    tk_messageBox -message "The value of point A coordinate z is not a number" -type ok -icon error
  } else {
#    Funnel::displaySkeleton
    Funnel::update
  }
}

proc Funnel::handle_update_pointbx {args} {
  variable var_pointbx

  set temp [Funnel::isnumeric $Funnel::var_pointbx]
  if {$temp != 0} {
    tk_messageBox -message "The value of point B coordinate x is not a number" -type ok -icon error
  } else {
#    Funnel::displaySkeleton
    Funnel::update
  }
}

proc Funnel::handle_update_pointby {args} {
  variable var_pointby

  set temp [Funnel::isnumeric $Funnel::var_pointby]
  if {$temp != 0} {
    tk_messageBox -message "The value of point B coordinate y is not a number" -type ok -icon error
  } else {
#    Funnel::displaySkeleton
    Funnel::update
  }
}

proc Funnel::handle_update_pointbz {args} {
  variable var_pointbz

  set temp [Funnel::isnumeric $Funnel::var_pointbz]
  if {$temp != 0} {
    tk_messageBox -message "The value of point B coordinate z is not a number" -type ok -icon error
  } else {
#    Funnel::displaySkeleton
    Funnel::update
  }
}

proc Funnel::handle_update_rcyl {args} {
  variable var_rcyl

  set temp [Funnel::isnumeric $Funnel::var_rcyl]
  if {$temp != 0} {
    tk_messageBox -message "The value of Rcyl is not a number" -type ok -icon error
  } else {
#    Funnel::displaySkeleton
    Funnel::update
  }
}

proc Funnel::handle_update_alpha {args} {
  variable var_alpha

  set temp [Funnel::isnumeric $Funnel::var_alpha]
  if {$temp != 0} {
    tk_messageBox -message "The value of Alpha is not a number" -type ok -icon error
  } elseif {[expr {$Funnel::var_alpha < 0.01}] || [expr {$Funnel::var_alpha > 1.57}]} {
    tk_messageBox -message "Only intervals between 0.01 and 1.57 are supported" -type ok -icon error  
  } else {
#    Funnel::displaySkeleton
    Funnel::update
  }
}

proc Funnel::handle_update_zcc {args} {
  variable var_zcc

  set temp [Funnel::isnumeric $Funnel::var_zcc]
  if {$temp != 0} {
    tk_messageBox -message "The value of Zcc is not a number" -type ok -icon error
  } else {
#    Funnel::displaySkeleton
    Funnel::update
  }
}

proc Funnel::handle_update_loww {args} {
  variable loww

  set temp [Funnel::isnumeric $Funnel::loww]
  if {$temp != 0} {
    tk_messageBox -message "The value of Low wall is not a number" -type ok -icon error
  } else {
#    Funnel::displaySkeleton
    Funnel::update
  }
}

proc Funnel::handle_update_upw {args} {
  variable upw

  set temp [Funnel::isnumeric $Funnel::upw]
  if {$temp != 0} {
    tk_messageBox -message "The value of Up wall is not a number" -type ok -icon error
  } else {
#    Funnel::displaySkeleton
    Funnel::update
  }
}

proc Funnel::handle_update_mode {args} {
  variable var_mode
  Funnel::update
}

proc Funnel::roundThird {num} {
  return [expr {double(round(1000*$num))/1000}]
}

proc Funnel::roundPlumed {num} {
  return [expr {double(round(1000*$num))/10000}]
}

proc Funnel::nuke { args } {
  variable funnel_mol
  variable var_mode

  Funnel::not_so_nuke
	
  graphics $funnel_mol delete all

  trace vdelete Funnel::var_mode w Funnel::handle_update_mode
  trace vdelete ::vmd_pick_event w Funnel::atom_picked
	
#  foreach var [info vars ::Funnel::*] {
#    set $var ""
#  }
}

proc Funnel::not_so_nuke { args } {
  variable w

  variable var_pointax
  variable var_pointay
  variable var_pointaz
      
  variable var_pointbx
  variable var_pointby
  variable var_pointbz
	
  variable mins
  variable maxs
	
  variable var_zcc
  variable var_alpha
  variable var_rcyl
  variable loww
  variable upw
	
  variable curtainsel
  variable query

  set var_pointax 1.0
  set var_pointay 1.0
  set var_pointaz 1.0
  set var_pointbx 5.0
  set var_pointby 5.0
  set var_pointbz 5.0
  set mins 2.0
  set maxs 6.0
  set var_zcc 5.0
  set var_alpha 1.0
  set var_rcyl 1.0
  set loww 2.0
  set upw 6.0
  set query ""
  set curtainsel ""

  $w.resname.curtainsel delete 0 end
  $w.resname.curtain configure -text ""
  $w.txt.text delete 1.0 end

  Funnel::handle_update_pointax
  Funnel::handle_update_pointay
  Funnel::handle_update_pointaz
  Funnel::handle_update_pointbx
  Funnel::handle_update_pointby
  Funnel::handle_update_pointbz
  Funnel::handle_update_zcc
  Funnel::handle_update_alpha
  Funnel::handle_update_rcyl
  Funnel::handle_update_loww
  Funnel::handle_update_upw
  Funnel::update
}

