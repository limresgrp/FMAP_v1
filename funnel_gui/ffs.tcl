##  FFS - Funnel Fast Software
##
##  A script to plot 2D FES from plumed in VMD
##
## Author: Sannian
##
package provide ffs 1.0

package require tooltip

namespace eval FFS:: {
  namespace export ffs

  # windows handles - variabili globali
  variable w              ; ## Define the variable for the windows of the software
  variable z
#  variable progressbar
  variable plumed ""      ; ## Where the bin of plumed is
  variable mintozero ""   ; ## Select if the sum_hills option of plumed must be set or not
  variable kT "2.5"       ; ## Value for kT, initialized to 2.5
  variable dyn ""         ; ##
  variable bin ""         
  variable input ""
  variable trj ""         ; ## Path of the trajectory
  variable pdb ""         ; ## Path of the pdb
  variable hills ""       ; ## Path of the HILLS file
  variable output ""      ; ## Folder for input/output, despite the name
  variable fes ""         ; ## Path for the fes
  variable dimensions ""  ; ## Stores the dimensionality of the system 
  variable borders ""     ; ## Stores min and max of the important values
  variable binning ""     
  variable min ""
  variable max ""
  variable fes_value ""   
  variable const ""       ; ## Constant to rescale fes that doesn't have the same dimension of the window
  variable Canvas ""      ; ## Used to define the rectangle for point selection in the fes graph
  variable difference ""  ; ## Difference between COLVAR file and frames in the simulation
  variable Wref ""        ; ## Value of reference for the unbound pose, to be used in the calculation of the deltaG
  variable Rcyl "0.1"     ; ## Value of the radius of the cylinder of the Funnel used during the simulation (0.1 as default)
  variable rej "0"         ; ## Value for the reject time in the calculation of the mean on the fly
  variable stride "10000" ; ## Value for the stride during deltaG calculation
}

