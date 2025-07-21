# Create project
create_project "rc-pwm" [pwd] -part "xc7s50csga324-1" -force

# Add source files
puts "--- Adding Design Sources ---\n"
add_files -fileset sources_1 ./src/pwm.vhdl
set_property FILE_TYPE {VHDL 2008} [get_files ./src/pwm.vhdl]

# Add constraint files
puts "--- Adding Constraint Files ---\n"
add_files -fileset constrs_1 ./constraints/arty_s7.xdc

# Add simulation files
puts "--- Adding Simulation Sources ---\n"
add_files -fileset sim_1 ./sim/testbench.vhdl
set_property FILE_TYPE {VHDL 2008} [get_files ./sim/testbench.vhdl]


puts "Project setup complete. Open project by running './open.sh'"