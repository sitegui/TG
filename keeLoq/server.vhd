library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Implement a server in a KeeLoq scheme
-- This is a sample implementation with support for only one device
entity server is
	generic (
		-- Client key (must be random)
		KEY: std_logic_vector(63 downto 0) := x"65887ba45f157620";
		-- Device serial
		SERIAL: std_logic_vector(27 downto 0) := x"325e7f3";
		-- Initial value for counter
		INI_CNTR: unsigned(15 downto 0) := x"0000"
	);
	port (
		i_clk: in std_logic;
		-- RX
		i_rx: in std_logic;
		-- Gesture type transfered
		o_qu: out std_logic_vector(1 downto 0);
		-- Button code transfered
		o_btn: out std_logic_vector(3 downto 0);
		-- Rise for 1 clock cycle when receives a message
		o_received: out std_logic;
		-- Rise for 1 clock cycle when completes authorization
		o_valid: out std_logic
	);
end;

architecture rtl of server is
	type t_state is (rx, crc, decrypt, check);
	signal state: t_state := rx;
	signal target_counter: unsigned(15 downto 0) := INI_CNTR;
	signal temp_counter: unsigned(15 downto 0);

	-- RX
	signal rx_data, rx_data_copy: std_logic_vector(68 downto 0);
	signal rx_ready: std_logic;
	
	-- Decrypt
	signal dec_plaintext, dec_ciphertext: std_logic_vector(31 downto 0);
	signal dec_start, dec_busy: std_logic;
	
	-- CRC
	signal crc_data: std_logic_vector(64 downto 0);
	signal crc_ck: std_logic_vector(1 downto 0);
begin
	ent_rx: entity work.PWM_RX generic map (
		N => 69
	) port map (
		clk => i_clk,
		rx => i_rx,
		data => rx_data,
		data_ready => rx_ready
	);
	o_received <= rx_ready;
	
	ent_decrypt: entity work.keeloq_decrypt port map (
		i_key => KEY,
		i_ciphertext => dec_ciphertext,
		i_clk => i_clk,
		i_start => dec_start,
		o_plaintext => dec_plaintext,
		o_busy => dec_busy
	);
	dec_ciphertext <= rx_data_copy(31 downto 0);
	
	ent_crc: entity work.crc generic map (
		N => 65
	) port map (
		i_data => crc_data,
		o_crc => crc_ck
	);
	crc_data <= rx_data_copy(64 downto 0);
	
	process (all) is
		variable rx_counter: unsigned(15 downto 0);
	begin
		if rising_edge(i_clk) then
			case state is
			when rx =>
				-- Wait for client message
				o_valid <= '0';
				if rx_ready then
					-- Extract info from frame to check CK
					if rx_data(59 downto 32) /= SERIAL then
						-- ERROR: unknown serial
						state <= rx;
					else
						state <= crc;
						rx_data_copy <= rx_data;
					end if;
				end if;
			when crc =>
				-- Give one clock cycle for CRC to complete
				if crc_ck /= rx_data_copy(66 downto 65) then
					-- ERROR: invalid CRC
					state <= rx;
				else
					-- Decrypt
					dec_start <= '1';
					state <= decrypt;
				end if;
			when decrypt =>
				-- Wait for decryption
				dec_start <= '0';
				if not dec_start and not dec_busy then
					rx_counter := unsigned(dec_plaintext(15 downto 0));
					if
						dec_plaintext(31 downto 28) /= rx_data_copy(63 downto 60) or
						dec_plaintext(25 downto 16) /= SERIAL(9 downto 0)
					then
						-- ERROR: button or discriminator mismatch
						state <= rx;
					elsif temp_counter /= 0 and rx_counter = temp_counter + 1 then
						-- Resynchronized
						target_counter <= rx_counter;
						temp_counter <= to_unsigned(0, 16);
						o_valid <= '1';
						state <= rx;
					elsif target_counter < rx_counter and rx_counter <= target_counter + 16 then
						-- Within reasonable window
						target_counter <= rx_counter;
						o_valid <= '1';
						state <= rx;
					elsif target_counter < rx_counter and rx_counter <= target_counter + 32768 then
						-- Require resynchonization
						temp_counter <= rx_counter;
						state <= rx;
					else
						-- ERROR: wrong counter
						state <= rx;
					end if;
				end if;
			end case;
		end if;
	end process;
end architecture;