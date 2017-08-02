----------------------------------------------------------------------------
----------------------------------------------------------------------------
-- Author:  Fernando García Redondo, fgarcia@die.upm.es
----------------------------------------------------------------------------
----------------------------------------------------------------------------

-- Create Date:    15:45:01 20/07/2017
-- Design Name:    Nexys4 DDR UPM VHDL Lab Project
-- Module Name:    memory_ctrl - behavioral
-- Project Name:   UPM VHDL Lab Project
-- Target Devices: Nexys4 DDR Development Board, containing a XC7a100t-1 csg324 device
-- Tool versions:
-- Description:
-- This project represents the basic project for the VHDL Lab at ETSIT UPM regarding ddr memories.
-- It, saves and reads secuential data in the DDR2 memory (out of the FPGA).
--
-- For simplicity, the DDR memory is working at 300Mhz (using a 200Mhz input clk),
-- and a PHY to Controller Clock Ratio of **4:1** with **BL8**.
-- **IMPORTANT** By doing so the ddr's **ui_clk** signal needs to be synchronized with the main 100Mhz clk.
-- We use a double reg approach together with handshake protocols (see Advanced FPGA design, Steve Kilts).
-- Double reg approach should be used between slower and faster domains.
--
-- The 200Mhz signal is generated using CLKGEN component (100Mhz output phase set at 0º to sync with 200MHz output).
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------
-- Libraries
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Project library
library work;
use work.ram_ddr_MIG7_interface_pkg.ALL;


entity memory_ctrl is
   port(
      clk_100MHz_i          : in  std_logic;
      rstn_i                : in  std_logic;
      init_calib_complete_o : out std_logic; -- when calibrated
      -- DDR2 interface signals
      ddr2_addr             : out   std_logic_vector(12 downto 0);
      ddr2_ba               : out   std_logic_vector(2 downto 0);
      ddr2_ras_n            : out   std_logic;
      ddr2_cas_n            : out   std_logic;
      ddr2_we_n             : out   std_logic;
      ddr2_ck_p             : out   std_logic_vector(0 downto 0);
      ddr2_ck_n             : out   std_logic_vector(0 downto 0);
      ddr2_cke              : out   std_logic_vector(0 downto 0);
      ddr2_cs_n             : out   std_logic_vector(0 downto 0);
      ddr2_dm               : out   std_logic_vector(1 downto 0);
      ddr2_odt              : out   std_logic_vector(0 downto 0);
      ddr2_dq               : inout std_logic_vector(15 downto 0);
      ddr2_dqs_p            : inout std_logic_vector(1 downto 0);
      ddr2_dqs_n            : inout std_logic_vector(1 downto 0)

   );
end memory_ctrl;

architecture behavioral of memory_ctrl is

----------------------------------------------------------------------------------
-- Component Declarations
----------------------------------------------------------------------------------

-- 200 MHz Clock Generator
component ClkGen
    port (
        -- Clock in ports
        clk_100MHz_i        : in     std_logic;
        -- Clock out ports
        clk_100MHz_o        : out    std_logic;
        clk_200MHz_o        : out    std_logic;
        -- Status and control signals
        reset_i             : in     std_logic;
        locked_o            : out    std_logic
    );
end component;


