library ieee;
use ieee.std_logic_1164.all;
use work.pltbutils_func_pkg.all;
use work.pltbutils_comp_pkg.all;

entity crc_test is
end entity;

architecture rtl of crc_test is
	signal pltbs: pltbs_t := C_PLTBS_INIT;
	
	signal i_data: std_logic_vector(64 downto 0);
	signal o_crc: std_logic_vector(1 downto 0);
	signal i_clk: std_logic;
begin
	
	uut: entity work.crc generic map (65) port map (i_data, o_crc);
	
	clkgen: pltbutils_clkgen generic map (
		G_PERIOD => 20 ns
	) port map (
		clk_o => i_clk,
		stop_sim_i => pltbs.stop_sim
	);
	
	process
		variable pltbv: pltbv_t := C_PLTBV_INIT;
	begin
		startsim("CRC", "", pltbv, pltbs);
		
		starttest(1, "00", pltbv, pltbs);
		i_data <= "01110000011010101111011011010011000101011100011101100110010011010";
		waitclks(1, i_clk, pltbv, pltbs, true);
		check("CRC", o_crc, "00", pltbv, pltbs);
		endtest(pltbv, pltbs);
		
		starttest(1, "01", pltbv, pltbs);
		i_data <= "11110110110010101001110001111001010111000100010011011000011000110";
		waitclks(1, i_clk, pltbv, pltbs, true);
		check("CRC", o_crc, "01", pltbv, pltbs);
		endtest(pltbv, pltbs);
		
		starttest(1, "10", pltbv, pltbs);
		i_data <= "10101001011001101100010101110010011001010010011010100010010011100";
		waitclks(1, i_clk, pltbv, pltbs, true);
		check("CRC", o_crc, "10", pltbv, pltbs);
		endtest(pltbv, pltbs);
		
		starttest(1, "11", pltbv, pltbs);
		i_data <= "01001010001101111000110101101101101000111000100111001100010111110";
		waitclks(1, i_clk, pltbv, pltbs, true);
		check("CRC", o_crc, "11", pltbv, pltbs);
		endtest(pltbv, pltbs);
		
		endsim(pltbv, pltbs, true);
		wait;
	end process;
	
end architecture;