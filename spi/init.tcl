# Create project
create_project "spi_test" [pwd] -part "xc7a35tcpg236-1" -force
set_property board_part digilentinc.com:cmod_a7-35t:part0:1.2 [current_project]
set_property simulator_language VHDL [current_project]
set_property target_language VHDL [current_project]

# Add source files
puts "--- Adding Design Sources ---\n"
add_files -fileset sources_1 ./src/spi.vhdl
set_property FILE_TYPE {VHDL 2008} [get_files *.vhdl]

# Add constraint files
puts "--- Adding Constraints Files ---\n"
add_files -fileset constrs_1 ./constraints/cmod-a7-master.xdc

# Add simulation files
puts "--- Adding Simulation Sources ---\n"
add_files -fileset sim_1 ./sim/testbench.vhdl
set_property FILE_TYPE {VHDL 2008} [get_files *.vhdl]
set_property -name {xsim.simulate.runtime} -value {3500ns} -objects [get_filesets sim_1]


puts "Project setup complete. Open project by running 'source open.sh'"
