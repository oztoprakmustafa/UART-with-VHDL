library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--This file contains the UART Transmitter and Receiver.  This transmitter is able
-- to transmit 8 bits of serial data, one start bit, one stop bit,
-- and no parity bit.  The receiver receives 8 bits of serial data, along with a start and stop bit.
-- When transmit is complete o_TX_Done will be driven high for one clock cycle.
--
-- Set Generic g_CLKS_PER_BIT as follows:
-- g_CLKS_PER_BIT = (Frequency of i_Clk)/(Frequency of UART)
-- Example: 10 MHz Clock, 115200 baud UART
-- (10000000)/(115200) = 87
-- (50000000)/(115200) = 434

 
entity UART is
  generic (
    g_CLKS_PER_BIT : integer := 434     -- Needs to be set correctly
  );
  port (
    i_Clk       : in  std_logic;				              -- clock
    i_TX_DV     : in  std_logic;                      -- Data Valid - Manually set when data is ready
    i_TX_Byte   : in  std_logic_vector(7 downto 0);   -- Data to be sent
    o_TX_Active : out std_logic;                      -- Is set when a transfer is in progress
    o_TX_Serial : out std_logic;                      -- FPGA Tx pin
    o_TX_Done   : out std_logic;                      -- Set high for 1 clock cycle when transmit complete
	 
	  i_RX_Serial : in  std_logic;                      -- FPGA Rx pin
    o_RX_DV     : out std_logic;                      -- Data Valid - Set high for 1 clock cycle when data has been read fully
    o_RX_Byte   : out std_logic_vector(7 downto 0)    -- Rx data buffer
    );
end UART;
 
 
architecture RTL of UART is
 
  type t_SM_Main is (s_Idle, s_Start_bit, s_Data_Bits,
                     s_Stop_Bit, s_Cleanup);
  signal r_TX_SM_Main : t_SM_Main := s_Idle;
 
  signal r_TX_Clk_Count : integer range 0 to g_CLKS_PER_BIT-1 := 0;
  signal r_TX_Bit_Index : integer range 0 to 7 := 0;  -- 8 Bits Total
  signal r_TX_Data   : std_logic_vector(7 downto 0) := (others => '0');
  signal r_TX_Done   : std_logic := '0';
  
  signal r_RX_SM_Main : t_SM_Main := s_Idle;
 
  signal r_RX_Data_R : std_logic := '0';
  signal r_RX_Data   : std_logic := '0';
   
  signal r_RX_Clk_Count : integer range 0 to g_CLKS_PER_BIT-1 := 0;
  signal r_RX_Bit_Index : integer range 0 to 7 := 0;  -- 8 Bits Total
  signal r_RX_Byte   : std_logic_vector(7 downto 0) := (others => '0');
  signal r_RX_DV     : std_logic := '0';
  
  
