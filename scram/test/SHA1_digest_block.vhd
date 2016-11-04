library ieee;
use ieee.std_logic_1164.all;
use work.pltbutils_func_pkg.all;

entity SHA1_digest_blockTest is
end entity;

architecture rtl of SHA1_digest_blockTest is
	signal pltbs: pltbs_t := C_PLTBS_INIT;
	
	signal i_clk: std_logic;
	signal i_hash: std_logic_vector(159 downto 0);
	signal i_block: std_logic_vector(511 downto 0);
	signal i_start: std_logic;
	signal o_hash: std_logic_vector(159 downto 0);
	signal o_busy: std_logic := '0';
begin
	
	uut: entity work.SHA1_digest_block
		port map (i_clk, i_hash, i_block, i_start, o_hash, o_busy);
	
	clkgen: entity work.pltbutils_clkgen
		port map (
			clk_o => i_clk,
			clk_n_o => open,
			stop_sim_i => pltbs.stop_sim
		);
	
	process
		variable pltbv: pltbv_t := C_PLTBV_INIT;
	begin
		startsim("SHA1_digest_block", "", pltbv, pltbs);
		
		-- Set inputs
		starttest("Success", pltbv, pltbs);
		i_hash <= x"67452301efcdab8998badcfe10325476c3d2e1f0";
		i_block <= x"80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
		i_start <= '1';
		
		waitclks(1, i_clk, pltbv, pltbs, true);
		i_start <= '0';
		
		check("Busy", o_busy, '1', pltbv, pltbs);
		
		waitsig(o_busy, '0', i_clk, pltbv, pltbs, true);
		check("Result", o_hash, x"da39a3ee5e6b4b0d3255bfef95601890afd80709", pltbv, pltbs);
		
		endtest(pltbv, pltbs);
		
		endsim(pltbv, pltbs, true);
		wait;
	end process;
	
end architecture;