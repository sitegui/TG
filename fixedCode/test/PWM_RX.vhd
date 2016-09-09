library ieee;
use ieee.std_logic_1164.all;
use work.pltbutils_func_pkg.all;
use work.pltbutils_comp_pkg.all;

entity PWM_RX_test is
end entity;

architecture rtl of PWM_RX_test is
	signal pltbs: pltbs_t := C_PLTBS_INIT;
	
	constant my_data: std_logic_vector(7 downto 0) := "10111101";
	-- Generated stream is composed of 4 parts (preamble, header, payload and guard)
	constant sent_tx: std_logic_vector(0 to 72) :=
		"1010101010101010101010101010101" &
		"00000000" &
		"100110100100100100110100" &
		"0000000000";
	signal data: std_logic_vector(7 downto 0);
	signal clk, data_ready, rx: std_logic;
begin
	clk_gen: pltbutils_clkgen port map (clk, open, pltbs.stop_sim);
	
	uut: entity work.PWM_RX
		generic map (8)
		port map (rx, clk, data, data_ready);
	
	process
		variable pltbv: pltbv_t := C_PLTBV_INIT;
	begin
		startsim("PWM RX", "", pltbv, pltbs);
		
		-- Receive transmission
		for i in sent_tx'range loop
			rx <= sent_tx(i);
			waitclks(1, clk, pltbv, pltbs, true);
			if i = 63 then
				check("Data ready", data_ready, '1', pltbv, pltbs);
				check("Data", data, my_data, pltbv, pltbs);
			else
				check("Data not ready@" & integer'image(i), data_ready, '0', pltbv, pltbs);
			end if;
		end loop;
		endtest(pltbv, pltbs);
		
		endsim(pltbv, pltbs, true);
		wait;
	end process;
	
end architecture;