begin
 
   
  p_UART_TX : process (i_Clk)
  begin
    if rising_edge(i_Clk) then
         
      case r_TX_SM_Main is
 
        when s_Idle =>
          o_TX_Active <= '0';
          o_TX_Serial <= '1';         -- Drive Line High for Idle
          r_TX_Done   <= '0';
          r_TX_Clk_Count <= 0;
          r_TX_Bit_Index <= 0;
 
          if i_TX_DV = '1' then
            r_TX_Data <= i_TX_Byte;
            r_TX_SM_Main <= s_Start_bit;
          else
            r_TX_SM_Main <= s_Idle;
          end if;
 
           
        -- Send out Start Bit. Start bit = 0
        when s_Start_bit =>
          o_TX_Active <= '1';
          o_TX_Serial <= '0';
 
          -- Wait g_CLKS_PER_BIT-1 clock cycles for start bit to finish
          if r_TX_Clk_Count < g_CLKS_PER_BIT-1 then
            r_TX_Clk_Count <= r_TX_Clk_Count + 1;
            r_TX_SM_Main   <= s_Start_bit;
          else
            r_TX_Clk_Count <= 0;
            r_TX_SM_Main   <= s_Data_Bits;
          end if;
 
           
        -- Wait g_CLKS_PER_BIT-1 clock cycles for data bits to finish          
        when s_Data_Bits =>
          o_TX_Serial <= r_TX_Data(r_TX_Bit_Index);
           
          if r_TX_Clk_Count < g_CLKS_PER_BIT-1 then
            r_TX_Clk_Count <= r_TX_Clk_Count + 1;
            r_TX_SM_Main   <= s_Data_Bits;
          else
            r_TX_Clk_Count <= 0;
             
            -- Check if we have sent out all bits
            if r_TX_Bit_Index < 7 then
              r_TX_Bit_Index <= r_TX_Bit_Index + 1;
              r_TX_SM_Main   <= s_Data_Bits;
            else
              r_TX_Bit_Index <= 0;
              r_TX_SM_Main   <= s_Stop_Bit;
            end if;
          end if;
 
 
        -- Send out Stop bit.  Stop bit = 1
        when s_Stop_Bit =>
          o_TX_Serial <= '1';
 
          -- Wait g_CLKS_PER_BIT-1 clock cycles for Stop bit to finish
          if r_TX_Clk_Count < g_CLKS_PER_BIT-1 then
            r_TX_Clk_Count <= r_TX_Clk_Count + 1;
            r_TX_SM_Main   <= s_Stop_Bit;
          else
            r_TX_Done   <= '1';
            r_TX_Clk_Count <= 0;
            r_TX_SM_Main   <= s_Cleanup;
          end if;
 
                   
        -- Stay here 1 clock
        when s_Cleanup =>
          o_TX_Active <= '0';
          r_TX_Done   <= '1';
          r_TX_SM_Main   <= s_Idle;
           
             
        when others =>
          r_TX_SM_Main <= s_Idle;
 
      end case;
    end if;
  end process p_UART_TX;
 
  o_TX_Done <= r_TX_Done;
  
  -- Purpose: Double-register the incoming data.
  -- This allows it to be used in the UART RX Clock Domain.
  -- (It removes problems caused by metastabiliy)
  p_SAMPLE : process (i_Clk)
  begin
    if rising_edge(i_Clk) then
      r_RX_Data_R <= i_RX_Serial;
      r_RX_Data   <= r_RX_Data_R;
    end if;
  end process p_SAMPLE;
   
 
  -- Purpose: Control RX state machine
  p_UART_RX : process (i_Clk)
  begin
    if rising_edge(i_Clk) then
         
      case r_RX_SM_Main is
 
        when s_Idle =>
          r_RX_DV     <= '0';
          r_RX_Clk_Count <= 0;
          r_RX_Bit_Index <= 0;
 
          if r_RX_Data = '0' then       -- Start bit detected
            r_RX_SM_Main <= s_Start_Bit;
          else
            r_RX_SM_Main <= s_Idle;
          end if;
 
           
        -- Check middle of start bit to make sure it's still low
        when s_Start_Bit =>
          if r_RX_Clk_Count = (g_CLKS_PER_BIT-1)/2 then
            if r_RX_Data = '0' then
              r_RX_Clk_Count <= 0;  -- reset counter since we found the middle
              r_RX_SM_Main   <= s_Data_Bits;
            else
              r_RX_SM_Main   <= s_Idle;
            end if;
          else
            r_RX_Clk_Count <= r_RX_Clk_Count + 1;
            r_RX_SM_Main   <= s_Start_Bit;
          end if;
 
           
        -- Wait g_CLKS_PER_BIT-1 clock cycles to sample serial data
        when s_Data_Bits =>
          if r_RX_Clk_Count < g_CLKS_PER_BIT-1 then
            r_RX_Clk_Count <= r_RX_Clk_Count + 1;
            r_RX_SM_Main   <= s_Data_Bits;
          else
            r_RX_Clk_Count            <= 0;
            r_RX_Byte(r_RX_Bit_Index) <= r_RX_Data;
             
            -- Check if we have sent out all bits
            if r_RX_Bit_Index < 7 then
              r_RX_Bit_Index <= r_RX_Bit_Index + 1;
              r_RX_SM_Main   <= s_Data_Bits;
            else
              r_RX_Bit_Index <= 0;
              r_RX_SM_Main   <= s_Stop_Bit;
            end if;
          end if;
 
 
        -- Receive Stop bit.  Stop bit = 1
        when s_Stop_Bit =>
          -- Wait g_CLKS_PER_BIT-1 clock cycles for Stop bit to finish
          if r_RX_Clk_Count < g_CLKS_PER_BIT-1 then
            r_RX_Clk_Count <= r_RX_Clk_Count + 1;
            r_RX_SM_Main   <= s_Stop_Bit;
          else
            r_RX_DV     <= '1';
            r_RX_Clk_Count <= 0;
            r_RX_SM_Main   <= s_Cleanup;
          end if;
 
                   
        -- Stay here 1 clock
        when s_Cleanup =>
          r_RX_SM_Main <= s_Idle;
          r_RX_DV   <= '0';
 
             
        when others =>
          r_RX_SM_Main <= s_Idle;
 
      end case;
    end if;
  end process p_UART_RX;
 
  o_RX_DV   <= r_RX_DV;
  o_RX_Byte <= r_RX_Byte;
   
end RTL;
