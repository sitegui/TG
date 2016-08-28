library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity keeloq_encrypt is
	port (
		key: in std_logic_vector(63 downto 0);
		plaintext: in std_logic_vector(31 downto 0);
		-- Rise edge clock
		clk: in std_logic;
		-- If 'on' on a clock pulse, resets the current process
		-- It will finish after more 8 clock cycles
		start_process: in std_logic;
		
		ciphertext: out std_logic_vector(31 downto 0);
		-- Indicates when the ciphertext is ready to be used
		done: out std_logic
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
		constant i: in integer;
		variable shift_reg: inout std_logic_vector(31 downto 0)
	) is
		variable nextBit, keyBit: std_logic;
	begin
		keyBit := key(i mod 64);
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
	signal stage: integer range 1 to 9;
	
	-- Partial result used to keep state between stages
	signal partial_result: std_logic_vector(31 downto 0);
begin
	
	process(key, plaintext, clk, start_process) is
		variable shift_reg: std_logic_vector(31 downto 0);
	begin
		if rising_edge(clk) then
			if start_process = '1' then
				-- Reset process
				shift_reg := plaintext;
				do_full_step(shift_reg);
				partial_result <= shift_reg;
				stage <= 1;
				done <= '0';
			elsif stage < 8 then
				-- Apply full step
				shift_reg := partial_result;
				do_full_step(shift_reg);
				partial_result <= shift_reg;
				stage <= stage + 1;
			elsif stage = 8 then
				-- Last stage
				shift_reg := partial_result;
				do_last_step(shift_reg);
				stage <= 9;
				ciphertext <= shift_reg;
				done <= '1';
			end if;
		end if;
	end process;
	
end architecture;