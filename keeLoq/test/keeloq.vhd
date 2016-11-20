library ieee;
use ieee.std_logic_1164.all;
use work.pltbutils_func_pkg.all;
use work.pltbutils_comp_pkg.all;

entity keeloq_test is
end entity;

architecture rtl of keeloq_test is
	signal pltbs: pltbs_t := C_PLTBS_INIT;
	
	signal i_key: std_logic_vector(63 downto 0) := (others => '0');
	signal i_plaintext: std_logic_vector(31 downto 0) := (others => '0');
	signal i_clk, i_start, o_busy: std_logic;
	signal o_ciphertext: std_logic_vector(31 downto 0) := (others => '0');
begin
	
	uut: entity work.keeloq_encrypt port map (i_key, i_plaintext, i_clk, i_start, o_ciphertext, o_busy);
	
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
		i_start <= '1';
		waitclks(1, i_clk, pltbv, pltbs, true);
		i_start <= '0';
		check("Busy", o_busy, '1', pltbv, pltbs);
		waitclks(8, i_clk, pltbv, pltbs, true);
		check("Done", o_busy, '0', pltbv, pltbs);
		check("Ciphertext", o_ciphertext, x"33b8700c", pltbv, pltbs);
		endtest(pltbv, pltbs);
		
		endsim(pltbv, pltbs, true);
		wait;
	end process;
	
end architecture;