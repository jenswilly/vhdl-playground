# Create project
create_project "udp-arty-a7-verilog-ethernet" [pwd] -part "xc7a100tcsg324-1" -force
set_property board_part digilentinc.com:arty-a7-100:part0:1.1 [current_project]
set_property simulator_language VHDL [current_project]
set_property target_language VHDL [current_project]
set_property STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE true [get_runs impl_1]

# Add source files
puts "--- Adding Design Sources ---\n"
add_files -fileset sources_1 \
    ./third_party/verilog_ethernet/example/Arty/fpga/rtl/fpga.v \
    ./third_party/verilog_ethernet/example/Arty/fpga/rtl/fpga_core.v \
    ./third_party/verilog_ethernet/example/Arty/fpga/rtl/debounce_switch.v \
    ./third_party/verilog_ethernet/example/Arty/fpga/rtl/sync_signal.v \
    ./third_party/verilog_ethernet/example/Arty/fpga/lib/eth/rtl/ssio_sdr_in.v \
    ./third_party/verilog_ethernet/example/Arty/fpga/lib/eth/rtl/mii_phy_if.v \
    ./third_party/verilog_ethernet/example/Arty/fpga/lib/eth/rtl/eth_mac_mii_fifo.v \
    ./third_party/verilog_ethernet/example/Arty/fpga/lib/eth/rtl/eth_mac_mii.v \
    ./third_party/verilog_ethernet/example/Arty/fpga/lib/eth/rtl/eth_mac_1g.v \
    ./third_party/verilog_ethernet/example/Arty/fpga/lib/eth/rtl/axis_gmii_rx.v \
    ./third_party/verilog_ethernet/example/Arty/fpga/lib/eth/rtl/axis_gmii_tx.v \
    ./third_party/verilog_ethernet/example/Arty/fpga/lib/eth/rtl/lfsr.v \
    ./third_party/verilog_ethernet/example/Arty/fpga/lib/eth/rtl/eth_axis_rx.v \
    ./third_party/verilog_ethernet/example/Arty/fpga/lib/eth/rtl/eth_axis_tx.v \
    ./third_party/verilog_ethernet/example/Arty/fpga/lib/eth/rtl/udp_complete.v \
    ./third_party/verilog_ethernet/example/Arty/fpga/lib/eth/rtl/udp_checksum_gen.v \
    ./third_party/verilog_ethernet/example/Arty/fpga/lib/eth/rtl/udp.v \
    ./third_party/verilog_ethernet/example/Arty/fpga/lib/eth/rtl/udp_ip_rx.v \
    ./third_party/verilog_ethernet/example/Arty/fpga/lib/eth/rtl/udp_ip_tx.v \
    ./third_party/verilog_ethernet/example/Arty/fpga/lib/eth/rtl/ip_complete.v \
    ./third_party/verilog_ethernet/example/Arty/fpga/lib/eth/rtl/ip.v \
    ./third_party/verilog_ethernet/example/Arty/fpga/lib/eth/rtl/ip_eth_rx.v \
    ./third_party/verilog_ethernet/example/Arty/fpga/lib/eth/rtl/ip_eth_tx.v \
    ./third_party/verilog_ethernet/example/Arty/fpga/lib/eth/rtl/ip_arb_mux.v \
    ./third_party/verilog_ethernet/example/Arty/fpga/lib/eth/rtl/arp.v \
    ./third_party/verilog_ethernet/example/Arty/fpga/lib/eth/rtl/arp_cache.v \
    ./third_party/verilog_ethernet/example/Arty/fpga/lib/eth/rtl/arp_eth_rx.v \
    ./third_party/verilog_ethernet/example/Arty/fpga/lib/eth/rtl/arp_eth_tx.v \
    ./third_party/verilog_ethernet/example/Arty/fpga/lib/eth/rtl/eth_arb_mux.v \
    ./third_party/verilog_ethernet/example/Arty/fpga/lib/eth/lib/axis/rtl/arbiter.v \
    ./third_party/verilog_ethernet/example/Arty/fpga/lib/eth/lib/axis/rtl/priority_encoder.v \
    ./third_party/verilog_ethernet/example/Arty/fpga/lib/eth/lib/axis/rtl/axis_fifo.v \
    ./third_party/verilog_ethernet/example/Arty/fpga/lib/eth/lib/axis/rtl/axis_async_fifo.v \
    ./third_party/verilog_ethernet/example/Arty/fpga/lib/eth/lib/axis/rtl/axis_async_fifo_adapter.v \
    ./third_party/verilog_ethernet/example/Arty/fpga/lib/eth/lib/axis/rtl/sync_reset.v
set_property top fpga [current_fileset]
update_compile_order -fileset sources_1
# set_property FILE_TYPE {VHDL 2008} [get_files *.vhd]
# set_property used_in_simulation false [get_files top_syn.vhd]

# Add IP sources
puts "--- Adding IP Sources ---\n"
#add_files -fileset sources_1 ./ip/fifo_0.xci
#catch { config_ip_cache -export [get_ips -all fifo_0] }
#export_ip_user_files -of_objects [get_files ./ip/fifo_0.xci] -no_script -sync -force -quiet
#generate_target {instantiation_template} [get_files ./ip/fifo_0.xci]
#update_compile_order -fileset sources_1

# Add constraint files
puts "--- Adding Constraints Files ---\n"
add_files -fileset constrs_1 \
    ./third_party/verilog_ethernet/example/Arty/fpga/fpga.xdc \
    ./third_party/verilog_ethernet/example/Arty/fpga/lib/eth/syn/vivado/mii_phy_if.tcl \
    ./third_party/verilog_ethernet/example/Arty/fpga/lib/eth/syn/vivado/eth_mac_fifo.tcl \
    ./third_party/verilog_ethernet/example/Arty/fpga/lib/eth/lib/axis/syn/vivado/axis_async_fifo.tcl \
    ./third_party/verilog_ethernet/example/Arty/fpga/lib/eth/lib/axis/syn/vivado/sync_reset.tcl

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
