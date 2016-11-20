library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity keeloq_encrypt is
	port (
		i_key: in std_logic_vector(63 downto 0);
		i_plaintext: in std_logic_vector(31 downto 0);
		-- Rise edge clock
		i_clk: in std_logic;
		-- Start processing when '1'
		-- It will finish after more 8 clock cycles
		i_start: in std_logic;
		-- Final result
		o_ciphertext: out std_logic_vector(31 downto 0);
		-- Operation done on fall
		o_busy: out std_logic := '0'
	);
end entity;

architecture rtl of keeloq_encrypt is

	-- Non-linear function used in KeeLoq
	function nlf (
		bits: std_logic_vector(31 downto 0);
		b4, b3, b2, b1, b0: integer
	) return std_logic is
		variable addr: unsigned(4 downto 0);
		constant core: std_logic_vector(31 downto 0) := x"3A5C742E";
	begin
		addr := bits(b4) & bits(b3) & bits(b2) & bits(b1) & bits(b0);
		return core(to_integer(addr));
	end function;
	
	-- KeeLoq encryption round
	procedure do_round (
		constant i: in natural range 63 downto 0;
		variable shift_reg: inout std_logic_vector(31 downto 0)
	) is
		variable nextBit, keyBit: std_logic;
	begin
		keyBit := i_key(i);
		nextBit := nlf(shift_reg, 31, 26, 20, 9, 1) xor shift_reg(16) xor shift_reg(0) xor keyBit;
		shift_reg := nextBit & shift_reg(31 downto 1);
	end procedure;
	
	-- Apply 64 rounds
	procedure do_full_step (
		variable shift_reg: inout std_logic_vector(31 downto 0)
	) is
	begin
		for i in 0 to 63 loop
			do_round(i, shift_reg);
		end loop;
	end procedure;
	
	-- Apply 16 rounds
	procedure do_last_step (
		variable shift_reg: inout std_logic_vector(31 downto 0)
	) is
	begin
		for i in 0 to 15 loop
			do_round(i, shift_reg);
		end loop;
	end procedure;
	
	-- KeeLoq is composed of 528 rounds.
	-- This implementation divides that into 8 steps of 64 rounds and a final one of 16 rounds.
	-- This signal indicates how many steps were done.
	-- 1 = first stage, 9 = done
	type t_stage is (sdone, s1, s2, s3, s4, s5, s6, s7, s8);
	signal stage: t_stage;
	
	-- Partial result used to keep state between stages
	signal partial_result: std_logic_vector(31 downto 0);
begin
	
	process (all) is
		variable shift_reg: std_logic_vector(31 downto 0);
	begin
		if rising_edge(i_clk) then
			if not o_busy and i_start then
				-- Reset process
				shift_reg := i_plaintext;
				do_full_step(shift_reg);
				partial_result <= shift_reg;
				stage <= s1;
				o_busy <= '1';
			elsif stage = sdone then
				-- Nothing to do
			elsif stage = s8 then
				-- Last stage
				shift_reg := partial_result;
				do_last_step(shift_reg);
				stage <= sdone;
				o_ciphertext <= shift_reg;
				o_busy <= '0';
			else
				-- Apply full step
				shift_reg := partial_result;
				do_full_step(shift_reg);
				partial_result <= shift_reg;
				
				case stage is
					when s1 => stage <= s2;
					when s2 => stage <= s3;
					when s3 => stage <= s4;
					when s4 => stage <= s5;
					when s5 => stage <= s6;
					when s6 => stage <= s7;
					when s7 => stage <= s8;
					when others =>
				end case;
			end if;
		end if;
	end process;
	
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity keeloq_decrypt is
	port (
		i_key: in std_logic_vector(63 downto 0);
		i_ciphertext: in std_logic_vector(31 downto 0);
		-- Rise edge clock
		i_clk: in std_logic;
		-- Start processing when '1'
		-- It will finish after more 8 clock cycles
		i_start: in std_logic;
		-- Final result
		o_plaintext: out std_logic_vector(31 downto 0);
		-- Operation done on fall
		o_busy: out std_logic := '0'
	);
end entity;

architecture rtl of keeloq_decrypt is

	-- Non-linear function used in KeeLoq
	function nlf (
		bits: std_logic_vector(31 downto 0);
		b4, b3, b2, b1, b0: integer
	) return std_logic is
		variable addr: unsigned(4 downto 0);
		constant core: std_logic_vector(31 downto 0) := x"3A5C742E";
	begin
		addr := bits(b4) & bits(b3) & bits(b2) & bits(b1) & bits(b0);
		return core(to_integer(addr));
	end function;
	
	-- KeeLoq decryption round
	procedure do_round (
		constant i: in natural range 63 downto 0;
		variable shift_reg: inout std_logic_vector(31 downto 0)
	) is
		variable nextBit, keyBit: std_logic;
	begin
		keyBit := i_key(i);
		nextBit := nlf(shift_reg, 30, 25, 19, 8, 0) xor shift_reg(15) xor shift_reg(31) xor keyBit;
		shift_reg := shift_reg(30 downto 0) & nextBit;
	end procedure;
	
	-- Apply 64 rounds
	procedure do_full_step (
		variable shift_reg: inout std_logic_vector(31 downto 0)
	) is
	begin
		for i in 63 downto 0 loop
			do_round(i, shift_reg);
		end loop;
	end procedure;
	
	-- Apply 16 rounds
	procedure do_first_step (
		variable shift_reg: inout std_logic_vector(31 downto 0)
	) is
	begin
		for i in 15 downto 0 loop
			do_round(i, shift_reg);
		end loop;
	end procedure;
	
	-- KeeLoq is composed of 528 rounds.
	-- This implementation divides that into a step of 16 rounds and 8 steps of 64 rounds.
	-- This signal indicates how many steps were done.
	-- 1 = first stage, 9 = done
	type t_stage is (sdone, s1, s2, s3, s4, s5, s6, s7, s8);
	signal stage: t_stage;
	
	-- Partial result used to keep state between stages
	signal partial_result: std_logic_vector(31 downto 0);
begin
	
	process (all) is
		variable shift_reg: std_logic_vector(31 downto 0);
	begin
		if rising_edge(i_clk) then
			if not o_busy and i_start then
				-- Reset process
				shift_reg := i_ciphertext;
				do_first_step(shift_reg);
				partial_result <= shift_reg;
				stage <= s1;
				o_busy <= '1';
			elsif stage = sdone then
				-- Nothing to do
			else
				-- Apply full step
				shift_reg := partial_result;
				do_full_step(shift_reg);
				partial_result <= shift_reg;
				
				case stage is
					when s1 => stage <= s2;
					when s2 => stage <= s3;
					when s3 => stage <= s4;
					when s4 => stage <= s5;
					when s5 => stage <= s6;
					when s6 => stage <= s7;
					when s7 => stage <= s8;
					when s8 =>
						stage <= sdone;
						o_plaintext <= shift_reg;
						o_busy <= '0';
					when others =>
				end case;
			end if;
		end if;
	end process;
	
end architecture;