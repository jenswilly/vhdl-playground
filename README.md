# VHDL Playground

This project contains several subprojects for testing VHDL in Vivado.

### Create Project

In subdirectories, first source the Vivado settings script, then run `./init.sh` to create the Vivado project.

### Open Project

If the project's Vivado files have been created, run `./open.sh` to open Vivado and open the project.

### Clean

To clean all Vivado-generated files, run `./clean.sh`. After this, it should be possible to re-create 
the project.

-----

# Installing Required Parts and Boards

If, when running `init.sh`, an error about being unable to find a _part_ or a _board_ is shown, 
the relevant part (i.e. FPGA) or board should be installed. 

To install a specific FPGA, open Vivado and go to Help -> Add Design Tools or Devices... to 
open the installer and then select the relvant FPGA series under Devices.

To install a board, create a new Project and choose "RTL Project" and check "Do not specify sources
at this time". Then, on the Default Part page, go to the Boards tab, click the Refresh button
and then search for the board (e.g. "cmod"). Click the Install button next to the relevant board.

**Note:** it will probably be necessary to copy the board files from the "user board repo" to the
"system repo".  
The board will likely be installed to `~/.Xilinx/Vivado/2025.1/xhub/board_store/xilinx_board_store/XilinxBoardStore/Vivado/2025.1/boards/`
(or thereabouts). To copy to the "system repo", copy the contents of the user repo to 
`/tools/Xilinx/2025.1/data/xhub/boards/XilinxBoardStore/boards/` (adjust for versions etc.).

