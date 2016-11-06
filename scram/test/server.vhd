library ieee;
use ieee.std_logic_1164.all;
use work.pltbutils_func_pkg.all;

entity server_test is
end entity;

architecture rtl of server_test is
	signal pltbs: pltbs_t := C_PLTBS_INIT;
	
	signal i_clk, i_rx, o_tx, o_received, o_valid: std_logic;
	signal o_data: std_logic_vector(0 to 7);
	
	signal tx_data: std_logic_vector(0 to 239);
	signal tx_start, tx_busy: std_logic;
	
	signal rx_data: std_logic_vector(0 to 79);
	signal rx_ready: std_logic;
	
	constant serial: std_logic_vector(0 to 31) := x"6d5d4d89";
	constant data: std_logic_vector(0 to 7) := x"4b";
	constant nonce_c: std_logic_vector(0 to 39) := x"059c5c379c";
	constant nonce_s: std_logic_vector(0 to 39) := x"05fa6c8282";
	constant proof: std_logic_vector(0 to 159) := x"b6a3a53a203bd9b13339cdbf6100b1c8137bc154";
begin
	
	uut: entity work.server
		generic map (
			x"c7eb39712c4acd677012d8158fc6fce5a1116daf",
			x"424bb35458f2f986dbafe2ab2b5bfa5fe10ee0a3",
			SERIAL,
			50000
		)
		port map (i_clk, i_rx, o_tx, o_received, o_valid, o_data);
	
	aux_tx: entity work.PWM_TX generic map (
		N => 240
	) port map (
		clk => i_clk,
		data => tx_data,
		activate => tx_start,
		tx => i_rx,
		busy => tx_busy
	);
	
	aux_rx: entity work.PWM_RX generic map (
		N => 80
	) port map (
		clk => i_clk,
		rx => o_tx,
		data => rx_data,
		data_ready => rx_ready
	);
	
	clkgen: entity work.pltbutils_clkgen
		port map (
			clk_o => i_clk,
			clk_n_o => open,
			stop_sim_i => pltbs.stop_sim
		);
	
	process
		variable pltbv: pltbv_t := C_PLTBV_INIT;
	begin
		startsim("Server", "", pltbv, pltbs);
		
		-- Client first
		starttest("First message", pltbv, pltbs);
		tx_data <= serial & nonce_c & data & (80 to 239 => '0');
		tx_start <= '1';
		waitclks(1, i_clk, pltbv, pltbs, true);
		tx_start <= '0';
		waitsig(o_received, '1', i_clk, pltbv, pltbs, true);
		waitsig(tx_busy, '0', i_clk, pltbv, pltbs, true);
		endtest(pltbv, pltbs);
		
		-- Server first
		starttest("Second message", pltbv, pltbs);
		waitsig(rx_ready, '1', i_clk, pltbv, pltbs, true);
		check("Frame: client nonce", rx_data(0 to 39), nonce_c, pltbv, pltbs);
		check("Frame: server nonce", rx_data(40 to 79), nonce_s, pltbv, pltbs);
		endtest(pltbv, pltbs);
		
		-- Client last
		starttest("Third message", pltbv, pltbs);
		tx_data <= nonce_c & nonce_s & proof;
		tx_start <= '1';
		waitclks(1, i_clk, pltbv, pltbs, true);
		tx_start <= '0';
		waitsig(o_received, '1', i_clk, pltbv, pltbs, true, 10 us);
		waitsig(tx_busy, '0', i_clk, pltbv, pltbs, true, 10 us);
		waitsig(o_valid, '1', i_clk, pltbv, pltbs, true, 10 us);
		check("Transfered data", o_data, data, pltbv, pltbs);
		endtest(pltbv, pltbs);
		
		endsim(pltbv, pltbs, true);
		wait;
	end process;
	
end architecture;