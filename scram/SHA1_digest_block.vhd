library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Digest one block of 512 bits and update the 160-bit digest
-- The operation starts on a clock rise when i_start = '1'
-- The operation ends 80 clock rises after that
-- o_busy will fall to flag the output is ready
entity SHA1_digest_block is
	port (
		-- Each clock cycle corresponds to a round
		i_clk: in std_logic;
		-- Previous intermediate hash
		i_hash: in std_logic_vector(0 to 159);
		-- Block input
		i_block: in std_logic_vector(0 to 511);
		-- Start processing when '1'
		i_start: in std_logic;
		-- Final hash
		o_hash: out std_logic_vector(0 to 159);
		-- Operation done on fall
		o_busy: out std_logic := '0'
	);
end;


architecture rtl of SHA1_digest_block is
	subtype t_word is unsigned(31 downto 0);
	type t_word_vector is array (natural range <>) of t_word;
	signal s_round: integer range 0 to 79 := 0;
	signal s_words_queue: t_word_vector(0 to 15);
	signal s_hash: t_word_vector(0 to 4);
begin
	process (all) is
		variable Ws, T, a, b, c, d, e, ft, Kt: t_word;
	begin
		if rising_edge(i_clk) then
			if not o_busy and i_start then
				-- Start process
				o_busy <= '1';
				s_round <= 0;
				
				-- Copy bits to words
				for i in 0 to 4 loop
					s_hash(i) <= t_word'(unsigned(i_hash((32*i) to (31+32*i))));
				end loop;
			elsif o_busy then
				-- Do one of the 80 rounds
				
				-- Word schedule
				if s_round < 16 then
					Ws := unsigned(i_block((32*s_round) to (31+32*s_round)));
				else
					Ws := (s_words_queue(13) xor
						s_words_queue(8) xor
						s_words_queue(2) xor
						s_words_queue(0)) rol 1;
				end if;
				s_words_queue <= s_words_queue(1 to 15) & Ws;
				
				-- Define helper variables
				(a, b, c, d, e) := s_hash;
				if s_round < 20 then
					Kt := t_word'(x"5a827999");
					ft := (b and c) xor ((not b) and d);
				elsif s_round < 40 then
					Kt := t_word'(x"6ed9eba1");
					ft := b xor c xor d;
				elsif s_round < 60 then
					Kt := t_word'(x"8f1bbcdc");
					ft := (b and c) xor (b and d) xor (c and d);
				else
					Kt := t_word'(x"ca62c1d6");
					ft := b xor c xor d;
				end if;
				T := (a rol 5) + ft + e + Kt + Ws;
				
				-- Apply round
				e := d;
				d := c;
				c := b rol 30;
				b := a;
				a := T;
				s_hash <= (a, b, c, d, e);
			
				if s_round = 79 then
					-- Finished
					o_busy <= '0';
					o_hash(0 to 31) <= std_logic_vector(unsigned(i_hash(0 to 31)) + a);
					o_hash(32 to 63) <= std_logic_vector(unsigned(i_hash(32 to 63)) + b);
					o_hash(64 to 95) <= std_logic_vector(unsigned(i_hash(64 to 95)) + c);
					o_hash(96 to 127) <= std_logic_vector(unsigned(i_hash(96 to 127)) + d);
					o_hash(128 to 159) <= std_logic_vector(unsigned(i_hash(128 to 159)) + e);
				else
					s_round <= s_round + 1;
				end if;
			end if;
		end if;
	end process;
end architecture;