library ieee;
use ieee.std_logic_1164.all;
use work.pltbutils_func_pkg.all;

entity SHA1_test is
end entity;

architecture rtl of SHA1_test is
	signal pltbs: pltbs_t := C_PLTBS_INIT;
	
	signal i_clk: std_logic;
	signal i_data1: std_logic_vector(0 to 159);
	signal i_data2: std_logic_vector(0 to 511);
	signal i_mode: std_logic;
	signal i_start: std_logic;
	signal o_hash: std_logic_vector(159 downto 0);
	signal o_busy: std_logic;
begin
	
	uut: entity work.SHA1
		port map (i_clk, i_data1, i_data2, i_mode, i_start, o_hash, o_busy);
	
	clkgen: entity work.pltbutils_clkgen
		port map (
			clk_o => i_clk,
			clk_n_o => open,
			stop_sim_i => pltbs.stop_sim
		);
	
	process
		variable pltbv: pltbv_t := C_PLTBV_INIT;
	begin
		startsim("SHA1", "", pltbv, pltbs);
		
		-- Test 1: 160 bits
		starttest("160 bits", pltbv, pltbs);
		i_data1 <= x"0be7d60cdff2831e651c6bd453c615181b3fa5e7";
		i_mode <= '0';
		i_start <= '1';
		
		waitclks(1, i_clk, pltbv, pltbs, true);
		i_start <= '0';
		
		check("Busy", o_busy, '1', pltbv, pltbs);
		
		waitsig(o_busy, '0', i_clk, pltbv, pltbs, true);
		check("Result", o_hash, x"7ec922998832c83e062cc574db54c69499124be1", pltbv, pltbs);
		
		endtest(pltbv, pltbs);
		
		-- Test 2: 512+160 bits
		starttest("512+160 bits", pltbv, pltbs);
		i_data1 <= x"ab495a9c59182564efb1f6fb5d72081dcfe3c087";
		i_data2 <= x"d408439bc9f52e813405690e3d3f87d694f64fc787756d8766ea52d17ee7bd75e209908b71213db663a9088bfbb0e1182393e6f5358b04e8b06142e7da3ac852";
		i_mode <= '1';
		i_start <= '1';
		
		waitclks(1, i_clk, pltbv, pltbs, true);
		i_start <= '0';
		
		check("Busy", o_busy, '1', pltbv, pltbs);
		
		waitsig(o_busy, '0', i_clk, pltbv, pltbs, true);
		check("Result", o_hash, x"ac39ad36ec653532bb3dd1553216489cf97df903", pltbv, pltbs);
		
		endtest(pltbv, pltbs);
		
		endsim(pltbv, pltbs, true);
		wait;
	end process;
	
end architecture;