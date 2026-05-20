# Create project
create_project "spi-uart-arty-a7" [pwd] -part "xc7a100tcsg324-1" -force
set_property board_part digilentinc.com:arty-a7-100:part0:1.1 [current_project]
set_property simulator_language VHDL [current_project]
set_property target_language VHDL [current_project]
set_property STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE true [get_runs impl_1]
set_property generic {BOARD_TYPE="arty-a7"} [current_fileset]

# Add source files
puts "--- Adding Design Sources ---\n"
add_files -fileset sources_1 \
    ./hdl/top.vhd \
    ./hdl/core.vhd \
    ./hdl/spi_axis.vhd \
    ./hdl/reset.vhd \
    ./hdl/debounce_switch.v \
    ./hdl/uart_tx.v
set_property FILE_TYPE {VHDL 2008} [get_files *.vhd]

add_files -fileset sources_1 \
    ./third_party/verilog-ethernet/lib/axis/rtl/axis_fifo.v

set_property top top [current_fileset]
update_compile_order -fileset sources_1

# set_property used_in_simulation false [get_files top_syn.vhd]

# Add constraint files
puts "--- Adding Constraints Files ---\n"
add_files -fileset constrs_1 \
    ./constraints/arty-a7-100t.xdc

# Add simulation files
puts "--- No Simulation Sources ---\n"
# puts "--- Adding Simulation Sources ---\n"
# add_files -fileset sim_1 ./sim/testbench.vhdl
# add_files -fileset sim_1 ./sim/testbench_behav.wcfg
# set_property FILE_TYPE {VHDL 2008} [get_files testbench.vhdl]
# set_property used_in_synthesis false [get_files testbench.vhdl]
# set_property xsim.view ./sim/testbench_behav.wcfg [get_filesets sim_1]
# set_property -name {xsim.simulate.runtime} -value {22us} -objects [get_filesets sim_1]

puts "Project setup complete. Open project by running './open.sh'"
