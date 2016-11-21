library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Implement a client in a KeeLoq scheme
entity client is
	generic (
		-- Client key (must be random)
		KEY: std_logic_vector(63 downto 0) := x"65887ba45f157620";
		-- Device serial (must be unique)
		SERIAL: std_logic_vector(27 downto 0) := x"325e7f3";
		-- Initial value for counter
		INI_CNTR: unsigned(15 downto 0) := x"0000"
	);
	port (
		i_clk: in std_logic;
		-- Gesture type to transfer
		i_qu: in std_logic_vector(1 downto 0);
		-- Button code to transfer
		i_btn: in std_logic_vector(3 downto 0);
		-- Start transmission on '1'
		i_start: in std_logic;
		-- Transmission is done on fall
		o_busy: out std_logic;
		-- TX
		o_tx: out std_logic
	);
end;

architecture rtl of client is
	type t_state is (off, encrypt, crc, tx);
	signal state: t_state := off;
	signal counter: unsigned(15 downto 0) := INI_CNTR;

	-- TX
	signal tx_data: std_logic_vector(68 downto 0);
	signal tx_start, tx_busy: std_logic;
	
	-- Encrypt
	signal enc_plaintext, enc_ciphertext: std_logic_vector(31 downto 0);
	signal enc_start, enc_busy: std_logic;
	
	-- CRC
	signal crc_data: std_logic_vector(64 downto 0);
	signal crc_ck: std_logic_vector(1 downto 0);
begin
	ent_tx: entity work.PWM_TX generic map (
		N => 69
	) port map (
		clk => i_clk,
		data => tx_data,
		activate => tx_start,
		tx => o_tx,
		busy => tx_busy
	);
	tx_data <= i_qu & crc_ck & '0' & i_btn & SERIAL & enc_ciphertext;
	
	ent_encrypt: entity work.keeloq_encrypt port map (
		i_key => KEY,
		i_plaintext => enc_plaintext,
		i_clk => i_clk,
		i_start => enc_start,
		o_ciphertext => enc_ciphertext,
		o_busy => enc_busy
	);
	enc_plaintext <= i_btn & "11" & SERIAL(9 downto 0) & std_logic_vector(counter);
	
	ent_crc: entity work.crc generic map (
		N => 65
	) port map (
		i_data => crc_data,
		o_crc => crc_ck
	);
	crc_data <= tx_data(64 downto 0);
	
	process (all) is
	begin
		if rising_edge(i_clk) then
			case state is
			when off =>
				-- Wait for i_start
				o_busy <= '0';
				if i_start then
					-- Encrypt payload
					enc_start <= '1';
					o_busy <= '1';
					state <= encrypt;
				end if;
			when encrypt =>
				-- Wait for encryption
				enc_start <= '0';
				if not enc_start and not enc_busy then
					-- Give CRC one clock to stabilize
					counter <= counter + 1;
					state <= crc;
				end if;
			when crc =>
				-- Start transmission
				tx_start <= '1';
				state <= tx;
			when tx =>
				-- Wait transmission
				tx_start <= '0';
				if not tx_start and not tx_busy then
					state <= off;
				end if;
			end case;
		end if;
	end process;
end architecture;