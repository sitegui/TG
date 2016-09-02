library ieee;
use ieee.std_logic_1164.all;

-- key(0) : next bit
-- key(1) : 

entity root is
	port (
		key: in std_logic_vector(1 downto 0);
		ledr: out std_logic_vector(0 downto 0)
	);
end;

architecture rtl of root is
begin
	fixedCode: entity work.fixedCode
		generic map (N => 10)
		port map (
			code => "1110111011",
			intake => key(1),
			clk => key(0),
			authorized => ledr(0)
		);
end architecture;