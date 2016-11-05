library ieee;
use ieee.std_logic_1164.all;
use work.pltbutils_func_pkg.all;

entity HMAC_SHA1_test is
end entity;

architecture rtl of HMAC_SHA1_test is
	signal pltbs: pltbs_t := C_PLTBS_INIT;
	
	signal i_clk: std_logic;
	signal i_key: std_logic_vector(0 to 159);
	signal i_data: std_logic_vector(0 to 159);
	signal i_start: std_logic;
	signal o_mac: std_logic_vector(0 to 159);
	signal o_busy: std_logic := '0';
	signal o_sha1_data1: std_logic_vector(0 to 159);
	signal o_sha1_data2: std_logic_vector(0 to 511);
	signal o_sha1_start: std_logic;
	signal i_sha1_hash: std_logic_vector(0 to 159);
	signal i_sha1_busy: std_logic;
begin
	
	uut: entity work.HMAC_SHA1
		port map (i_clk, i_key, i_data, i_start, o_mac, o_busy,
			o_sha1_data1, o_sha1_data2, o_sha1_start, i_sha1_hash, i_sha1_busy);
	
	aux: entity work.SHA1
		port map (i_clk, o_sha1_data1, o_sha1_data2, '1', o_sha1_start, i_sha1_hash, i_sha1_busy);
	
	clkgen: entity work.pltbutils_clkgen
		port map (
			clk_o => i_clk,
			clk_n_o => open,
			stop_sim_i => pltbs.stop_sim
		);
	
	process
		variable pltbv: pltbv_t := C_PLTBV_INIT;
	begin
		startsim("HMAC SHA1", "", pltbv, pltbs);
		
		starttest("Success", pltbv, pltbs);
		i_key <= x"d885d91119ee4a4955f3762980033a8f89543716";
		i_data <= x"0098d4fe52cd6f81a1832d115743402aed5a9a17";
		i_start <= '1';
		waitclks(1, i_clk, pltbv, pltbs, true);
		i_start <= '0';
		check("Busy", o_busy, '1', pltbv, pltbs);
		waitsig(o_busy, '0', i_clk, pltbv, pltbs, true);
		check("Result", o_mac, x"fe11093b36471fc97f209e8c88dac9b334ccdcb5", pltbv, pltbs);
		endtest(pltbv, pltbs);
		
		endsim(pltbv, pltbs, true);
		wait;
	end process;
	
end architecture;