component ram_ddr_wrapper is
    port (
        -- Common
        -- clk_100MHz_i         : in    std_logic;
        clk_200MHz_i              : in    std_logic;
        -- device_temp_i        : in    std_logic_vector(11 downto 0);
        rst_i                     : in    std_logic;
        -- ram control interface
        ram_rnw_i                 : in    std_logic; -- operation to be done: 0->READ, 1->WRITE
        ram_addr_i                : in    std_logic_vector(c_DATA_ADDRESS_WIDTH-1 downto 0);
        ram_new_instr_i           : in    std_logic; -- cs, '1' starts operation
        ram_new_ack_o             : out   std_logic; -- ack between clk domains
        ram_end_op_i              : in    std_logic; -- '1' ends the current write or read operation
                                                     -- for high performance consecutive writes or reads
        ram_rd_ack_o              : out   std_logic;
        ram_rd_valid_o            : out   std_logic;
        ram_wr_ack_o              : out   std_logic;
        ram_data_to_i             : in    std_logic_vector(c_DATA_2_MEM_WIDTH-1 downto 0);
        ram_data_from_o           : out   std_logic_vector(c_DATA_2_MEM_WIDTH-1 downto 0);
        ram_available_o           : out   std_logic; -- when ready to next command
        init_calib_complete_o     : out   std_logic; -- when calibrated
        -- DDR2 interface
        ddr2_addr                 : out   std_logic_vector(12 downto 0);
        ddr2_ba                   : out   std_logic_vector(2 downto 0);
        ddr2_ras_n                : out   std_logic;
        ddr2_cas_n                : out   std_logic;
        ddr2_we_n                 : out   std_logic;
        ddr2_ck_p                 : out   std_logic_vector(0 downto 0);
        ddr2_ck_n                 : out   std_logic_vector(0 downto 0);
        ddr2_cke                  : out   std_logic_vector(0 downto 0);
        ddr2_cs_n                 : out   std_logic_vector(0 downto 0);
        ddr2_dm                   : out   std_logic_vector(1 downto 0);
        ddr2_odt                  : out   std_logic_vector(0 downto 0);
        ddr2_dq                   : inout std_logic_vector(15 downto 0);
        ddr2_dqs_p                : inout std_logic_vector(1 downto 0);
        ddr2_dqs_n                : inout std_logic_vector(1 downto 0)
    );
end component;


------------------------------------------------------------------------
-- Local Type Declarations
------------------------------------------------------------------------
-- FSM
type state_type is (st_IDLE, st_SEND_WRITE, st_WAIT_WRITE_ACK,
                    st_SEND_READ, st_WAIT_READ_ACK, st_CHANGE, st_END);

--------------------------------------
-- constants
--------------------------------------
constant c_END_WRITE_CLK      : positive  := 2;
constant c_END_READ_CLK       : positive  := 2;
constant c_DATA_OFFSET        : integer   := 0;
--------------------------------------
-- Signals
--------------------------------------

-- state machine
signal st_state, st_next_state      : state_type;

----------------------------------------------------------------------------------
-- Signal Declarations
----------------------------------------------------------------------------------
-- Inverted input reset signal
signal s_rst                      : std_logic;
-- Reset signal conditioned by the PLL lock
signal s_reset                    : std_logic;
signal s_resetn                   : std_logic;
signal s_locked                   : std_logic;

-- 100 MHz buffered clock signal
signal clk_100MHz_buf             : std_logic;
-- 200 MHz buffered clock signal
signal clk_200MHz_buf             : std_logic;

-- signals interfacing ram_ddr_wrapper
-- registered control signals for clk domain changes
signal s_ram_rd_ack_pre           : std_logic;
signal s_ram_rd_valid_pre         : std_logic;
signal s_ram_wr_ack_pre           : std_logic;
signal s_ram_available_pre        : std_logic;
signal s_init_calib_complete_pre  : std_logic;
-- second register
signal s_ram_rd_ack_pre2          : std_logic;
signal s_ram_rd_valid_pre2        : std_logic;
signal s_ram_wr_ack_pre2          : std_logic;
signal s_ram_available_pre2       : std_logic;
signal s_init_calib_complete_pre2 : std_logic;
-- registered data signals for clk domain changes
signal s_ram_data_from_pre        : std_logic_vector(c_DATA_2_MEM_WIDTH-1 downto 0);
signal s_ram_data_from_pre2       : t_DATA_OUT_MEM;

-- Signals to be used safely
signal s_init_calib_complete      : std_logic;
signal s_ram_rnw                  : std_logic; -- operation to be done: 0->READ, 1->WRITE
signal s_ram_addr                 : std_logic_vector(c_DATA_ADDRESS_WIDTH-1 downto 0);
signal s_ram_new_instr            : std_logic; -- cs, '1' starts operation
signal s_ram_new_ack              : std_logic; -- cs ack, between clk domains
                                               -- does not need to be registered, as only triggers change of state
