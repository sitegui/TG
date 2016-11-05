library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Generate up to 80 pseudo-random bits, using a simple
-- construction based on SHA1
-- Some theoretical background is provided here:
-- http://crypto.stackexchange.com/questions/9076/using-a-hash-as-a-secure-prng
-- It would be better to use a stream cipher or a block cipher in CTR mode,
-- but this provides an ok PRNG reusing the SHA1 digest block available elsewhere
-- Initialization: state = seed
-- Iteration: state = hash(state); output = slice_of(state)
entity SHA1_PRNG is
	generic (
		-- Output size
		N: natural range 1 to 80
	);
	port (
		i_clk: in std_logic;
		-- Previous intermediate hash
		i_seed: in std_logic_vector(0 to 159);
		-- Apply seed when '1'. Can only be seeded once
		i_load_seed: in std_logic;
		-- Start generating random bits when '1', after seeded
		i_start: in std_logic;
		-- Generated pseudo-random bits
		o_random: out std_logic_vector(0 to N-1);
		-- Operation done on fall
		o_busy: out std_logic := '0';
		
		-- SHA1 shared ports (must share the same clock)
		o_sha1_data: out std_logic_vector(0 to 159);
		o_sha1_start: out std_logic;
		i_sha1_hash: in std_logic_vector(0 to 159);
		i_sha1_busy: in std_logic
	);
end;

architecture rtl of SHA1_PRNG is
	signal seeded: std_logic := '0';
	signal state: std_logic_vector(0 to 159);
begin
	process (all) is
	begin
		if rising_edge(i_clk) then
			o_sha1_start <= '0';
			if not o_busy and i_load_seed and not seeded then
				-- Copy to internal state
				state <= i_seed;
				seeded <= '1';
			elsif not o_busy and i_start and seeded then
				-- Iterate
				o_busy <= '1';
				o_sha1_start <= '1';
			elsif o_busy and not o_sha1_start and not i_sha1_busy then
				-- Hash finished
				state <= i_sha1_hash;
				o_random <= i_sha1_hash(0 to N-1);
				o_busy <= '0';
			end if;
		end if;
	end process;
	
	o_sha1_data <= state;
end architecture;