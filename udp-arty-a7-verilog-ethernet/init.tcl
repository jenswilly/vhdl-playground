# Create project
create_project "udp-server-arty-a7" [pwd] -part "xc7a100tcsg324-1" -force
set_property board_part digilentinc.com:arty-a7-100:part0:1.1 [current_project]
set_property simulator_language VHDL [current_project]
set_property target_language VHDL [current_project]
set_property STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE true [get_runs impl_1]

# Add source files
puts "--- Adding Design Sources ---\n"
add_files -fileset sources_1 ./hdl/top_syn.vhd
add_files -fileset sources_1 ./hdl/reset.vhd
add_files -fileset sources_1 ./hdl/ethernet.vhd
set_property FILE_TYPE {VHDL 2008} [get_files *.vhd]
set_property used_in_simulation false [get_files top_syn.vhd]
update_compile_order -fileset sources_1

# Add IP sources
puts "--- Adding IP Sources ---\n"
add_files -fileset sources_1 ./third_party/fpga-cores-fc1001-mii/FC1001_MII.edn
#add_files -fileset sources_1 ./ip/fifo_0.xci
#catch { config_ip_cache -export [get_ips -all fifo_0] }
#export_ip_user_files -of_objects [get_files ./ip/fifo_0.xci] -no_script -sync -force -quiet
#generate_target {instantiation_template} [get_files ./ip/fifo_0.xci]
update_compile_order -fileset sources_1

# Add constraint files
puts "--- Adding Constraints Files ---\n"
add_files -fileset constrs_1 ./constraints/Arty-A7-100-Master.xdc

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
