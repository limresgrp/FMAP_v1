# FMAP_v1
Codes to use funnel-metadynamics and funnel-metadynamics automated protocol

Update 22/10/2020
- VMD version MacOS X Catalina: after extensive rework of VMD to allow running on newer OS, the graphical user interfaces might not work as intended. We suggest to use older versions of VMD if you wish to use funnel.tcl or ffs.tcl or wait for further updates.
- Gromacs 2020 series: option -multi has been substituted with -multidir, dividing parallel simulations in different folders. This causes FMAP to crash since the file for the Funnel potential (in the paper called "BIAS") will be written only in the first folder. A possible workaround is to copy that file in each folder and then launch again Funnel-Metadynamics or wait for an update of the code. 
