library ieee;
use ieee.std_logic_1164.all;
use work.pltbutils_func_pkg.all;

entity fixedCodeTest is
end entity;

architecture rtl of fixedCodeTest is
	signal pltbs: pltbs_t := C_PLTBS_INIT;
	
	signal code: std_logic_vector(3 downto 0);
	signal intake: std_logic;
	signal clk: std_logic;
	signal authorized: std_logic;
begin
	
	uut: entity work.fixedCode
		generic map (4)
		port map (code, intake, clk, authorized);
	
	process
		variable pltbv: pltbv_t := C_PLTBV_INIT;
	begin
		startsim("FixedCode", "", pltbv, pltbs);
		
		starttest("Success", pltbv, pltbs);
		code <= "1110";
		
		-- Intake bit a bit
		for i in 3 downto 0 loop
			clk <= '0';
			wait for 1 ns;
			check("Not done yet", authorized, '0', pltbv, pltbs);
			intake <= code(i);
			clk <= '1';
			wait for 1 ns;
		end loop;
		
		check("Authorized", authorized, '1', pltbv, pltbs);
		endtest(pltbv, pltbs);
		
		endsim(pltbv, pltbs, true);
		wait;
	end process;
	
end architecture;