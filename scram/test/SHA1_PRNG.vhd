library ieee;
use ieee.std_logic_1164.all;
use work.pltbutils_func_pkg.all;

entity SHA1_PRNG_test is
end entity;

architecture rtl of SHA1_PRNG_test is
	signal pltbs: pltbs_t := C_PLTBS_INIT;
	
	signal i_clk: std_logic;
	signal i_start: std_logic;
	signal o_random: std_logic_vector(0 to 39);
	signal o_busy: std_logic := '0';
	signal o_sha1_data: std_logic_vector(0 to 159);
	signal o_sha1_start: std_logic;
	signal i_sha1_hash: std_logic_vector(0 to 159);
	signal i_sha1_busy: std_logic;
begin
	
	uut: entity work.SHA1_PRNG
		generic map (40, x"6e863f898a327b1a9a6b4f69b67df28c20bd3aac")
		port map (i_clk, i_start, o_random, o_busy,
			o_sha1_data, o_sha1_start, i_sha1_hash, i_sha1_busy);
	
	aux: entity work.SHA1
		port map (i_clk, o_sha1_data, (others => '0'), '0', o_sha1_start, i_sha1_hash, i_sha1_busy);
	
	clkgen: entity work.pltbutils_clkgen
		port map (
			clk_o => i_clk,
			clk_n_o => open,
			stop_sim_i => pltbs.stop_sim
		);
	
	process
		variable pltbv: pltbv_t := C_PLTBV_INIT;
	begin
		startsim("SHA1 PRNG", "", pltbv, pltbs);
		
		-- First random number
		starttest("First random", pltbv, pltbs);
		i_start <= '1';
		waitclks(1, i_clk, pltbv, pltbs, true);
		i_start <= '0';
		check("Busy", o_busy, '1', pltbv, pltbs);
		waitsig(o_busy, '0', i_clk, pltbv, pltbs, true);
		check("Result", o_random, x"ac8af8d88e", pltbv, pltbs);
		endtest(pltbv, pltbs);
		
		-- Second random number
		starttest("Second random", pltbv, pltbs);
		i_start <= '1';
		waitclks(1, i_clk, pltbv, pltbs, true);
		i_start <= '0';
		check("Busy", o_busy, '1', pltbv, pltbs);
		waitsig(o_busy, '0', i_clk, pltbv, pltbs, true);
		check("Result", o_random, x"6b29cf724e", pltbv, pltbs);
		endtest(pltbv, pltbs);
		
		endsim(pltbv, pltbs, true);
		wait;
	end process;
	
end architecture;