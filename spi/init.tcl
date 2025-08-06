# Create project
create_project "spi_test" [pwd] -part "xc7a35tcpg236-1" -force
set_property board_part digilentinc.com:cmod_a7-35t:part0:1.2 [current_project]
set_property simulator_language VHDL [current_project]
set_property target_language VHDL [current_project]
set_property STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE true [get_runs impl_1]

# Add source files
puts "--- Adding Design Sources ---\n"
add_files -fileset sources_1 ./src/spi.vhdl
add_files -fileset sources_1 ./src/top.vhdl
set_property FILE_TYPE {VHDL 2008} [get_files *.vhdl]
set_property used_in_simulation false [get_files top.vhdl]
update_compile_order -fileset sources_1

# Add IP sources
puts "--- Adding IP Sources ---\n"
add_files -fileset sources_1 ./ip/fifo_0.xci
set_property used_in_simulation false [get_files fifo_0.xci]
catch { config_ip_cache -export [get_ips -all fifo_0] }
export_ip_user_files -of_objects [get_files ./ip/fifo_0.xci] -no_script -sync -force -quiet
generate_target {instantiation_template} [get_files ./ip/fifo_0.xci]
update_compile_order -fileset sources_1

# Add constraint files
puts "--- Adding Constraints Files ---\n"
add_files -fileset constrs_1 ./constraints/cmod-a7-master.xdc

# Add simulation files
puts "--- Adding Simulation Sources ---\n"
add_files -fileset sim_1 ./sim/testbench.vhdl
set_property FILE_TYPE {VHDL 2008} [get_files *.vhdl]
set_property -name {xsim.simulate.runtime} -value {3500ns} -objects [get_filesets sim_1]

puts "Project setup complete. Open project by running 'source open.sh'"
