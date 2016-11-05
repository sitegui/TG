library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Digest either 160, 512+160 bits
-- The operation starts on a clock rise when i_start = '1'
-- o_busy will fall to flag the output is ready
entity SHA1 is
	port (
		i_clk: in std_logic;
		-- Input (should not be changed during operation)
		i_data1: in std_logic_vector(0 to 159);
		i_data2: in std_logic_vector(0 to 511);
		-- Mode of operation
		-- '0': hash(i_data1), 160 bits
		-- '1': hash(i_data2 & i_data1), 512+160 bits
		i_mode: in std_logic;
		-- Start processing when '1'
		i_start: in std_logic;
		-- Final hash
		o_hash: out std_logic_vector(159 downto 0);
		-- Operation done on fall
		o_busy: out std_logic := '0'
	);
end;


architecture rtl of SHA1 is
	signal sha1_hash_in, sha1_hash_out: std_logic_vector(0 to 159);
	signal sha1_block: std_logic_vector(0 to 511);
	signal sha1_start, sha1_busy: std_logic;
	signal last_block: boolean;
begin
	digest_block: entity work.SHA1_digest_block
		port map(
			i_clk => i_clk,
			i_hash => sha1_hash_in,
			i_block => sha1_block,
			i_start => sha1_start,
			o_hash => sha1_hash_out,
			o_busy => sha1_busy
		);

	process (all) is
		constant k_160: unsigned(63 downto 0) := to_unsigned(160, 64);
		constant k_512_160: unsigned(63 downto 0) := to_unsigned(512+160, 64);
	begin
		if rising_edge(i_clk) then
			sha1_start <= '0';
			if not o_busy and i_start then
				-- Start
				sha1_hash_in <= x"67452301efcdab8998badcfe10325476c3d2e1f0";
				sha1_start <= '1';
				o_busy <= '1';
				if i_mode ='0' then
					-- 160 bits
					sha1_block(0 to 159) <= i_data1;
					sha1_block(160) <= '1';
					sha1_block(161 to 447) <= (others => '0');
					sha1_block(448 to 511) <= std_logic_vector(k_160);
				elsif i_mode = '1' then
					-- 512+160 bits
					sha1_block <= i_data2;
					last_block <= false;
				end if;
			elsif o_busy and not sha1_start and not sha1_busy then
				-- Finish or input next block
				if i_mode = '1' and not last_block then
					-- 512+160 bits next block
					sha1_hash_in <= sha1_hash_out;
					sha1_block(0 to 159) <= i_data1;
					sha1_block(160) <= '1';
					sha1_block(161 to 447) <= (others => '0');
					sha1_block(448 to 511) <= std_logic_vector(k_512_160);
					sha1_start <= '1';
					last_block <= true;
				else
					-- 160 bits or 512+160 bits done
					o_hash <= sha1_hash_out;
					o_busy <= '0';
				end if;
			end if;
		end if;
	end process;
end architecture;