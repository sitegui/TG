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
	signal ciphertext: std_logic_vector(31 downto 0) := (others => '0');
begin
	
	uut: entity work.keeloq_encrypt port map (key, plaintext, ciphertext);
	
	process
		variable pltbv: pltbv_t := C_PLTBV_INIT;
	begin
		startsim("tc1", "", pltbv, pltbs);
		
		starttest(1, "Encryption", pltbv, pltbs);
		key <= x"ba64de6e980836ed";
		plaintext <= x"b6b7e517";
		wait for 1 ns;
		check("Ciphertext", ciphertext, x"33b8700c", pltbv, pltbs);
		endtest(pltbv, pltbs);
		
		endsim(pltbv, pltbs, true);
		wait;
	end process;
	
end architecture;