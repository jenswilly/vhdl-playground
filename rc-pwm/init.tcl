# Create project
create_project "rc-pwm" [pwd] -part "xc7s50csga324-1" -force
set_property board_part digilentinc.com:arty-s7-50:part0:1.1 [current_project]
set_property simulator_language VHDL [current_project]

# Get the directory where this script is located
set script_dir [file dirname [file normalize [info script]]]

# Add source files
puts "--- Adding Design Sources ---\n"
add_files -fileset sources_1 [file join $script_dir src top.vhdl]
add_files -fileset sources_1 [file join $script_dir src pwm.vhdl]
set_property FILE_TYPE {VHDL 2008} [get_files [file join $script_dir src *.vhdl]]

# Add constraint files
puts "--- Adding Constraint Files ---\n"
add_files -fileset constrs_1 [file join $script_dir constraints arty_s7.xdc]

# Add simulation files
puts "--- Adding Simulation Sources ---\n"
add_files -fileset sim_1 [file join $script_dir sim testbench.vhdl]
set_property FILE_TYPE {VHDL 2008} [get_files [file join $script_dir sim testbench.vhdl]]

puts "Project setup complete. Open project by running './open.sh'"