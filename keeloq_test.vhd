library ieee;
use ieee.std_logic_1164.all;
use work.pltbutils_func_pkg.all;
use work.pltbutils_comp_pkg.all;

entity keeloq_encrypt_test is
end entity;

architecture rtl of keeloq_encrypt_test is
	signal pltbs: pltbs_t := C_PLTBS_INIT;
	
	signal key: std_logic_vector(63 downto 0) := (others => '0');
	signal plaintext: std_logic_vector(31 downto 0) := (others => '0');
	signal clk, start_process, done: std_logic;
	signal ciphertext: std_logic_vector(31 downto 0) := (others => '0');
begin
	
	uut: entity work.keeloq_encrypt port map (key, plaintext, clk, start_process, ciphertext, done);
	
	clkgen: pltbutils_clkgen generic map (
		G_PERIOD => 20 ns
	) port map (
		clk_o => clk,
		stop_sim_i => '0'
	);
	
	process
		variable pltbv: pltbv_t := C_PLTBV_INIT;
	begin
		startsim("KeeLoq", "", pltbv, pltbs);
		
		starttest(1, "Encryption", pltbv, pltbs);
		key <= x"ba64de6e980836ed";
		plaintext <= x"b6b7e517";
		start_process <= '1';
		waitclks(1, clk, pltbv, pltbs);
		wait for 1 ns;
		start_process <= '0';
		check("Not done", done, '0', pltbv, pltbs);
		waitclks(8, clk, pltbv, pltbs);
		wait for 1 ns;
		check("Done", done, '1', pltbv, pltbs);
		check("Ciphertext", ciphertext, x"33b8700c", pltbv, pltbs);
		endtest(pltbv, pltbs);
		
		endsim(pltbv, pltbs, true);
		wait;
	end process;
	
end architecture;