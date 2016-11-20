library ieee;
use ieee.std_logic_1164.all;
use work.pltbutils_func_pkg.all;
use work.pltbutils_comp_pkg.all;

entity keeloq_test is
end entity;

architecture rtl of keeloq_test is
	signal pltbs: pltbs_t := C_PLTBS_INIT;
	
	signal i_key: std_logic_vector(63 downto 0) := (others => '0');
	signal i_plaintext, o_plaintext: std_logic_vector(31 downto 0) := (others => '0');
	signal i_clk, i_start1, i_start2, o_busy1, o_busy2: std_logic;
	signal o_ciphertext, i_ciphertext: std_logic_vector(31 downto 0) := (others => '0');
begin
	
	uut1: entity work.keeloq_encrypt port map (i_key, i_plaintext, i_clk, i_start1, o_ciphertext, o_busy1);
	uut2: entity work.keeloq_decrypt port map (i_key, i_ciphertext, i_clk, i_start2, o_plaintext, o_busy2);
	
	clkgen: pltbutils_clkgen generic map (
		G_PERIOD => 20 ns
	) port map (
		clk_o => i_clk,
		stop_sim_i => pltbs.stop_sim
	);
	
	process
		variable pltbv: pltbv_t := C_PLTBV_INIT;
	begin
		startsim("KeeLoq", "", pltbv, pltbs);
		
		starttest(1, "Encryption", pltbv, pltbs);
		i_key <= x"ba64de6e980836ed";
		i_plaintext <= x"b6b7e517";
		i_start1 <= '1';
		waitclks(1, i_clk, pltbv, pltbs, true);
		i_start1 <= '0';
		check("Busy", o_busy1, '1', pltbv, pltbs);
		waitclks(8, i_clk, pltbv, pltbs, true);
		check("Done", o_busy1, '0', pltbv, pltbs);
		check("Ciphertext", o_ciphertext, x"33b8700c", pltbv, pltbs);
		endtest(pltbv, pltbs);
		
		starttest(1, "Decryption", pltbv, pltbs);
		i_ciphertext <= o_ciphertext;
		i_start2 <= '1';
		waitclks(1, i_clk, pltbv, pltbs, true);
		i_start2 <= '0';
		check("Busy", o_busy2, '1', pltbv, pltbs);
		waitclks(8, i_clk, pltbv, pltbs, true);
		check("Done", o_busy2, '0', pltbv, pltbs);
		check("Plaintext", o_plaintext, i_plaintext, pltbv, pltbs);
		endtest(pltbv, pltbs);
		
		endsim(pltbv, pltbs, true);
		wait;
	end process;
	
end architecture;