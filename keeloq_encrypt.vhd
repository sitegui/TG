library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity keeloq_encrypt is
	port (
		key: in std_logic_vector(63 downto 0);
		plaintext: in std_logic_vector(31 downto 0);
		ciphertext: out std_logic_vector(31 downto 0)
	);
end entity;

architecture rtl of keeloq_encrypt is
	function nlf(
		bits: std_logic_vector(31 downto 0);
		b4, b3, b2, b1, b0: integer
	) return std_logic is
		variable addr: unsigned(4 downto 0);
		constant core: std_logic_vector(31 downto 0) := x"3A5C742E";
	begin
		addr := bits(b4) & bits(b3) & bits(b2) & bits(b1) & bits(b0);
		return core(to_integer(addr));
	end function;
begin
	
	process(key, plaintext) is
		variable shiftReg: std_logic_vector(31 downto 0);
		variable nextBit, keyBit: std_logic;
	begin
		shiftReg := plaintext;
		for i in 0 to 527 loop
			keyBit := key(i mod 64);
			nextBit := nlf(shiftReg, 31, 26, 20, 9, 1) xor shiftReg(16) xor shiftReg(0) xor keyBit;
			shiftReg := nextBit & shiftReg(31 downto 1);
		end loop;
		ciphertext <= shiftReg;
	end process;
	
end architecture;