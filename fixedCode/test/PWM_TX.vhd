library ieee;
use ieee.std_logic_1164.all;
use work.pltbutils_func_pkg.all;
use work.pltbutils_comp_pkg.all;

entity PWM_TX_test is
end entity;

architecture rtl of PWM_TX_test is
	signal pltbs: pltbs_t := C_PLTBS_INIT;
	
	constant my_data: std_logic_vector(7 downto 0) := "10111101";
	-- Expected output is composed of 4 parts (preamble, header, payload and guard)
	constant expected_tx: std_logic_vector(0 to 72) :=
		"1010101010101010101010101010101" &
		"00000000" &
		"100110100100100100110100" &
		"0000000000";
	signal data: std_logic_vector(7 downto 0);
	signal clk, activate, tx: std_logic;
begin
	clk_gen: pltbutils_clkgen port map (clk, open, pltbs.stop_sim);
	
	uut: entity work.PWM_TX
		generic map (8)
		port map (data, clk, activate, tx);
	
	process
		variable pltbv: pltbv_t := C_PLTBV_INIT;
	begin
		startsim("PWM TX", "", pltbv, pltbs);
		
		-- While off, no output should be produced
		starttest("Off", pltbv, pltbs);
		for i in 1 to 5 loop
			waitclks(1, clk, pltbv, pltbs, true);
			check("No output", tx, '0', pltbv, pltbs);
		end loop;
		endtest(pltbv, pltbs);
		
		-- Start transmission
		activate <= '1';
		data <= my_data;
		waitclks(1, clk, pltbv, pltbs, true);
		data <= (others => '0');
		activate <= '0';
		for i in expected_tx'range loop
			waitclks(1, clk, pltbv, pltbs, true);
			check("TX@" & integer'image(i), tx, expected_tx(i), pltbv, pltbs);
		end loop;
		endtest(pltbv, pltbs);
		
		endsim(pltbv, pltbs, true);
		wait;
	end process;
	
end architecture;