## create a window and initialize data structure
proc FFS::ffs {} {
  variable w
  variable plumed
  variable mintozero
  variable kT
  variable dyn
  variable bin
  variable input
  variable trj
  variable pdb
  variable hills
  variable output
  variable fes
  variable fes_value
  variable Wref
  variable Rcyl
 
  global vmd_frame
 
  # If already initialized, just turn on
  if { [winfo exists .ffs] } {
    wm deiconify $w
    return
  }

  set w [toplevel ".ffs"]
  wm title $w "FFS - Funnel Fast Software"
  wm resizable $w 0 0
  bind $w <Destroy> {catch {FFS::nuke}}
	
# Create menubar
  frame $w.menubar -relief raised -bd 2
  pack $w.menubar -padx 1 -fill x

  menubutton $w.menubar.help -text Help -underline 0 -menu $w.menubar.help.menu
  menubutton $w.menubar.file -text File -underline 0 -menu $w.menubar.file.menu

# Help menu and file menu
  menu $w.menubar.help.menu -tearoff no
  $w.menubar.help.menu add command -label "Help..." -command "vmd_open_url https://sites.google.com/site/vittoriolimongelli/gallery#TOC-Funnel-Metadynamics-FM-"
  $w.menubar.help config -width 5

  menu $w.menubar.file.menu -tearoff no
  $w.menubar.file.menu add command -label "Export..." -command FFS::print_PostScript
  $w.menubar.file config -width 5
  
  pack $w.menubar.file -side left
  pack $w.menubar.help -side right

# Where the fes will stay
  frame $w.fes -width 652 -height 577
  fescanvas $w.fes.graph -height 500 -width 500 
  fescanvas $w.fes.x -height 75 -width 500
  fescanvas $w.fes.y -height 500 -width 150                                  
  pack $w.fes.y -side left -anchor ne
  pack $w.fes.graph -side top -anchor ne
  pack $w.fes.x -side top -anchor ne
  
  frame $w.fes.info

  label $w.fes.info.pre -text "At frame:"
  label $w.fes.info.frame
  label $w.fes.info.post -text "cv value:"
  label $w.fes.info.cv1  
  label $w.fes.info.cv2  
  label $w.fes.info.fes  

  pack $w.fes.info.pre -side left
  pack $w.fes.info.frame -side left
  pack $w.fes.info.post -side left
  pack $w.fes.info.cv1 -side left
  pack $w.fes.info.cv2 -side right
  pack $w.fes.info.fes -side right
  
  pack $w.fes.info -side bottom

  bind $w.fes.graph.canvas <ButtonPress-2>   [namespace code {canvas_select_start  %x %y}]
  bind $w.fes.graph.canvas <B2-Motion>       [namespace code {canvas_select_expand %x %y}]
  bind $w.fes.graph.canvas <ButtonRelease-2> [namespace code {canvas_select_end    %x %y}]

# Input section
  frame $w.plumed

# Plumed directory
  frame $w.plumed.dir
  label $w.plumed.dir.l -text "No file" -anchor w
  button $w.plumed.dir.b -text "Plumed (bin)" -activeforeground White -activebackground Blue -width 12 -command [namespace code {set bin [tk_getOpenFile]; $w.plumed.dir.l configure -text [file tail $bin]; puts "Selected binary $bin"}]
  tooltip::tooltip $w.plumed.dir.b "\
  Please select Plumed binary\n\
  in case you wish to use\n\
  driver or sum_hills."
	
  pack $w.plumed.dir.l -side right
  pack $w.plumed.dir.b -side left
  pack $w.plumed.dir -side top

# Input .dat file
  frame $w.plumed.dat
  label $w.plumed.dat.l -text "No file" -anchor w
  button $w.plumed.dat.b -text "Input (.dat)" -activeforeground White -activebackground Blue -width 12 -command [namespace code {set input [tk_getOpenFile]; $w.plumed.dat.l configure -text [file tail $input]; puts "Selected input file $input"}]
  tooltip::tooltip $w.plumed.dat.b "\
  Please select an input file\n\
  for a driver calculation.\n\
  Not necessary for sum_hills."
	
  pack $w.plumed.dat.l -side right
  pack $w.plumed.dat.b -side left
  pack $w.plumed.dat -side top

# Trajectory file
  frame $w.plumed.trj
  label $w.plumed.trj.l -text "No file" -anchor w
  button $w.plumed.trj.b -text "Trajectory" -activeforeground White -activebackground Blue -width 8 -command [namespace code {set trj [tk_getOpenFile]; $w.plumed.trj.l configure -text [file tail $trj]; puts "Selected trajectory $trj"}]
  tooltip::tooltip $w.plumed.trj.b "\
  Please select a trajectory file\n\
  for a driver calculation.\n\
  Allowed formats are:\n\
  - dcd\n\
  - crd\n\
  - xtc\n\
  - trr"
	
  pack $w.plumed.trj.l -side right
  pack $w.plumed.trj.b -side left
  pack $w.plumed.trj -side top

# Dynamics command
  frame $w.plumed.dyn
  label $w.plumed.dyn.l -text "Trajectory extension" -anchor w
  menubutton $w.plumed.dyn.m -relief raised -bd 2 -direction flush -textvariable $dyn -menu $w.plumed.dyn.m.menu
  menu $w.plumed.dyn.m.menu -tearoff no
  $w.plumed.dyn.m.menu add command -label "dcd" -command [namespace code {set dyn "dcd"; $w.plumed.dyn.m configure -text "dcd "; puts "Selected dcd extension"}]
  $w.plumed.dyn.m.menu add command -label "crd" -command [namespace code {set dyn "crd"; $w.plumed.dyn.m configure -text "crd "; puts "Selected crd extension"}]
  $w.plumed.dyn.m.menu add command -label "xtc" -command [namespace code {set dyn "xtc"; $w.plumed.dyn.m configure -text "xtc "; puts "Selected xtc extension"}]
  $w.plumed.dyn.m.menu add command -label "trr" -command [namespace code {set dyn "trr"; $w.plumed.dyn.m configure -text "trr "; puts "Selected trr extension"}]
	
  pack $w.plumed.dyn.l -side left
  pack $w.plumed.dyn.m -side right
  pack $w.plumed.dyn -side top

# PDB
  frame $w.plumed.pdb
  label $w.plumed.pdb.l -text "No file" -anchor w
  button $w.plumed.pdb.b -text "Pdb file" -activeforeground White -activebackground Blue -width 8 -command [namespace code {set pdb [tk_getOpenFile]; $w.plumed.pdb.l configure -text [file tail $pdb]; puts "Selected pdb file $pdb"}]
  tooltip::tooltip $w.plumed.pdb.b "\
  Please select a pdb file\n\
  for a driver calculation.\n\
  Remember that the file might\n\
  need to have last two columns\n\
  filled for the driver to work.\n\
  Not necessary for sum_hills."
	
  pack $w.plumed.pdb.l -side right
  pack $w.plumed.pdb.b -side left
  pack $w.plumed.pdb -side top

# HILLS file
  frame $w.plumed.hills
  label $w.plumed.hills.l -text "No file" -anchor w
  button $w.plumed.hills.b -text "Hills" -activebackground Blue -activeforeground White -width 8 -command [namespace code {set hills [tk_getOpenFile]; $w.plumed.hills.l configure -text [file tail $hills]; puts "Selected hills file $hills"}]
  tooltip::tooltip $w.plumed.hills.b "\
  Please select a HILLS file\n\
  for a sum_hills calculation.\n\
  Not necessary for driver."
	
  pack $w.plumed.hills.l -side right
  pack $w.plumed.hills.b -side left
  pack $w.plumed.hills -side top

# Mintozero command
  frame $w.plumed.mtz
  label $w.plumed.mtz.l -text "Min to zero?" -anchor w
  menubutton $w.plumed.mtz.m -relief raised -bd 2 -direction flush -menu $w.plumed.mtz.m.menu
  menu $w.plumed.mtz.m.menu -tearoff no
  $w.plumed.mtz.m.menu add command -label "yes" -command [namespace code {set mintozero 1; $w.plumed.mtz.m configure -text "yes";puts "Selected option mintozero"}]
  $w.plumed.mtz.m.menu add command -label "no" -command [namespace code {set mintozero 0; $w.plumed.mtz.m configure -text "no "; puts "Mintozero turned off"}]
  tooltip::tooltip $w.plumed.mtz.m "\
  Do you wish to have the minimum\n\
  as the value zero of your fes?"
	
  pack $w.plumed.mtz.l -side left
  pack $w.plumed.mtz.m -side right
  pack $w.plumed.mtz -side top

# kT value
  frame $w.plumed.kt
  label $w.plumed.kt.l -text "Value of kT?" -anchor w
  entry $w.plumed.kt.e -relief sunken -width 5 -bg White -textvariable FFS::kT
  button $w.plumed.kt.b -text "Enter" -width 5 -command [namespace code {set kT [$w.plumed.kt.e get];puts $kT}]

  pack $w.plumed.kt.l -side left
  pack $w.plumed.kt.b -side right
  pack $w.plumed.kt.e -side right
  pack $w.plumed.kt -side top

# Output folder
  frame $w.plumed.out
  label $w.plumed.out.l -text "No folder" -anchor w
  button $w.plumed.out.b -text "Output" -activeforeground White -activebackground Blue -width 8 -command [namespace code {set output [tk_chooseDirectory]; $w.plumed.out.l configure -text [file tail $output]; puts "Selected output folder $output"}]
  tooltip::tooltip $w.plumed.out.b "\
  Used to set the output folder\n\
  in driver and sum_hills calculations.\n\
  It is also essential if you wish\n\
  to follow the collective variables\n\
  while changing the simulation frames."
	
  pack $w.plumed.out.l -side right
  pack $w.plumed.out.b -side left
  pack $w.plumed.out -side top
  
# RUN! (driver)
  frame $w.plumed.run
  button $w.plumed.run.b -text "RUN Driver" -width 10 -command [namespace code {FFS::driver $bin $input $dyn $trj $pdb}]
  tooltip::tooltip $w.plumed.run.b "\
  Performs a driver run on a selected\n\
  trajectory. Compulsory inputs: plumed\n\
  binary, input file, trajectory file and\n\
  extension, pdb file with masses on\n\
  the occupancy column, and output folder."

  pack $w.plumed.run.b -side bottom
  pack $w.plumed.run -side top 

# RUN! (sum_hills)
  frame $w.plumed.run2
  button $w.plumed.run2.b1 -text "RUN Sum_hills LR" -width 15 -command [namespace code {FFS::sum_hills $bin $hills $output 1}]
  tooltip::tooltip $w.plumed.run2.b1 "\
  Peforms a sum_hills run on a selected\n\
  hills file. The output is automatically\n\
  low in resolution, useful to plot the\n\
  FES on the canvas. Compulsory inputs:\n\
  plumed binary, hills file, mintozero, and\n\
  output folder.\n\
  ATTENTION: the action resets all fes\n\
  already produced."
  button $w.plumed.run2.b2 -text "RUN Sum_hills HR" -width 15 -command [namespace code {FFS::sum_hills $bin $hills $output 0}]
  tooltip::tooltip $w.plumed.run2.b2 "\
  Peforms a sum_hills run on a selected\n\
  hills file. The output is at the resolution\n\
  selected during simulation, in case more\n\
  precise evaluation are necessary. Compulsory\n\
  inputs: plumed binary, hills file, mintozero,\n\
  and the output folder.\n\
  ATTENTION: the action resets all fes\n\
  already produced."
  frame $w.plumed.run3
  label $w.plumed.run3.l -text "Stride"
  entry $w.plumed.run3.e -relief sunken -width 5 -bg White -textvariable FFS::stride
  tooltip::tooltip $w.plumed.run3.e "\
  Specify a stride value that will define\n\
  the number of points in the deltaG calculation\n\
  depending on the length of your simulation."
  button $w.plumed.run3.b -text "RUN Sum_hills stride" -width 20 -command [namespace code {FFS::sum_hills $bin $hills $output 2}]
  tooltip::tooltip $w.plumed.run3.b "\
  Peforms a sum_hills run on a selected\n\
  hills file. The output is at the resolution\n\
  selected during simulation and several fes\n\
  will be produced depending on the stride\n\
  parameter and the deposition rate during\n\
  simulation. Compulsory inputs: plumed binary\n\
  hills file, mintozero and the output folder.\n\
  ATTENTION: the action resets all fes\n\
  already produced."
	
  pack $w.plumed.run2.b1 -side left
  pack $w.plumed.run2.b2 -side right
  pack $w.plumed.run2 -side top

  pack $w.plumed.run3.l -side left
  pack $w.plumed.run3.e -side left
  pack $w.plumed.run3.b -side right
  pack $w.plumed.run3 -side top

# Plot FES
  frame $w.plumed.plot
  button $w.plumed.plot.b -text "Plot FES" -width 7 -command [namespace code {set fes [tk_getOpenFile];if {$fes!=""} {puts "Taken as input file $fes"; set_pixels; fesplot}}]
  tooltip::tooltip $w.plumed.plot.b "\
  Select a fes file to be plotted.\n\
  It can be 1D or 2D, but in 2D case\n\
  visualization might require some\n\
  time. Be patient."
	
  pack $w.plumed.plot.b -side left
  pack $w.plumed.plot -side top

  pack $w.plumed -side right
  pack $w.fes -side left

  button $w.plumed.plot.res -text "Clear" -width 5 -command FFS::reset
  button $w.plumed.plot.b2 -text "Trace" -width 5 -command [namespace code update_position]
  tooltip::tooltip $w.plumed.plot.b2 "\
  Force tracing of the collective variable\n\
  in the current simulation frame.\n\
  Available only if \"Output\" has been\n\
  specified."
  tooltip::tooltip $w.plumed.plot.res "\
  Clear the tracing function, emptying\n\
  the canvas for clearer visualization."

  pack $w.plumed.plot.res -side right
  pack $w.plumed.plot.b2 -side right
	
  frame $w.plumed.mm
  frame $w.plumed.mm.x
  frame $w.plumed.mm.y
  label $w.plumed.mm.x.l1 -text "min_x"
  label $w.plumed.mm.x.l2 -text "max_x" 
  entry $w.plumed.mm.x.e1 -relief sunken -width 5 -bg White -state normal
  entry $w.plumed.mm.x.e2 -relief sunken -width 5 -bg White -state normal
  label $w.plumed.mm.y.l3 -text "min_y" 
  label $w.plumed.mm.y.l4 -text "max_y" 
  entry $w.plumed.mm.y.e3 -relief sunken -width 5 -bg White -state normal
  entry $w.plumed.mm.y.e4 -relief sunken -width 5 -bg White -state normal
  button $w.plumed.mm.b -text "Extract" -width 5 -command [namespace code {find_it_bobby [$w.plumed.mm.x.e1 get] [$w.plumed.mm.x.e2 get] [$w.plumed.mm.y.e3 get] [$w.plumed.mm.y.e4 get]}]
  tooltip::tooltip $w.plumed.mm.b "\
  Extract pdb files related to the\n\
  specified interval. If you are not\n\
  sure about it, select the interval\n\
  directly on the canvas\n\
  on the canvas."
	
  pack $w.plumed.mm.x.l1 -side left -anchor nw
  pack $w.plumed.mm.x.l2 -side right -anchor ne
  pack $w.plumed.mm.x.e1 -side left -anchor sw
  pack $w.plumed.mm.x.e2 -side right -anchor se
  pack $w.plumed.mm.y.l3 -side left -anchor nw
  pack $w.plumed.mm.y.l4 -side right -anchor ne
  pack $w.plumed.mm.y.e3 -side left -anchor sw
  pack $w.plumed.mm.y.e4 -side right -anchor se
  pack $w.plumed.mm.x -side top
  pack $w.plumed.mm.y -side top
  pack $w.plumed.mm.b -side bottom
  pack $w.plumed.mm -side top

	
  frame $w.plumed.dg
  frame $w.plumed.dg.wref
  frame $w.plumed.dg.rcyl
  label $w.plumed.dg.wref.l -text "Wref value at"
  entry $w.plumed.dg.wref.e -relief sunken -width 5 -bg White -textvariable FFS::Wref
  tooltip::tooltip $w.plumed.dg.wref.e "\
  Value of the CV at which\n\
  to take the reference value\n\
  for Wref in the deltaG calculation."  
  button $w.plumed.dg.wref.b -text "Enter" -width 5 -command [namespace code {set Wref [$w.plumed.dg.wref.e get]}]
  label $w.plumed.dg.rcyl.l -text "Value of Rcyl"
  entry $w.plumed.dg.rcyl.e -relief sunken -width 5 -bg White -textvariable FFS::Rcyl
  tooltip::tooltip $w.plumed.dg.rcyl.e "\
  Value of Rcyl used during\n\
  the FM simulation (in nm)."
  button $w.plumed.dg.rcyl.b -text "Enter" -width 5 -command [namespace code {set Rcyl [$w.plumed.dg.rcyl.e get]}]
  button $w.plumed.dg.b -text "Calculate!" -width 10 -command [namespace code {calculate [$w.plumed.mm.x.e1 get] [$w.plumed.mm.x.e2 get] [$w.plumed.mm.y.e3 get] [$w.plumed.mm.y.e4 get] [$w.plumed.dg.wref.e get] [$w.plumed.dg.rcyl.e get]}]
  label $w.plumed.dg.l -text ""
  tooltip::tooltip $w.plumed.dg.b "\
  Performs a deltaG calculation by specifying\n\
  an interval of interest and a free-energy\n\
  surface. Result is displayed in kcal/mol.\n\
  Compulsory inputs: min_x and max_x (1D) +\n\
  min_y and max_y (only for 2D), Wref and Rcyl."

# Reset button
  frame $w.plumed.reset
  button $w.plumed.reset.b -text "Reset" -width 8 -command [namespace code {not_so_nuke}]
	
# Convergence section
  frame $w.plumed.settings
  label $w.plumed.settings.l2 -text "Rej. time"
  entry $w.plumed.settings.e2 -relief sunken -width 5 -bg White -textvariable FFS::rej
  tooltip::tooltip $w.plumed.settings.e2 "\
  Specify a reject time for convergence\n\
  calculation. First part of metadynamics\n\
  should be discarded since it is a settlement\n\
  portion where CV space has not been sampled\n\
  thoroughly."
  frame $w.plumed.convergence
  button $w.plumed.convergence.b -text "Convergence" -width 10 -command [namespace code {convergence}]
  tooltip::tooltip $w.plumed.convergence.b "\
  Performs a deltaG calculation if\n\
  the user provides the necessary\n\
  inputs for an interval of interest.\n\ 
  Please run Sum_hills stride beforehand.\n\
  The output consist of the mean-on-the-\n\
  fly of the binding free energy, together\n\
  with the relative error. May take some\n\
  time. Compulsory inputs: output folder,\n\
  min_x and max_x (1D), min_y and max_y\n\
  (only for 2D), Wref, Rcyl, and reject\n\
  time."
  button $w.plumed.convergence.b2 -text "Block bootstrap" -width 15 -command [namespace code {apply_bootstrap $rej}]
  tooltip::tooltip $w.plumed.convergence.b2 "\
  Performs a revised block bootstrap\n\
  applicable to well-tempered FM. The\n\
  command \"Convergence\" must be run\n\
  beforehand. The output consists of the\n\
  weighted mean and standard error calculated\n\
  through bootstrap analysis of 10 blocks\n\
  that divide the simulation time without\n\
  overlaps. Compulsory inputs: output folder\n\
  and reject time."

  pack $w.plumed.dg.wref.l -side left
  pack $w.plumed.dg.wref.e -side left
  pack $w.plumed.dg.wref.b -side right
  pack $w.plumed.dg.rcyl.l -side left
  pack $w.plumed.dg.rcyl.e -side left
  pack $w.plumed.dg.rcyl.b -side right
  pack $w.plumed.dg.wref -side top
  pack $w.plumed.dg.rcyl -side top
  pack $w.plumed.dg.b -side left
  pack $w.plumed.dg.l -side right
  pack $w.plumed.dg -side top
  pack $w.plumed.reset.b -side left
  pack $w.plumed.reset -side top
  pack $w.plumed.settings.l2 -side left
  pack $w.plumed.settings.e2 -side left
  pack $w.plumed.settings -side top
  pack $w.plumed.convergence.b2 -side right
  pack $w.plumed.convergence.b -side right
  pack $w.plumed.convergence -side top
	
  # the trace
  trace variable vmd_frame([molinfo top]) w FFS::il_pianto_paga
}

