library ieee;
use ieee.std_logic_1164.all;
use work.pltbutils_func_pkg.all;

entity root_test is
end entity;

architecture rtl of root_test is
	signal pltbs: pltbs_t := C_PLTBS_INIT;
	
	signal key: std_logic_vector(0 downto 0);
	signal clock_50: std_logic;
	signal ledr: std_logic_vector(1 downto 0);
begin
	
	uut: entity work.root port map (key, clock_50, ledr);
	
	clkgen: entity work.pltbutils_clkgen
		port map (
			clk_o => clock_50,
			clk_n_o => open,
			stop_sim_i => pltbs.stop_sim
		);
	
	process
		variable pltbv: pltbv_t := C_PLTBV_INIT;
	begin
		startsim("Root", "", pltbv, pltbs);
		
		starttest("Success", pltbv, pltbs);
		key(0) <= '1';
		waitclks(1, clock_50, pltbv, pltbs, true);
		key(0) <= '0';
		waitsig(ledr(1), '1', clock_50, pltbv, pltbs, true);
		endtest(pltbv, pltbs);
		
		endsim(pltbv, pltbs, true);
		wait;
	end process;
	
end architecture;