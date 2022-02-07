library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Set Generic g_CLKS_PER_BIT as follows:
-- g_CLKS_PER_BIT = (Frequency of i_Clk)/(Frequency of UART)
-- Example: 10 MHz Clock, 115200 baud UART
-- (10000000)/(115200) = 87
-- (50000000)/(115200)= 434
-- (50000000)/(12500000)=4



Entity UART_TEST is 
	port ( clk 		: in std_logic;
			leds 		: out std_logic_vector (8 downto 1);
			uart_tx_out : out std_logic;
			uart_rx_in	: in std_logic
		);
end UART_TEST;

Architecture main of UART_TEST is

	component UART  is
		port (
			i_Clk       : in  std_logic;
			i_TX_DV     : in  std_logic;
			i_TX_Byte   : in  std_logic_vector(7 downto 0);
			o_TX_Active : out std_logic;
			o_TX_Serial : out std_logic;
			o_TX_Done   : out std_logic;
			
			i_RX_Serial : in  std_logic;
			o_RX_DV     : out std_logic;
			o_RX_Byte   : out std_logic_vector(7 downto 0)
		);
	end component UART;
	
	signal sig_txData			: std_logic_vector(7 downto 0);
	signal sig_uart_tx		: std_logic;
	signal sig_tx_dataValid	: std_logic;
	signal sig_tx_active 	: std_logic;
	signal sig_tmp2 			: std_logic_vector(7 downto 0);
	signal sig_tx_uart_done : std_logic;
	
	signal sig_rxData				: std_logic_vector(7 downto 0);
	signal sig_rx_dataValid 	: std_logic;
	signal sig_uart_rx			: std_logic;
	
	signal rx_buffer	: std_logic_vector(7 downto 0) := x"A5";
	signal counter 	: integer range 0 to 12500000 := 0;
	signal clk_div		: std_logic;
	
	signal reset 		: std_logic := '0';
	
	signal sig_led			: std_logic;
begin

uart_tx_out <= sig_uart_tx;
sig_uart_rx <= uart_rx_in;
leds(1) <= clk_div;
leds(2) <= sig_led;

--sig_led <= clk_div;

uartmap : UART PORT MAP (
			i_Clk => clk, 
			i_TX_DV => sig_tx_dataValid, 
			i_tX_Byte => sig_txData,
			o_TX_Active => sig_tx_active,
			o_TX_Serial => sig_uart_tx,
			o_TX_Done => sig_tx_uart_done,
			
			i_RX_Serial => sig_uart_rx,
			o_RX_DV		=> sig_rx_dataValid,
			o_RX_byte 	=> sig_rxData
	);
	
rx : process (sig_rx_dataValid) begin
	if (sig_rx_dataValid = '1') then 
		rx_buffer <= sig_rxData;
		sig_led <= not sig_led;
	end if;
end process;
--tx : process (clk_div, sig_tx_active) begin
--	if rising_edge(clk_div) then
--		if sig_tx_active = '0' then
--			sig_txData <= rx_buffer;
--			sig_tx_dataValid <= '1';
--		else
--			sig_tx_dataValid <= '0';
--		end if;
--	end if;
--end process;

--ClkDivider : process (clk, reset) begin
--	if (reset = '1') then 
--		clk_div <= '0';
--		counter <= 0;
--		sig_led <= '0';
--	elsif rising_edge(clk) then
--		if (counter = 12500000) then
--			clk_div <= not clk_div;
--			counter <= 0;
--		else
--			counter <= counter + 1;
--		end if;
--	end if;
--end process;

end main;