## Program just to run a sum_hills, if you provided all the necessary input
proc FFS::sum_hills {plumed hills output mode} {
  variable mintozero
  variable kT
  set pseudodimensions ""
  variable stride
  if {$plumed=="No file" || $plumed==""} {
    error "ERROR, you didn't specify a correct binary file."
  } elseif {$hills=="No file" || $hills==""} {
    error "ERROR, you didn't specify a correct hills file."
  } elseif {$output=="No folder" || $output==""} {
    error "ERROR, you didn't specify a correct folder where to save your FES."
  } elseif {$mintozero==""} {
    puts "You didn't specify any option for mintozero, it has been set automatically at no."
    set mintozero 0
  }

  catch {eval file delete [glob $output/fes_*]}

  if {$mode==1} {
    set infile [open [file normalize $hills]]
    gets $infile line
    set pseudodimensions [regexp -all {sigma_\S+} $line]
    close $infile
  }
  if {$mintozero==1} { 
    if {$mode==1} {
      if {$pseudodimensions==2} {
	if {[lindex [array get tcl_platform platform] 1]=="windows"} {
	  puts [eval exec [auto_execok start] \"\" [list $plumed --no-mpi --standalone-executable sum_hills --hills $hills --mintozero --kt $kT --bin 150,150 --outfile $output/fes_lr.dat &]]
	} else {
	  puts [eval exec [list $plumed --no-mpi --standalone-executable sum_hills --hills $hills --mintozero --kt $kT --bin 150,150 --outfile $output/fes_lr.dat]]
	}
      } else {
	if {[lindex [array get tcl_platform platform] 1]=="windows"} {
	  puts [eval exec [auto_execok start] \"\" [list $plumed --no-mpi --standalone-executable sum_hills --hills $hills --mintozero --kt $kT --bin 150 --outfile $output/fes_lr.dat &]]
	} else {
	  puts [eval exec [list $plumed --no-mpi --standalone-executable sum_hills --hills $hills --mintozero --kt $kT --bin 150 --outfile $output/fes_lr.dat]]
	}	
      }
    } elseif {$mode==2} {
      if {[lindex [array get tcl_platform platform] 1]=="windows"} {
	puts [eval exec [auto_execok start] \"\" [list $plumed --no-mpi --standalone-executable sum_hills --hills $hills --mintozero --kt $kT --stride $stride --outfile $output/fes_ &]]
      } else {
	puts [eval exec [list $plumed --no-mpi --standalone-executable sum_hills --hills $hills --mintozero --kt $kT --stride $stride --outfile $output/fes_]]
      }
    } else {
      if {[lindex [array get tcl_platform platform] 1]=="windows"} {
	puts [eval exec [auto_execok start] \"\" [list $plumed --no-mpi --standalone-executable sum_hills --hills $hills --mintozero --kt $kT --outfile $output/fes_hr.dat &]]
      } else {
        puts [eval exec [list $plumed --no-mpi --standalone-executable sum_hills --hills $hills --mintozero --kt $kT --outfile $output/fes_hr.dat]]
      }      
    }
#    puts "Launched $plumed sum_hills --hills $hills --mintozero --kt $kT --outfile $output/fes.dat"
  } else { 
    if {$mode==1} {
      if {$pseudodimensions==2} {  
	if {[lindex [array get tcl_platform platform] 1]=="windows"} {
	  puts [eval exec [auto_execok start] \"\" [list $plumed --no-mpi --standalone-executable sum_hills --hills $hills --kt $kT --bin 150,150 --outfile $output/fes_lr.dat &]]
	} else {
	  puts [eval exec [list $plumed --no-mpi --standalone-executable sum_hills --hills $hills --kt $kT --bin 150,150 --outfile $output/fes_lr.dat]]
	}		
      } else {
	if {[lindex [array get tcl_platform platform] 1]=="windows"} {
	  puts [eval exec [auto_execok start] \"\" [list $plumed --no-mpi --standalone-executable sum_hills --hills $hills --kt $kT --bin 150 --outfile $output/fes_lr.dat &]]
	} else {
	  puts [eval exec [list $plumed --no-mpi --standalone-executable sum_hills --hills $hills --kt $kT --bin 150 --outfile $output/fes_lr.dat]]
	}
      }
    } elseif {$mode==2} {  
## Here I should put the possibility to choose the stride value, though it would break apart the current code
      if {[lindex [array get tcl_platform platform] 1]=="windows"} {
	puts [eval exec [auto_execok start] \"\" [list $plumed --no-mpi --standalone-executable sum_hills --hills $hills --kt $kT --stride $stride --outfile $output/fes_ &]]
      } else {
	puts [eval exec [list $plumed --no-mpi --standalone-executable sum_hills --hills $hills --kt $kT --stride $stride --outfile $output/fes_]]
      }		
    } else {
      if {[lindex [array get tcl_platform platform] 1]=="windows"} {
        puts [eval exec [auto_execok start] \"\" [list $plumed --no-mpi --standalone-executable sum_hills --hills $hills --kt $kT --outfile $output/fes_hr.dat &]]      
      } else {
        puts [eval exec [list $plumed --no-mpi --standalone-executable sum_hills --hills $hills --kt $kT --outfile $output/fes_hr.dat]]
      }
    }
#    puts "Launched $plumed sum_hills --hills $hills --kt $kT --outfile $output/fes.dat" 
  }
}

## Program to launch a driver calculation
proc FFS::driver {bin input dyn trj pdb} {
  variable output
  if {$bin=="No file" || $bin==""} {
    error "ERROR, you didn't specify a correct binary file."
  } elseif {$input=="No file" || $input==""} {
    error "ERROR, you didn't specify a correct input file."
  } elseif {$trj=="No folder" || $trj==""} {
    error "ERROR, you didn't specify a correct simulation trajectory."
  } elseif {$dyn==""} {
    error "ERROR, you didn't specify any option for the trajectory extension."
  } elseif {$pdb==""} {
    error "ERROR, you didn't specify any option for the pdb file."
  }
  cd $output
  if {[lindex [array get tcl_platform platform] 1]=="windows"} {
    puts [eval exec [auto_execok start] \"\" [list $bin --no-mpi driver --plumed $input --mf_$dyn $trj --pdb $pdb &]]
  } else {
    puts [eval exec [list $bin --no-mpi driver --plumed $input --mf_$dyn $trj --pdb $pdb]]
  }
}

## Program to assign a directory to a label
proc FFS::assign_dir {label} {
  set plumed [tk_getOpenFile]
  $label configure -text $plumed
  unset plumed
}

#####################################################################################################

## This program gives orders to plot the FES. Depending on dimensionality, it chooses if plotting
## a curve or a gradient graph, taking value stored by initialization.
proc FFS::fesplot {} {
  variable w
  variable fes
  variable dimensions
  variable borders
  set coords ""
  set infile [open "$fes"]
  seek $infile 0

  update idletasks

### Just to remember, z is always created, but it is read and written only if required.

  while {[gets $infile line] > -1} {
    if {![regexp {#!} $line] && $line!=""} {
      set z ""
      set x [lindex $line 0]
      set y [lindex $line 1]
      if {$dimensions==2} {
        set z [lindex $line 2]
      }
      lappend coords [expr int(($x-[lindex $borders 0])/([lindex $borders 1]-[lindex $borders 0])*([winfo width $w.fes.graph.canvas]-1))] [expr int(([winfo height $w.fes.graph.canvas]-1)-(($y-[lindex $borders 2])/([lindex $borders 3]-[lindex $borders 2]))*([winfo height $w.fes.graph.canvas]-1))]
      if {$dimensions==2} {
        lappend coords [expr {($z-[lindex $borders 4])/([lindex $borders 5]-[lindex $borders 4])}]
      }
    }
  }

  if {$dimensions==2} {
    draw_gradient $coords
  } else {
    for {set i 0} {$i < [expr {[regexp -all {\w+} $coords]/2}]} {incr i} {
      $w.fes.graph.canvas create rectangle [lindex $coords [expr {$i*2}]] [lindex $coords [expr {$i*2+1}]] [lindex $coords [expr {$i*2}]] [lindex $coords [expr {$i*2+1}]] -width 1
    }
    $w.fes.graph.canvas create line $coords -smooth true
  }
  unset coords
  unset x
  unset y
  unset z
  close $infile
}

proc FFS::fescanvas { c args } {
  frame $c
  eval { canvas $c.canvas -highlightthickness 0 -background white} $args
  grid $c.canvas -sticky news
  grid rowconfigure $c 0 -weight 1
  grid columnconfigure $c 0 -weight 1
  return $c.canvas
}

proc FFS::draw_gradient { coords } {
  variable w
  variable borders
  variable pixels
  variable const
  set r1 255
  set g1 0
  set b1 0
  set r2 152
  set g2 251
  set b2 152
  set r3 0
  set g3 0
  set b3 255
	
  set limit [expr {[regexp -all {(^|[ ])[0-9]*\.?[0-9]*} $coords]/3}]
  for {set i 0} {$i < $limit} {incr i} {
    set part [lindex $coords [expr {$i*3+2}]]
    if {$part <= 0.5} {
      set nR [expr int( $r2*$part*2 + (0.5-$part)*$r3*2 )]
      set nG [expr int( $g2*$part*2 + (0.5-$part)*$g3*2 )]
      set nB [expr int( $b2*$part*2 + (0.5-$part)*$b3*2 )]
    } else {
      set nR [expr int( $r1*($part-0.5)*2 + (1.0-$part)*$r2*2 )]
      set nG [expr int( $g1*($part-0.5)*2 + (1.0-$part)*$g2*2 )]
      set nB [expr int( $b1*($part-0.5)*2 + (1.0-$part)*$b2*2 )]
    }
    
    set col [format %02x $nR]
    append col [format %02x $nG]
    append col [format %02x $nB]

    set values [lindex $coords [expr {$i*3}]]
    lappend values [lindex $coords [expr {$i*3+1}]]
    
    $w.fes.graph.canvas create rectangle [lindex $values 0] [lindex $values 1] [expr {[lindex $values 0]+[lindex $const 0]}] [expr {[lindex $values 1]+[lindex $const 1]}] -fill "\#$col" -outline ""
  }
  unset r1
  unset g1
  unset b1
  unset r2
  unset g2
  unset b2
  unset r3
  unset g3
  unset b3
  unset col
  unset values
}

proc FFS::interval { value1 value2 } {
  variable w
  variable dimensions
  variable fes
  variable borders
  update idletasks
  $w.fes.graph.canvas delete x
  $w.fes.graph.canvas delete y
  set x1 [expr {($value1-[lindex $borders 0])/([lindex $borders 1]-[lindex $borders 0])*([winfo width $w.fes.graph.canvas])}]
  if {$dimensions==2} {
    set y1 [expr {([winfo height $w.fes.graph.canvas])-(($value2-[lindex $borders 2])/([lindex $borders 3]-[lindex $borders 2]))*([winfo height $w.fes.graph.canvas])}]
  }
  if {$dimensions==2} {
    $w.fes.graph.canvas create line $x1 0 $x1 [expr {[winfo height $w.fes.graph.canvas]}] -fill black -tags x
    $w.fes.graph.canvas create line 0 $y1 [expr {[winfo width $w.fes.graph.canvas]}] $y1 -fill black -tags y
  } else {
    $w.fes.graph.canvas create line $x1 0 $x1 [expr {[winfo height $w.fes.graph.canvas]}] -fill red -tags x
  }
  unset x1
  if {$dimensions==2} {
    unset y1
  }
}

proc FFS::update_position {args} {
  variable w
  global vmd_frame
  variable bin
  variable dimensions
  variable input
  variable output
  variable trj
  variable dyn
  variable difference
  control_colvar
  cd $output
  set infile [open "COLVAR"]
  seek $infile 0
  set counter 0
#  set time [molinfo top get frame]
  set time_trj $vmd_frame([molinfo top])
  if {[expr {$time_trj-$difference}] < 0} {
    puts "No value in COLVAR for this frame"
  } else {
    while {[gets $infile line] > -1} {
      if {![regexp {#!} $line]} {
        if {$counter == [expr ($time_trj-$difference)]} {
          set cv1 [lindex $line 1]
          if {$dimensions==2} {
            set cv2 [lindex $line 2]
          } else {
	    set cv2 ""
          }
          break
        }
        incr counter
      } 
    }
  }
  $w.fes.info.frame configure -text $vmd_frame([molinfo top])
  $w.fes.info.cv1 configure -text $cv1
  if {$dimensions==2} {
    $w.fes.info.cv2 configure -text $cv2
  }
  interval $cv1 $cv2
  close $infile
  unset time_trj
  unset counter
  unset cv1
  unset cv2
}

### This program initializes whichever file you pass as input fes to see what are max and min for all
### the set of variables. It stores those values in an array to be used by everyone.
proc FFS::set_pixels {} {
  variable w
  variable fes
  variable dimensions
  variable borders
  variable const
  set set_of_values ""
  variable lower_limit "0.0"
  variable upper_limit "0.0"
  variable name ""
  set infile [open $fes]
  seek $infile 0
  set pixels ""
  set const ""  

  ## Since the canvas calculates its dimensions with respect to the normal canvas dimensions,
  ## in these lines I reapply all the default dimensions, to always start from the same point
  $w.fes.graph.canvas delete all
  $w.fes.x.canvas delete all
  $w.fes.y.canvas delete all
  $w.fes.graph.canvas configure -width 500
  $w.fes.x.canvas configure -width 500
  $w.fes.graph.canvas configure -height 500
  $w.fes.y.canvas configure -height 500
  update idletasks
   
  ### The script recognize if we are dealing with a 1D or 2D FES (don't ask for 3D please, such an headache
  ### for 2D...) and stored values for min and max in 2 variables.
 
  while {[gets $infile line] > -1} {
    if {[regexp {FIELD\S+} $line]} {
      lappend name [lindex $line 2]
      lappend name [lindex $line 3]
    }
    if {[regexp {nbins_\S+} $line]} {
      lappend pixels [lindex $line 3]
    }
    if {[regexp {min_\S+} $line]} {
      if {[lindex $line 3]=="-pi"} {
        lappend set_of_values -3.141592654
      } else {
        lappend set_of_values [lindex $line 3]
      }
    }
    if {[regexp {max_\S+} $line]} {
      if {[lindex $line 3]=="pi"} {
        lappend set_of_values 3.141592654
      } else {
        lappend set_of_values [lindex $line 3]
      }
    }
    if {![regexp {#!} $line] && $line!=""} {
      set position [regexp -all {\w+} $pixels]
      if {[lindex $line $position] <= $lower_limit} {                    
        set lower_limit [lindex $line $position]
      }
      if {[lindex $line $position] >= $upper_limit} {
        set upper_limit [lindex $line $position]
      }
    }
  }
  lappend set_of_values $lower_limit
  lappend set_of_values $upper_limit

  ### Once stored the values in pixels, I confront them with width and height of the canvas to see if 
  ### dimensions are enough. In case, the program updates these values.

  if {[expr {[winfo width $w.fes.graph.canvas]}]<[lindex $pixels 0]} {
    lappend const 0
    $w.fes.graph.canvas configure -width [lindex $pixels 0]
    $w.fes.x.canvas configure -width [lindex $pixels 0]
    puts "The width of the uploaded fes exceeds the default width and it has been updated accordingly."
  } else {
    lappend const [expr int(([winfo width $w.fes.graph.canvas])/[lindex $pixels 0]+1.0)]
    $w.fes.graph.canvas configure -width [expr {[lindex $pixels 0]*[lindex $const 0]}]
    $w.fes.x.canvas configure -width [expr {[lindex $pixels 0]*[lindex $const 0]}]
    puts "The width of the uploaded fes does not exceed the default width, thus the width has been broadened by a factor of [lindex $const 0]."
  }
  if {[regexp -all {\w+} $pixels]==2} {
    if {[expr {[winfo height $w.fes.graph.canvas]}]<[lindex $pixels 1]} {
      lappend const 0
      $w.fes.graph.canvas configure -height [lindex $pixels 1]
      $w.fes.y.canvas configure -height [lindex $pixels 1]
      puts "The height of the uploaded fes exceeds the default height and it has been updated accordingly."
    } else {
      lappend const [expr int(([winfo height $w.fes.graph.canvas])/[lindex $pixels 1]+1.0)]
      $w.fes.graph.canvas configure -height [expr {[lindex $pixels 1]*[lindex $const 1]}]
      $w.fes.y.canvas configure -height [expr {[lindex $pixels 1]*[lindex $const 1]}]
      puts "The height of the uploaded fes does not exceed the default height, thus the height has been broadened by a factor of [lindex $const 1]."
    }
  }
  set dimensions [regexp -all {\w+} $pixels]
  puts "The uploaded FES has $dimensions dimensions."
  set borders $set_of_values
  draw_axis 1 [lindex $name 0]
  draw_axis 2 [lindex $name 1]
	
  unset set_of_values
  close $infile
}

## Create the x and y axis to plot the FES
proc FFS::draw_axis {pos name} {
  variable w
  variable borders
  variable dimensions
  set counter 0
  update idletasks
  if {$pos == 1} {
    $w.fes.x.canvas create line 0 0 [expr {[winfo width $w.fes.x.canvas]-1}] 0 -fill black
    for {set i 0} {$i <= 10} {incr i} {
      $w.fes.x.canvas create line [expr int(([winfo width $w.fes.x.canvas]-1)/10*$i)] 0 [expr int(([winfo width $w.fes.x.canvas]-1)/10*$i)] 5 -fill black
      if {$i == 0} {
        $w.fes.x.canvas create text 15 15 -text [format "%.2f" [expr {[lindex $borders 0] + (([lindex $borders 1]-[lindex $borders 0])/10)*$i}]]
      } elseif {$i == 10} {
        $w.fes.x.canvas create text [expr {[winfo width $w.fes.x.canvas]-16}] 15 -text [format "%.2f" [expr {[lindex $borders 0] + (([lindex $borders 1]-[lindex $borders 0])/10)*$i}]]
      } else {
        $w.fes.x.canvas create text [expr {[winfo width $w.fes.x.canvas]/10*$i}] 25 -text [format "%.2f" [expr {[lindex $borders 0] + (([lindex $borders 1]-[lindex $borders 0])/10)*$i}]]
      }
    }
    $w.fes.x.canvas create text [expr {[winfo width $w.fes.x.canvas]/2}] [expr {[winfo height $w.fes.x.canvas]-10}] -text $name
  } else {
    $w.fes.y.canvas create line [expr {[winfo width $w.fes.y.canvas]-1}] 0 [expr {[winfo width $w.fes.y.canvas]-1}] [expr {[winfo height $w.fes.y.canvas]-1}] -fill black
    for {set j 0} {$j <= 10} {incr j} {
      $w.fes.y.canvas create line [expr {[winfo width $w.fes.y.canvas]-1}] [expr {[winfo height $w.fes.y.canvas]-1-(([winfo height $w.fes.y.canvas]-1)/10*$j)}] [expr {[winfo width $w.fes.y.canvas]-6}] [expr {[winfo height $w.fes.y.canvas]-1-(([winfo height $w.fes.y.canvas]-1)/10*$j)}] -fill black
      if {$j == 0} {
        $w.fes.y.canvas create text [expr {[winfo width $w.fes.y.canvas]-31}] [expr {[winfo height $w.fes.y.canvas]-11}] -text [format "%.2f" [expr {[lindex $borders 2] + (([lindex $borders 3]-[lindex $borders 2])/10)*$j}]]
      } elseif {$j == 10} {
        $w.fes.y.canvas create text [expr {[winfo width $w.fes.y.canvas]-31}] 10 -text [format "%.2f" [expr {[lindex $borders 2] + (([lindex $borders 3]-[lindex $borders 2])/10)*$j}]]
      } else {
        $w.fes.y.canvas create text [expr {[winfo width $w.fes.y.canvas]-31}] [expr {[winfo height $w.fes.y.canvas]-1-(([winfo height $w.fes.y.canvas]-1)/10*$j)}] -text [format "%.2f" [expr {[lindex $borders 2] + (([lindex $borders 3]-[lindex $borders 2])/10)*$j}]]
      }
    }
    if {$dimensions == 2} {
      $w.fes.y.canvas create text 65 [expr {[winfo height $w.fes.y.canvas]/2}] -text $name
    } else {
      $w.fes.y.canvas create text 65 [expr {[winfo height $w.fes.y.canvas]/2}] -text "FES" -tag titletag
    }
  }
  unset counter
}

## Start the selection in the canvas
proc FFS::canvas_select_start {x y} {
  variable w
  variable Canvas
  update idletasks
  $w.fes.graph.canvas create rectangle $x $y $x $y -width 1 -tags selRect
  set Canvas $x
  lappend Canvas $y
}

## Expand the selection in the canvas
proc FFS::canvas_select_expand {x y} {
  variable Canvas
  variable w
  $w.fes.graph.canvas coords selRect [lindex $Canvas 0] [lindex $Canvas 1] $x $y
}

## Finalize the selection in the canvas, and initialize the process of extraction
proc FFS::canvas_select_end {x y} {
  variable borders
  variable Canvas
  variable w
  array set boh [list x_min [expr {[winfo width $w.fes.graph.canvas]}] x_max 0 y_min [expr {[winfo height $w.fes.graph.canvas]}] y_max 0]
  canvas_select_expand $x $y
  set id [$w.fes.graph.canvas find withtag selRect]
  $w.fes.graph.canvas itemconfigure selRect -outline gray
##  $w.fes.graph.canvas dtag selRect
  set selection [$w.fes.graph.canvas find overlapping [lindex $Canvas 0] [lindex $Canvas 1] $x $y]
  foreach item $selection {
    set type [$w.fes.graph.canvas type $item]
    if {$item != $id && $type == "rectangle"} {
      if {[lindex [$w.fes.graph.canvas coords $item] 0] < $boh(x_min)} {
        set boh(x_min) [lindex [$w.fes.graph.canvas coords $item] 0]
      }
      if {[lindex [$w.fes.graph.canvas coords $item] 0] > $boh(x_max)} {
        set boh(x_max) [lindex [$w.fes.graph.canvas coords $item] 0]
      }
      if {[lindex [$w.fes.graph.canvas coords $item] 1] < $boh(y_min)} {
        set boh(y_min) [lindex [$w.fes.graph.canvas coords $item] 1]
      }
      if {[lindex [$w.fes.graph.canvas coords $item] 1] > $boh(y_max)} {
        set boh(y_max) [lindex [$w.fes.graph.canvas coords $item] 1]
      }
#             $w.fes.graph.canvas itemconfigure $item -outline red
    }
  }
  find_it_bobby [expr {($boh(x_min)/([winfo width $w.fes.graph.canvas]))*([lindex $borders 1]-[lindex $borders 0])+[lindex $borders 0]}] \
   [expr {($boh(x_max)/([winfo width $w.fes.graph.canvas]))*([lindex $borders 1]-[lindex $borders 0])+[lindex $borders 0]}] \
   [expr {([winfo height $w.fes.graph.canvas]-$boh(y_max))/([winfo height $w.fes.graph.canvas])*([lindex $borders 3]-[lindex $borders 2])+[lindex $borders 2]}] \
   [expr {([winfo height $w.fes.graph.canvas]-$boh(y_min))/([winfo height $w.fes.graph.canvas])*([lindex $borders 3]-[lindex $borders 2])+[lindex $borders 2]}]
   $w.fes.graph.canvas delete selRect
}

## Program to extract the correct frames from a simulation
proc FFS::find_it_bobby {x_min x_max y_min y_max} {
  variable w
  variable dimensions
  variable output
  if {[FFS::isnumeric $x_min]==0 && [FFS::isnumeric $x_max]==0 && [FFS::isnumeric $y_min]==0 && [FFS::isnumeric $y_max]==0} {
#  set progress "0"
  set selected ""
  control_colvar
  variable difference
  cd $output
  set infile [open "COLVAR"]
  seek $infile 0
  set counter 1
  while {[gets $infile line] > -1} {
    if {![regexp {#!} $line] && [lindex $line 0] != 0.000000} {
      if {$x_min <= [lindex $line 1] &&\
	  $x_max >= [lindex $line 1]} {
        if {$dimensions == 2} {
	  if {$y_min <= [lindex $line 2] &&\
	      $y_max >= [lindex $line 2]} {
	    lappend selected $counter
	  }
        } else {
          lappend selected $counter
        }
      }
      incr counter
    }
  }
  set answer [tk_messageBox -message "I am going to write [llength $selected] frames. It might be time consuming. Proceed?" -icon question -type yesno]
  switch -- $answer {
    yes {if {![file exists selected_structures]} {
           file mkdir selected_structures
        }
#	set progress 0
#	set progressbar [toplevel ".ffs"]
#	wm title $progressbar "Please wait"
#	wm resizable $progressbar 0 0
#	pack [ttk::progressbar $progressbar -orient horizontal -mode determinate -maximum 100 -variable [expr {$progress*100}]]
        cd selected_structures
#	set counter_2 0
        foreach item $selected {
#	  incr counter_2 1
          set sel [atomselect top all frame [expr {$item+$difference}]]
          $sel writepdb frame_[expr {$item+$difference}].pdb
#	  set progress [expr{$counter/[llength $selected]}]
#	  update
        }
#	destroy $progressbar
	set filename "extraction.log"
	set fileId [open $filename "w"]
	if {$dimensions==2} {
	  puts $fileId "This file has been created after extracting structure from interval [format "%.6f" $x_min] - [format "%.6f" $x_max] and [format "%.6f" $y_min] - [format "%.6f" $y_max]"
	} else {
	  puts $fileId "This file has been created after extracting structure from interval [format "%.6f" $x_min] - [format "%.6f" $x_max]"
	}
	puts $fileId "Times in COLVAR are: $selected"
	set temp ""
	set temp2 ""
	foreach item2 $selected {
	  lappend temp [expr $item2 + $difference]
	  lappend temp2 "frame_[expr $item2 + $difference].pdb"
	}
	puts $fileId "Frames in simulation are: $temp"
#	puts [exec /bin/sh -c "cat [join $temp2] > multi.pdb"]
#	exec /bin/sh -c "rm frame_*"
	close $fileId
	unset selected
	unset temp
	unset temp2
        close $infile
        }
    no {puts "Process interrupted"}
  }
  } else {
    tk_messageBox -message "One value is not a number." -type ok -icon error
  }
}

## Program to extract the correct frames from a simulation
proc FFS::calculate {x_min x_max y_min y_max wref rcyl} {
  variable w
  variable kT
#  puts $kT
  set pseudodimensions ""
  set infile [open [file normalize [tk_getOpenFile]]]
#  puts $infile
  seek $infile 0
  set kb 0
  set bin ""
  set min ""
  set max ""
  set ref 0
  set dr ""
	
#  set aux [split [read $infile] "\n"]
#  set bin1 [lindex [lindex $aux 19] 0] 
#  set bin2 [lindex [lindex $aux 20] 0]
#  set dr [expr ($bin2 - $bin1)]
#  puts $dr	
#  seek $infile 0 start
#  while {[gets $infile line] > -1} {
#    if {[lindex $line 0] >= $wref && [lindex $line 0] <= [expr ($wref + $dr)]} {
#      set ref [lindex $line 1]
#	    puts $ref
#    }
#  }
	
  while {[gets $infile line] > -1} {
    if {[regexp {nbins_\S+} $line]} {
      lappend bin [lindex $line 3]
    }
    if {[regexp {min_\S+} $line]} {
      if {[lindex $line 3]=="-pi"} {
        lappend min -3.141592654
      } else {
        lappend min [lindex $line 3]
      }
    }
    if {[regexp {max_\S+} $line]} {
      if {[lindex $line 3]=="pi"} {
        lappend max 3.141592654
      } else {
        lappend max [lindex $line 3]
      }
    }
  }
  if {[llength $bin]==2} {
     set pseudodimensions 2
  } else {
     set pseudodimensions 1
  }
#  ##### DEBUG ######
#  puts $min
#  puts $max
#  puts $bin
#  ##################
  set dr [expr {([lindex $max 0] - [lindex $min 0]) / [lindex $bin 0]}]
  if {$pseudodimensions == 2} {
    lappend dr [expr {([lindex $max 1] - [lindex $min 1]) / [lindex $bin 1]}]
  }
  seek $infile 0 start 
  set counter 0
  while {[gets $infile line] > -1} {
    if {![regexp {#!} $line]} {
      if {[lindex $line 0] >= $wref && [lindex $line 0] <= [expr ($wref + [lindex $dr 0])]} {
	if {$pseudodimensions == 2} {
#	  puts [lindex $line 2]
	  set ref [expr {$ref + [lindex $line 2]}]
	  incr counter
	} else {
	  set ref [lindex $line 1]
	}
      }    
    }
  }
  if {$pseudodimensions==2} {
    set ref [expr {$ref / $counter}]
  }
#  puts $counter
  unset counter
  ######## DEBUG #########
  puts "Calculate reference value is $ref kJ/mol"
  ########################
	
  seek $infile 0 start
  while {[gets $infile line] > -1} {
    if {![regexp {#!} $line]} {
      if {$x_min <= [lindex $line 0] &&\
	  $x_max >= [lindex $line 0] &&\
	  [lindex $line 1] ne "Infinity"} {
	if {$pseudodimensions == 2} {
	  if {$y_min <= [lindex $line 1] &&\
              $y_max >= [lindex $line 1] &&\
              [lindex $line 2] ne "Infinity"} {
	    set kb [expr {$kb + exp(-([lindex $line 2] - $ref) / $kT) * [lindex $dr 0] * [lindex $dr 1]}]
	   # puts $kb
	  }
	} else {
	  set kb [expr {$kb + exp(-([lindex $line 1] - $ref) / $kT) * [lindex $dr 0]}]
	  # puts $kb
	}
      }
    }
  }
  $w.plumed.dg.l configure -text "[format "%.2f" [expr (-$kT * log($kb * 3.1416 * $rcyl * $rcyl * 0.6020) / 4.187)]] kcal/mol"
#  unset aux
  unset pseudodimensions
  unset bin
  unset min
  unset max
  unset ref
  unset kb
  unset dr
  close $infile
}

proc FFS::control_colvar {} {
  variable output
  variable difference
  cd $output
  set infile [open "COLVAR"]
  seek $infile 0
  set numframes [molinfo top get numframes]
  set counter 0
  while {[gets $infile line] > -1} {
    if {![regexp {#!} $line]} {
      incr counter
    }
  }
  if {$counter!=$numframes} {
    set difference [expr {$numframes-$counter}]
  } else {
    set difference 0
  }
  unset numframes
  unset counter
  close $infile
}

proc FFS::il_pianto_paga {args} {
  global vmd_frame
  FFS::update_position
}

proc FFS::print_PostScript {} {
  variable w
  variable Canvas
  $w.fes.graph.canvas postscript -file prova.ps
}

proc FFS::reset {} {
  variable w
  variable Canvas
  $w.fes.graph.canvas delete x
  $w.fes.graph.canvas delete y
}

proc ffs_tk {} {
  FFS::ffs
  return $FFS::w
}

proc FFS::nuke { args } {
  global vmd_frame
  variable w
  variable Canvas
	
  variable kT
	
  FFS::not_so_nuke
	
  trace vdelete vmd_frame([molinfo top]) w FFS::il_pianto_paga
}

proc FFS::isnumeric value {
     return [catch {expr {abs($value)}}]
}

proc FFS::not_so_nuke { args } {
  variable w
  variable Canvas	

  variable kT
	
  $w.plumed.dir.l configure -text "No file"
  $w.plumed.dat.l configure -text "No file"
  $w.plumed.trj.l configure -text "No file"
  $w.plumed.dyn.m configure -text ""
  $w.plumed.hills.l configure -text "No file"
  $w.plumed.mtz.m configure -text ""
  set kT 2.5
  $w.plumed.out.l configure -text "No folder"
  $w.plumed.mm.x.e1 configure -text ""
  $w.plumed.mm.x.e2 configure -text ""
  $w.plumed.mm.y.e3 configure -text ""
  $w.plumed.mm.y.e4 configure -text ""
  $w.plumed.dg.wref.e configure -text ""
  $w.plumed.dg.rcyl.e configure -text "0.1"
  $w.plumed.dg.l configure -text ""
  $w.fes.graph.canvas delete all
  $w.fes.x.canvas delete all
  $w.fes.y.canvas delete all
  $w.fes.graph.canvas configure -width 500
  $w.fes.x.canvas configure -width 500
  $w.fes.graph.canvas configure -height 500
  $w.fes.y.canvas configure -height 500
  update idletasks
  $w.fes.info.frame configure -text ""
  $w.fes.info.cv1 configure -text ""
  $w.fes.info.cv2 configure -text ""
  $w.fes.info.fes configure -text ""
  $w.plumed.settings.e2 configure -text ""
  $w.plumed.run3.e configure -text ""
}

proc FFS::dg { x_min x_max y_min y_max wref rcyl fes } {
  variable w
  variable kT

  set infile [open [file normalize $fes]]
  set pseudodimensions ""
  set kb 0
  set bin ""
  set min ""
  set max ""
  set ref 0
  set dr ""
	
  seek $infile 0
  while {[gets $infile line] > -1} {
    if {[regexp {nbins_\S+} $line]} {
      lappend bin [lindex $line 3]
    }
    if {[regexp {min_\S+} $line]} {
      if {[lindex $line 3]=="-pi"} {
	lappend min -3.141592654
      } else {
	lappend min [lindex $line 3]
      }
    }
    if {[regexp {max_\S+} $line]} {
      if {[lindex $line 3]=="pi"} {
	lappend max 3.141592654
      } else {
	lappend max [lindex $line 3]
      }
    }
  }
  if {[llength $bin]==2} {
     set pseudodimensions 2
  } else {
     set pseudodimensions 1
  }
  
  set dr [expr {([lindex $max 0] - [lindex $min 0]) / [lindex $bin 0]}]
  if {$pseudodimensions == 2} {
    lappend dr [expr {([lindex $max 1] - [lindex $min 1]) / [lindex $bin 1]}]
  }
  seek $infile 0 start 
  set counter 0
  while {[gets $infile line] > -1} {
    if {![regexp {#!} $line]} {
      if {[lindex $line 0] >= $wref && [lindex $line 0] <= [expr ($wref + [lindex $dr 0])]} {
	if {$pseudodimensions == 2} {
#	  puts [lindex $line 2]
	  set ref [expr {$ref + [lindex $line 2]}]
	  incr counter
	} else {
	  set ref [lindex $line 1]
	}
      }    
    }
  }
  if {$pseudodimensions==2} {
    set ref [expr {$ref / $counter}]
  }
  unset counter
	
  seek $infile 0 start
  while {[gets $infile line] > -1} {
    if {![regexp {#!} $line]} {
      if {$x_min <= [lindex $line 0] &&\
	  $x_max >= [lindex $line 0] &&\
	  [lindex $line 1] ne "Infinity"} {
	if {$pseudodimensions == 2} {
	  if {$y_min <= [lindex $line 1] &&\
	      $y_max >= [lindex $line 1] &&\
	      [lindex $line 2] ne "Infinity"} {
	    set kb [expr {$kb + exp(-([lindex $line 2] - $ref) / $kT) * [lindex $dr 0] * [lindex $dr 1]}]
	   # puts $kb
	  }
	} else {
	  set kb [expr {$kb + exp(-([lindex $line 1] - $ref) / $kT) * [lindex $dr 0]}]
	  # puts $kb
	}
      }
    }
  }
#  unset aux
  unset pseudodimensions
  unset bin
  unset min
  unset max
  unset ref
  unset dr
  close $infile
  return [expr (-$kT * log($kb * 3.1416 * $rcyl * $rcyl * 0.6020))]
}

proc FFS::convergence { args } {
  variable w
  variable output
  
  set table_x 0
  set table_y 0
  set destination [open $output/deltaG.txt w]
  set reject [$w.plumed.settings.e2 get]

## headers for file
  puts -nonewline $destination "#! Num. fes"
  puts -nonewline $destination "   DeltaG"
  puts -nonewline $destination "   Mean_otf"
  puts $destination "   Std_error"
	
  for {set i 1} {$i < [llength [glob -type f $output/fes_*.dat]]} {incr i} {
    lappend table_x $i
    lappend table_y [FFS::dg [$w.plumed.mm.x.e1 get] [$w.plumed.mm.x.e2 get] [$w.plumed.mm.y.e3 get] [$w.plumed.mm.y.e4 get] [$w.plumed.dg.wref.e get] [$w.plumed.dg.rcyl.e get] $output/fes_$i.dat]
  }
  ## DEBUG
#  puts $table_x
#  puts $table_y
  ########
  set tot1 0
  set tot2 0
  set tot3 0
  set mean 0
  set std 0
  
  set min 0
  set max 0

  puts -nonewline $destination [lindex $table_x 0]
  puts $destination "   [lindex $table_y 0]"
  for {set j 1} {$j < [llength $table_x]} {incr j} {
    puts -nonewline $destination [lindex $table_x $j]
    if {$j > $reject} {
      puts -nonewline $destination "   [lindex $table_y $j]"
      set tot1 [expr ($tot1 + ([lindex $table_x $j] - $reject) * [lindex $table_y $j])]
      set tot2 [expr ($tot2 + ([lindex $table_x $j] - $reject))]
      set mean [expr ($tot1/$tot2)]
      puts -nonewline $destination "   $mean"
      set tot3 [expr ($tot3 + ([lindex $table_x $j] - $reject) * ([lindex $table_y $j] - $mean) * ([lindex $table_y $j] - $mean))]
      set std [expr (sqrt($tot3/$tot2))]
      puts $destination "   $std"
    } else {
      puts $destination "   [lindex $table_y $j]"
    }
    if {[lindex $table_y $j] < $min} {
      set min [lindex $table_y $j]
    } elseif {[lindex $table_y $j] > $max} {
      set max [lindex $table_y $j]
    } 

  }
	
  FFS::draw_deltaG $table_x $table_y $min $max

  puts "#############################################################"
  puts "Average-on-the-fly:      [expr ([lindex $mean end] / 4.187)] kcal/mol"
  puts "with standard deviation: [expr ([lindex $std end] / 4.187)] kcal/mol"
  puts "#############################################################"

##  set check ""

  # Very rough estimation of the goodness of the deltaG
##  if {[lindex $std end] < 8.374 && [lindex $std end] < [expr (abs([lindex $mean end]) / 10)]} {
##    $w.plumed.convergence.b2 configure -background "\#228B22"
##  } else {
##    $w.plumed.convergence.b2 configure -background "\#ED2939"
##  }
	  
  unset tot1
  unset tot2
  unset tot3
  unset mean
  unset std
  unset table_x
  unset table_y
  unset reject
##  unset check
  close $destination
}

proc FFS::bootstrap { table_y reject number_blocks block number_points} {
  variable output
	
  set averages ""
  set av 0
  set div_av 0
  set std 0
  set weight ""
  set destination ""
  if {$block == 0} {
    set destination [open $output/bootstrap.txt w]
  } else {
    set destination [open $output/bootstrap.txt a]
  }
	
  for {set j 1} {$j <= 1000} {incr j} {
    set table_boot ""
    set average_boot 0
	  
    ######## This is necessary for weighted bootstrap
    set div 0
    #################################################  

    for {set i 0} {$i < $number_points} {incr i} {
      set random_number [expr (round(rand()*$number_points + (([llength $table_y] - $reject) * $block / $number_blocks - 1) + $reject))]
###      puts $random_number
      lappend table_boot [lindex $table_y $random_number]
      set average_boot [expr ($average_boot + [lindex $table_boot $i] * ($random_number + 1 - $reject))]
######      set average_boot [expr ($average_boot + [lindex $table_boot $i])]
      set div [expr ($div + $random_number + 1 - $reject)]
    }
    lappend averages [expr ($average_boot / $div)]
######    lappend averages [expr ($average_boot / 50)]
    lappend weight $div
  }
  puts $destination $averages
  for {set n 0} {$n < 1000} {incr n} {
    set av [expr ($av + ([lindex $weight $n] * [lindex $averages $n]))]
    set div_av [expr ($div_av + [lindex $weight $n])]
######    set av [expr ($av + [lindex $averages $n])]
  }
######   set av [expr ($av / 1000)]
  set av [expr ($av / $div_av)]
### DEBUG
  puts "#############################################################"
  puts "Bootstrap average for block $block is: [expr ($av / 4.187)] kcal/mol"

  for {set m 0} {$m < 1000} {incr m} {
    set std [expr ($std + ([lindex $averages $m] - $av) * ([lindex $averages $m] - $av))]
#########    set std [expr ($std + [lindex $weight $m] * ([lindex $averages $m] - $av) * ([lindex $averages $m] - $av))]
  }  
  set std [expr (sqrt ($std / 1000))]
#########  set std [expr (sqrt ($std / 1000) * sqrt([llength $table_y] - $reject))]
### DEBUG
  puts "with standard error:  [expr ($std / 4.187)] kcal/mol"
  puts "#############################################################"
  
  unset averages
  unset div_av
  unset weight
  close $destination
  return $av $std
}

proc FFS::histo_it { averages } {
  variable z
  set min {9999 9999 9999 9999 9999 9999 9999 9999 9999 9999}
  set max {-9999 -9999 -9999 -9999 -9999 -9999 -9999 -9999 -9999 -9999}
	
  for {set x 0} {$x < 10} {incr x} {
    for {set i 0} {$i < 1000} {incr i} {
      if {[lindex [lindex $averages $x] $i] < [lindex $min $x]} {
        lset min $x [lindex [lindex $averages $x] $i]
      }
      if {[lindex [lindex $averages $x] $i] > [lindex $max $x]} {
        lset max $x [lindex [lindex $averages $x] $i]
      } 
    }
  }
##  puts $min
##  puts $max
  ## There is a problem with max, it has to be 6.999999 in order to be plotted
  for {set y 0} {$y < 10} {incr y} {
    lset max $y [expr ([lindex $max $y] + 0.001)]
  }
	
  if { [winfo exists .bootstrap] } {
    wm deiconify $z
    $z.histo.graph.canvas delete all
  } else {
    set z [toplevel ".bootstrap"]
    wm resizable $z 0 0
    frame $z.histo -width 1075 -height 405
    fescanvas $z.histo.graph -height 405 -width 1075 
    pack $z.histo.graph
    pack $z.histo
  }
  for {set aaa 0} {$aaa < 10} {incr aaa} {
    set width 0
    set width [expr (([lindex $max $aaa] - [lindex $min $aaa]) / 21)]
##    puts $width
    set pop {0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0}  

    for {set j 0} {$j < [llength [lindex $averages $aaa]]} {incr j} {
      set where [expr int(abs([lindex [lindex $averages $aaa] $j] - [lindex $min $aaa]) / $width)]
      lset pop $where [expr ([lindex $pop $where] + 1)]
    }
##    puts $pop

    set max_height 0
    for {set h 0} {$h < 21} {incr h} {
      if {[lindex $pop $h] > $max_height} {
        set max_height [lindex $pop $h]
      }
    }
##    puts $max_height
    set div [expr (double(200.0 / $max_height))]
##    puts $div
	
    if {$aaa < 5} {
      $z.histo.graph.canvas create text [expr (215 * $aaa + 15)] 15 -text "$aaa"
    } else {
      $z.histo.graph.canvas create text [expr (215 * ($aaa - 5) + 15)] 220 -text "$aaa"
    }
	 
    for {set xxx 0} {$xxx < 21} {incr xxx} {
      if {$aaa < 5} {
	$z.histo.graph.canvas create rectangle [expr ($xxx * 10 + 215 * $aaa)]  [expr (200 - round([lindex $pop $xxx] * $div))] [expr (($xxx + 1) * 10 + 215 * $aaa)] 200 -fill "\#50C878" -outline ""
      } else {
	$z.histo.graph.canvas create rectangle [expr ($xxx * 10 + 215 * ($aaa - 5))]  [expr (405 - round([lindex $pop $xxx] * $div))] [expr (($xxx + 1) * 10 + 215 * ($aaa - 5))] 405 -fill "\#50C878" -outline ""
      }      
    }
  }
	  
  unset min
  unset max
  unset width
  unset max_height
  unset div
}

###proc FFS::check { args } {
###  variable w
###	
###  puts [$w.plumed.convergence.b2 cget -background]
###  if {[$w.plumed.convergence.b2 cget -background] == "#228B22"} {
###    tk_messageBox -type ok -icon info -title "Converged!" -message "Your simulation seems to be converged or close to convergence."
###  } elseif {[$w.plumed.convergence.b2 cget -background] == "#ED2939"} {
###    tk_messageBox -type ok -icon info -title "Not yet..." -message "Your simulation has not converged."
###  } else {
###    tk_messageBox -type ok -icon warning -title "" -message "No convergence estimate has been run. Please click the button on my left beforehand."
###  }
### 
###}

proc FFS::draw_deltaG { x y min max } {
  variable w	
  variable dimensions
  variable borders
  variable const	

  set pixels [llength $x]
  set dimensions 1
  set const ""
  set set_of_values ""
  set coords ""

  $w.fes.graph.canvas delete all
  $w.fes.x.canvas delete all
  $w.fes.y.canvas delete all
  $w.fes.graph.canvas configure -width 500
  $w.fes.x.canvas configure -width 500
  $w.fes.graph.canvas configure -height 500
  $w.fes.y.canvas configure -height 500
  update idletasks

  lappend set_of_values 0
  lappend set_of_values [expr ([llength $x] -1)]
  lappend set_of_values $min
  lappend set_of_values $max

  if {[expr {[winfo width $w.fes.graph.canvas]}]<[lindex $pixels 0]} {
    lappend const 0
    $w.fes.graph.canvas configure -width [lindex $pixels 0]
    $w.fes.x.canvas configure -width [lindex $pixels 0]
    puts "The width of the uploaded fes exceeds the default width and it has been updated accordingly."
  } else {
    lappend const [expr int(([winfo width $w.fes.graph.canvas])/[lindex $pixels 0]+1.0)]
    $w.fes.graph.canvas configure -width [expr {[lindex $pixels 0]*[lindex $const 0]}]
    $w.fes.x.canvas configure -width [expr {[lindex $pixels 0]*[lindex $const 0]}]
    puts "The width of the uploaded fes does not exceed the default width, thus the width has been broadened by a factor of [lindex $const 0]."
  }

  set borders $set_of_values
  draw_axis 1 "fes number"
  draw_axis 2 "deltaG"
  $w.fes.y.canvas itemconfigure titletag -text "deltaG"

  for {set j 0} {$j < [llength $x]} {incr j} {
    lappend coords [expr int((double([lindex $x $j])-[lindex $borders 0])/([lindex $borders 1]-[lindex $borders 0])*([winfo width $w.fes.graph.canvas]-1))] [expr int(([winfo height $w.fes.graph.canvas]-1)-(([lindex $y $j]-[lindex $borders 2])/([lindex $borders 3]-[lindex $borders 2]))*([winfo height $w.fes.graph.canvas]-1))]
  }
  for {set i 0} {$i < [expr {[regexp -all {\w+} $coords]/2}]} {incr i} {
    $w.fes.graph.canvas create rectangle [lindex $coords [expr {$i*2}]] [lindex $coords [expr {$i*2+1}]] [lindex $coords [expr {$i*2}]] [lindex $coords [expr {$i*2+1}]] -width 1
  }
  $w.fes.graph.canvas create line $coords -smooth true
	
  unset set_of_values	
  unset coords
}

proc FFS::apply_bootstrap { reject } {
  variable output

  set number_blocks 10
  set table_x ""
  set table_y ""
  set averages ""
  set infile [open [file normalize $output/deltaG.txt]]
###  set infile2 [open [file normalize $output/bootstrap.txt]]
  seek $infile 0
  while {[gets $infile line] > -1} {
    if {![regexp {#!} $line]} {
      lappend table_x [lindex $line 0]
      lappend table_y [lindex $line 1]
    }
  }
	
  if {[expr (([llength $table_y] - $reject) / $number_blocks)] < 50} {
    tk_messageBox -message "You have too few points to perform block bootstrap analysis. Please consider reducing the stride." -type ok -icon error
  } else {
    set number_points [expr (round(([llength $table_y] - $reject) / $number_blocks))]
    for {set h 0} {$h < $number_blocks} {incr h} {
      puts [FFS::bootstrap $table_y [expr ($reject + ([llength $table_y] - $reject) - ($number_blocks * $number_points))] $number_blocks $h $number_points]	    
    }
    set infile2 [open [file normalize $output/bootstrap.txt]]
    seek $infile2 0
    while {[gets $infile2 line] > -1} {
      lappend averages $line
    }
  
    FFS::histo_it $averages
  }	

  unset averages
  unset table_x
  unset table_y
  unset number_blocks	
  close $infile
  close $infile2
}