signal s_ram_end_op               : std_logic; -- end of operation
signal s_ram_available            : std_logic;
signal s_ram_rd_ack               : std_logic;
signal s_ram_rd_valid             : std_logic;
signal s_ram_wr_ack               : std_logic;
signal s_ram_data_to              : std_logic_vector(c_DATA_2_MEM_WIDTH-1 downto 0);
signal s_ram_data_from            : t_DATA_OUT_MEM;

signal cnt_en                     : std_logic;
signal cnt_counter                : unsigned(c_DATA_WIDTH-1 downto 0);

begin

  -----------------------
  -- Reset Generation
  -----------------------
  -- The Reset Button on the Nexys4 board is active-low,
  -- however many components need an active-high reset
  s_rst <= not rstn_i;

  -- Assign reset signals conditioned by the PLL lock
  s_reset <= s_rst or (not s_locked);
  -- active-low version of the reset signal
  s_resetn <= not s_reset;


----------------------------------------------------------------------------------
-- 200MHz Clock Generator
----------------------------------------------------------------------------------
   inst_ClkGen: ClkGen
   port map (
      clk_100MHz_i   => clk_100MHz_i,
      clk_100MHz_o   => clk_100MHz_buf,
      clk_200MHz_o   => clk_200MHz_buf,
      reset_i        => s_rst,
      locked_o       => s_locked
      );

