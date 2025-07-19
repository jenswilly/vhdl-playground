# Vivado TCL Script for Project Creation
# This script creates a Vivado project and adds sources from src/, constraints/, and sim/ directories

# Set project variables
set project_name "testbench1"
set project_dir [pwd]
set part "xc7s50csga324-1"

# Create project
puts "Creating Vivado project: $project_name"
create_project $project_name $project_dir -part $part -force

# Function to add files from a directory if it exists and contains files
proc add_files_from_dir {dir file_types fileset_name} {
    if {[file exists $dir] && [file isdirectory $dir]} {
        set files [glob -nocomplain -directory "$dir" "*.$file_types"]
        puts "Searching for $file_types files in $dir..."
        if {[llength $files] > 0} {
            puts "Adding files from $dir to $fileset_name:"
            foreach file $files {
                puts "  - [file tail $file]"
            }
            add_files -fileset $fileset_name $files
        } else {
            puts "No $file_types files found in $dir"
        }
    } else {
        puts "Directory $dir does not exist"
    }
}

# Add source files (VHDL, Verilog, SystemVerilog)
puts "\n--- Adding Design Sources ---"
add_files_from_dir "$project_dir/src" "{vhd,vhdl,v,sv}" "sources_1"

# Add constraint files
puts "\n--- Adding Constraint Files ---"
if {[file exists "./constraints"] && [file isdirectory "./constraints"]} {
    set constraint_files [glob -nocomplain -directory "./constraints" "*.{xdc,tcl,sdc}"]
    if {[llength $constraint_files] > 0} {
        puts "Adding constraint files:"
        foreach file $constraint_files {
            puts "  - [file tail $file]"
        }
        add_files -fileset constrs_1 $constraint_files
    } else {
        puts "No constraint files found in ./constraints"
    }
} else {
    puts "Directory ./constraints does not exist"
}

# Add simulation files
puts "\n--- Adding Simulation Sources ---"
add_files_from_dir "./sim" "{vhd,vhdl,v,sv}" "sim_1"

# Set top module (will need to be specified manually or detected)
puts "\n--- Project Setup Complete ---"
puts "Project created successfully!"
puts "Note: You may need to set the top module manually using:"
puts "set_property top <top_module_name> [current_fileset]"

# Optional: Set simulation top if simulation files exist
puts "\nTo set simulation top module, use:"
puts "set_property top <testbench_name> [get_filesets sim_1]"

# Show project summary
puts "\n--- Project Summary ---"
puts "Project Name: [get_property NAME [current_project]]"
puts "Project Directory: [get_property DIRECTORY [current_project]]"
puts "Target Part: [get_property PART [current_project]]"

# List added files
puts "\nDesign Sources:"
set design_files [get_files -of_objects [get_filesets sources_1]]
if {[llength $design_files] > 0} {
    foreach file $design_files {
        puts "  - [file tail $file]"
    }
} else {
    puts "  No design sources added"
}

puts "\nConstraint Files:"
set constraint_files [get_files -of_objects [get_filesets constrs_1]]
if {[llength $constraint_files] > 0} {
    foreach file $constraint_files {
        puts "  - [file tail $file]"
    }
} else {
    puts "  No constraint files added"
}

puts "\nSimulation Sources:"
set sim_files [get_files -of_objects [get_filesets sim_1]]
if {[llength $sim_files] > 0} {
    foreach file $sim_files {
        puts "  - [file tail $file]"
    }
} else {
    puts "  No simulation sources added"
}

puts "\nProject setup complete! You can now open the project in Vivado GUI or continue with TCL commands."