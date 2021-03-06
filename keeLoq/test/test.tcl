# Compile test bench framework
vcom -reportprogress 300 -2008 -work work \
	../../../pltb/txt_util.vhd \
	../../../pltb/pltbutils_user_cfg_pkg.vhd \
	../../../pltb/pltbutils_func_pkg.vhd \
	../../../pltb/pltbutils_comp.vhd \
	../../../pltb/pltbutils_comp_pkg.vhd

# Compile main application
vcom -reportprogress 300 -2008 -work work \
	../../../PWM/PWM_TX.vhd \
	../../../PWM/PWM_RX.vhd \
	../../keeloq.vhd \
	../../crc.vhd \
	../../client.vhd \
	../../server.vhd \
	../../root.vhd

# Compile test cases
vcom -reportprogress 300 -2008 -work work \
	../../test/keeloq.vhd \
	../../test/crc.vhd \
	../../test/client.vhd \
	../../test/root.vhd

vsim -l ../../test.log root_test

add wave -noupdate -divider {Simulation info}
add wave -noupdate -label {Test number} pltbs.test_num
add wave -noupdate -label {Test name} pltbs.test_name
add wave -noupdate -label {Info} pltbs.info
add wave -noupdate -label {Checks} pltbs.chk_cnt
add wave -noupdate -label {Errors} pltbs.err_cnt
add wave -noupdate -label {StopSim} pltbs.stop_sim
add wave -noupdate -divider DUT
add wave -noupdate *
add wave -position end sim:/root_test/uut/ent_client/state
add wave -position end sim:/root_test/uut/ent_server/state
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 us} 0}
configure wave -timelineunits us
update

when {pltbs.stop_sim == '1'} {
	echo "At Time $now Ending the simulation"
	stop
}

run 1 ms
wave zoom full