----------------------------------------------------------------------------------
-- ram_ddr_wrapper
----------------------------------------------------------------------------------
   inst_ram_ddr_wrapper: ram_ddr_wrapper
   port map(
      -- clk_100MHz_i         => clk_100MHz_buf,
      clk_200MHz_i         => clk_200MHz_buf,
      rst_i                => s_reset,

      -- ram control interface
      ram_rnw_i               => s_ram_rnw,
      ram_addr_i              => s_ram_addr,
      ram_new_instr_i         => s_ram_new_instr,
      ram_new_ack_o           => s_ram_new_ack,
      ram_end_op_i            => s_ram_end_op,
      ram_rd_ack_o            => s_ram_rd_ack_pre,
      ram_rd_valid_o          => s_ram_rd_valid_pre,
      ram_wr_ack_o            => s_ram_wr_ack_pre,
      ram_data_to_i           => s_ram_data_to,
      ram_data_from_o         => s_ram_data_from_pre,
      ram_available_o         => s_ram_available_pre,
      init_calib_complete_o   => s_init_calib_complete_pre,

      -- DDR2 signals
      ddr2_dq        => ddr2_dq,
      ddr2_dqs_p     => ddr2_dqs_p,
      ddr2_dqs_n     => ddr2_dqs_n,
      ddr2_addr      => ddr2_addr,
      ddr2_ba        => ddr2_ba,
      ddr2_ras_n     => ddr2_ras_n,
      ddr2_cas_n     => ddr2_cas_n,
      ddr2_we_n      => ddr2_we_n,
      ddr2_ck_p      => ddr2_ck_p,
      ddr2_ck_n      => ddr2_ck_n,
      ddr2_cke       => ddr2_cke,
      ddr2_cs_n      => ddr2_cs_n,
      ddr2_dm        => ddr2_dm,
      ddr2_odt       => ddr2_odt
   );

    ------------------------------------------------------------------------
    -- State Machine
    ------------------------------------------------------------------------
    -- Register states
    p_sync_FSM: process(clk_100MHz_buf, s_reset)
    begin
        if s_reset = '1' then
           st_state <= st_IDLE;
        elsif rising_edge(clk_100MHz_buf) then
            st_state <= st_next_state;
        end if;
    end process p_sync_FSM;

    -- Next state logic
    p_next_state: process(st_state, s_ram_available, cnt_counter,
                          s_ram_wr_ack, s_ram_rd_ack, s_ram_new_ack)
    begin
        st_next_state <= st_state;
        case(st_state) is
            -- If calibration is done successfully
            when st_IDLE =>
                if s_ram_available = '1' then
                    st_next_state <= st_SEND_WRITE;
                end if;
            when st_SEND_WRITE =>
                if cnt_counter > c_END_WRITE_CLK-1 then
                    st_next_state <= st_CHANGE;
                elsif s_ram_new_ack = '1' then
                    st_next_state <= st_WAIT_WRITE_ACK;
                end if;
            when st_WAIT_WRITE_ACK =>
                if s_ram_wr_ack = '1' then
                    st_next_state <= st_SEND_WRITE;
                end if;
            when st_CHANGE =>
                if s_ram_available = '1' then
                    st_next_state <= st_SEND_READ;
                end if;
             -- We send the command
            when st_SEND_READ =>
                if cnt_counter > c_END_READ_CLK-1 then
                    st_next_state <= st_END;
                elsif s_ram_new_ack = '1' then
                    st_next_state <= st_WAIT_READ_ACK;
                end if;
            when st_WAIT_READ_ACK =>
                if s_ram_rd_ack = '1' then
                    st_next_state <= st_SEND_READ;
                end if;
            when st_END => -- nothing
                -- st_next_state <= st_END;
            when others => st_next_state <= st_IDLE;
        end case;
    end process;

    -------------
    -- Counter
    -------------
    p_counter: process (clk_100MHz_buf, s_reset)
    begin
        if (s_reset = '1') then
              cnt_counter <= (others => '0');
        elsif (rising_edge (clk_100MHz_buf)) then
            if (st_state = st_CHANGE) then
                cnt_counter <= (others => '0');
            elsif cnt_en = '1' then
                cnt_counter <= cnt_counter + 1;
            end if;
        end if;
    end process p_counter;

    -- counter enable, including ack response
    p_counter_en: process (clk_100MHz_buf, s_reset)
    begin
        if (s_reset = '1') then
              cnt_en    <= '0';
        elsif (rising_edge (clk_100MHz_buf)) then
            if (st_state = st_SEND_WRITE or st_state = st_SEND_READ) then
                if cnt_en = '0' then
                    cnt_en    <= '1';
                else
                    cnt_en    <= '0';
                end if;
            else
                cnt_en    <= '0';
            end if;
        end if;
    end process p_counter_en;

    -- Control signals
    p_control:process(st_state, cnt_counter)
    begin
        s_ram_new_instr     <= '0';
        s_ram_end_op        <= '0';
        s_ram_rnw           <= '0';
        case(st_state) is
            when st_IDLE =>
                s_ram_new_instr   <= '0';
                s_ram_end_op      <= '0';
                s_ram_rnw         <= '0';
            when st_SEND_WRITE =>
                s_ram_new_instr   <= '1';
                s_ram_end_op      <= '0';
                s_ram_rnw         <= '1';
            when st_WAIT_WRITE_ACK =>
                s_ram_new_instr   <= '0';
                s_ram_end_op      <= '0';
                -- maintain previous data and controls but new_instr
                s_ram_rnw         <= '1';
            when st_CHANGE =>
                s_ram_new_instr   <= '0';
                s_ram_end_op      <= '1';
                s_ram_rnw         <= '0';
            when st_SEND_READ =>
                s_ram_new_instr   <= '1';
                s_ram_end_op      <= '0';
                s_ram_rnw         <= '0';
            when st_WAIT_READ_ACK =>
                s_ram_new_instr   <= '0';
                s_ram_end_op      <= '0';
                s_ram_rnw         <= '0';
            when st_END =>
                s_ram_new_instr   <= '0';
                s_ram_end_op      <= '1';
                s_ram_rnw         <= '0';
            when others =>
                s_ram_new_instr   <= '0';
                s_ram_end_op      <= '0';
                s_ram_rnw         <= '0';
        end case;
    end process p_control;

    -- Control signals
    p_data_addr:process(st_state, cnt_counter)
    begin
        s_ram_addr          <= (others => '0');
        s_ram_data_to       <= (others => '0');
        case(st_state) is
            when st_IDLE =>
                s_ram_addr        <= (others => '0');
                s_ram_data_to     <= (others => '0');
            when st_SEND_WRITE =>
                -- update address according to c_ADDR_INC
                s_ram_addr        <= std_logic_vector( resize(c_ADDR_INC*cnt_counter, s_ram_addr'length) );
                -- send up to c_WORDS_2_MEM words each time,  based on counter
                data_to_wr: for w in 0 to c_WORDS_2_MEM-1 loop
                    s_ram_data_to((w+1)*c_DATA_WIDTH-1 downto w*c_DATA_WIDTH) <= std_logic_vector( resize(c_WORDS_2_MEM*cnt_counter + w, c_DATA_WIDTH));
                end loop data_to_wr;
            when st_WAIT_WRITE_ACK =>
                s_ram_addr        <= (others => '0');
                s_ram_data_to     <= (others => '0');
            when st_CHANGE =>
                s_ram_addr        <= (others => '0');
                s_ram_data_to     <= (others => '0');
            when st_SEND_READ =>
                s_ram_addr        <= std_logic_vector( resize(c_ADDR_INC*cnt_counter, s_ram_addr'length) );
                s_ram_data_to     <= (others => '0');
            when st_WAIT_READ_ACK =>
                s_ram_addr        <= (others => '0');
                s_ram_data_to     <= (others => '0');
            when st_END =>
                s_ram_addr        <= (others => '0');
                s_ram_data_to     <= (others => '0');
            when others =>
                s_ram_addr        <= (others => '0');
                s_ram_data_to     <= (others => '0');
        end case;
    end process p_data_addr;

    ------------------------------------------------------------------------
    -- Register Data From Memory for CLK Domain change
    ------------------------------------------------------------------------
    p_reg_memory_outs_ctrl: process (clk_100MHz_buf, s_reset)
    begin
        if (s_reset = '1') then
            s_ram_rd_ack_pre2           <= '0';
            s_ram_rd_valid_pre2         <= '0';
            s_ram_wr_ack_pre2           <= '0';
            s_ram_available_pre2        <= '0';
            s_init_calib_complete_pre2  <= '0';
            s_ram_rd_ack                <= '0';
            s_ram_rd_valid              <= '0';
            s_ram_wr_ack                <= '0';
            s_ram_available             <= '0';
            s_init_calib_complete       <= '0';
        elsif (rising_edge (clk_100MHz_buf)) then
            -- first reg stage
            s_ram_rd_ack_pre2           <= s_ram_rd_ack_pre;
            s_ram_rd_valid_pre2         <= s_ram_rd_valid_pre;
            s_ram_wr_ack_pre2           <= s_ram_wr_ack_pre;
            s_ram_available_pre2        <= s_ram_available_pre;
            s_init_calib_complete_pre2  <= s_init_calib_complete_pre;
            -- second reg stage
            s_ram_rd_ack                <= s_ram_rd_ack_pre2;
            s_ram_rd_valid              <= s_ram_rd_valid_pre2;
            s_ram_wr_ack                <= s_ram_wr_ack_pre2;
            s_ram_available             <= s_ram_available_pre2;
            s_init_calib_complete       <= s_init_calib_complete_pre2;
        end if;
    end process p_reg_memory_outs_ctrl;

    p_reg_memory_outs_data: process (clk_100MHz_buf, s_reset)
    begin
        if (s_reset = '1') then
            -- restore up to c_WORDS_2_MEM words each time
            data_from_rst: for w in 0 to c_WORDS_2_MEM-1 loop
                s_ram_data_from_pre2(w)  <= (others => '0');
                s_ram_data_from(w)       <= (others => '0');
            end loop data_from_rst;
        elsif (rising_edge (clk_100MHz_buf)) then
            if s_ram_rd_valid = '1' then
                -- restore up to c_WORDS_2_MEM words each time
                data_from: for w in 0 to c_WORDS_2_MEM-1 loop
                    s_ram_data_from_pre2(w)  <= s_ram_data_from_pre((w+1)*c_DATA_WIDTH-1 downto w*c_DATA_WIDTH);
                    s_ram_data_from(w)       <= s_ram_data_from_pre2(w);
                end loop data_from;
            end if;
        end if;
    end process p_reg_memory_outs_data;

    -----------------------
    -- Outputs connections
    -----------------------
    -- ram_available_o
    init_calib_complete_o <= s_init_calib_complete;

end behavioral;
