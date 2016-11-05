# Compile test bench framework
vcom -reportprogress 300 -2008 -work work \
	../../../pltb/txt_util.vhd \
	../../../pltb/pltbutils_user_cfg_pkg.vhd \
	../../../pltb/pltbutils_func_pkg.vhd \
	../../../pltb/pltbutils_comp.vhd \
	../../../pltb/pltbutils_comp_pkg.vhd

# Compile main application
vcom -reportprogress 300 -2008 -work work \
	../../SHA1_digest_block.vhd \
	../../SHA1.vhd \
	../../SHA1_PRNG.vhd

# Compile test cases
vcom -reportprogress 300 -2008 -work work \
	../../test/SHA1_digest_block.vhd \
	../../test/SHA1.vhd \
	../../test/SHA1_PRNG.vhd

vsim -l ../../test.log SHA1_PRNG_test

add wave -noupdate -divider {Simulation info}
add wave -noupdate -label {Test number} pltbs.test_num
add wave -noupdate -label {Test name} pltbs.test_name
add wave -noupdate -label {Info} pltbs.info
add wave -noupdate -label {Checks} pltbs.chk_cnt
add wave -noupdate -label {Errors} pltbs.err_cnt
add wave -noupdate -label {StopSim} pltbs.stop_sim
add wave -noupdate -divider DUT
add wave -noupdate *
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
configure wave -timelineunits ns
update

when {pltbs.stop_sim == '1'} {
	echo "At Time $now Ending the simulation"
	stop
}

run 1 ms