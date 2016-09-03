library ieee;
use ieee.std_logic_1164.all;

-- Implement a fixed code authentication mechanism
entity fixedCode is
	generic (
		-- Number of bits
		N: natural
	);
	port (
		-- Correct code
		code: in std_logic_vector(N-1 downto 0);
		-- Next intake bit
		intake: in std_logic;
		-- Take the next bit from 'intake' and update 'authorized'
		clk: in std_logic;
		-- Whether the bit stream matches the expected value
		authorized: out std_logic := '0'
	);
end;

architecture rtl of fixedCode is
	-- Shift register content
	-- New bits come into memory(0),
	-- old bits fall of memory(N-1)
	signal memory: std_logic_vector(N-1 downto 0);
begin
	process (code, intake, clk) is
	begin
		if rising_edge(clk) then
			-- Shift memory by one
			memory <= memory(N-2 downto 0) & intake;
		end if;
	end process;
	
	-- Check result
	authorized <= '1' when memory = code else '0';
	
end architecture;