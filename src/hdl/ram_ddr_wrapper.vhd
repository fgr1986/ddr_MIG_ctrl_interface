----------------------------------------------------------------------------
----------------------------------------------------------------------------
-- Author:  Fernando García Redondo, fgarcia@die.upm.es
----------------------------------------------------------------------------
----------------------------------------------------------------------------

-- Create Date:    26/07/2017
-- Design Name:    Nexys4 DDR RAM/DDR2/DDR3 Interface
-- Module Name:    ram_ddr_wrapper - behavioral
-- Project Name:   ram_ddr_wrapper
-- Target Devices: Nexys4 DDR Development Board, containing a XC7a100t-1 csg324 device
-- Tool versions:
-- Description:
--
--    IMPORTANT: This ddr_xadc module includes already an xadc instance. Do not instantiate outside.
--    IMPORTANT: If xadc is instantiated outside, use ddr IP (not ddr_xadc) and drive to ddr instance
--    IMPORTANT: the xadc sensed temperature.
--
--
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
-- Libraries
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Project library
library work;
use work.ram_ddr_MIG7_interface_pkg.ALL;

entity ram_ddr_wrapper is
    port (
      -- Common
      clk_200MHz_i           : in    std_logic;
      rst_i                  : in    std_logic;

      -- ram control interface
      ram_rnw_i              : in    std_logic; -- operation to be done  : 0->READ, 1->WRITE
      ram_addr_i             : in    std_logic_vector(c_DATA_ADDRESS_WIDTH-1 downto 0);
      ram_new_instr_i        : in    std_logic; -- cs, '1' starts operation
      ram_new_ack_o          : out   std_logic; -- ack between clk domains
      ram_end_op_i           : in    std_logic; -- '1' ends the current write or read operation
                                                -- for high performance consecutive writes or reads
      ram_rd_ack_o           : out   std_logic;
      ram_rd_valid_o         : out   std_logic;
      ram_wr_ack_o           : out   std_logic;
      ram_data_to_i          : in    std_logic_vector(c_DATA_2_MEM_WIDTH-1 downto 0);
      ram_data_from_o        : out   std_logic_vector(c_DATA_2_MEM_WIDTH-1 downto 0);
      ram_available_o        : out   std_logic; -- when available for a different command
                                                -- write to read, read to write
      init_calib_complete_o  : out   std_logic; -- when calibrated
      -- DDR2 interface
      ddr2_addr              : out   std_logic_vector(c_DDR_ADDRESS_WIDTH-1 downto 0);
      ddr2_ba                : out   std_logic_vector(c_DDR_BANK_WIDTH-1 downto 0);
      ddr2_ras_n             : out   std_logic;
      ddr2_cas_n             : out   std_logic;
      ddr2_we_n              : out   std_logic;
      ddr2_ck_p              : out   std_logic_vector(0 downto 0);
      ddr2_ck_n              : out   std_logic_vector(0 downto 0);
      ddr2_cke               : out   std_logic_vector(0 downto 0);
      ddr2_cs_n              : out   std_logic_vector(0 downto 0);
      ddr2_dm                : out   std_logic_vector(c_DDR_DM_WIDTH-1 downto 0);
      ddr2_odt               : out   std_logic_vector(0 downto 0);
      ddr2_dq                : inout std_logic_vector(c_DDR_DQ_WIDTH-1 downto 0);
      ddr2_dqs_p             : inout std_logic_vector(c_DDR_DQS_WIDTH-1 downto 0);
      ddr2_dqs_n             : inout std_logic_vector(c_DDR_DQS_WIDTH-1 downto 0)

   );
end ram_ddr_wrapper;

architecture behavioral of ram_ddr_wrapper is

------------------------------------------------------------------------
-- Component Declarations
------------------------------------------------------------------------

------------------------------------------------------------------------
-- Component Declarations
------------------------------------------------------------------------
component ddr_xadc
  port (
    -- Inouts
    ddr2_dq              : inout std_logic_vector(c_DDR_DQ_WIDTH-1 downto 0);
    ddr2_dqs_p           : inout std_logic_vector(c_DDR_DQS_WIDTH-1 downto 0);
    ddr2_dqs_n           : inout std_logic_vector(c_DDR_DQS_WIDTH-1 downto 0);
    -- Outputs
    ddr2_addr            : out   std_logic_vector(c_DDR_ADDRESS_WIDTH-1 downto 0);
    ddr2_ba              : out   std_logic_vector(c_DDR_BANK_WIDTH-1 downto 0);
    ddr2_ras_n           : out   std_logic;
    ddr2_cas_n           : out   std_logic;
    ddr2_we_n            : out   std_logic;
    ddr2_ck_p            : out   std_logic_vector(0 downto 0);
    ddr2_ck_n            : out   std_logic_vector(0 downto 0);
    ddr2_cke             : out   std_logic_vector(0 downto 0);
    ddr2_cs_n            : out   std_logic_vector(0 downto 0);
    ddr2_dm              : out   std_logic_vector(c_DDR_DM_WIDTH-1 downto 0);
    ddr2_odt             : out   std_logic_vector(0 downto 0);
    -- Inputs
    sys_clk_i            : in    std_logic;
    sys_rst              : in    std_logic;
    -- user interface signals
    app_addr             : in    std_logic_vector(c_APP_DATA_ADDRESS_WIDTH-1 downto 0);
    app_cmd              : in    std_logic_vector(c_DDR_CMD_WIDTH-1 downto 0);
    app_en               : in    std_logic;
    app_wdf_data         : in    std_logic_vector(c_APP_DATA_WIDTH-1 downto 0);
    app_wdf_end          : in    std_logic;
    app_wdf_mask         : in    std_logic_vector(c_DDR_WDF_MASK_WIDTH-1 downto 0);
    app_wdf_wren         : in    std_logic;
    app_rd_data          : out   std_logic_vector(c_APP_DATA_WIDTH-1 downto 0);
    app_rd_data_end      : out   std_logic;
    app_rd_data_valid    : out   std_logic;
    app_rdy              : out   std_logic;
    app_wdf_rdy          : out   std_logic;
    app_sr_req           : in    std_logic;
    app_sr_active        : out   std_logic;
    app_ref_req          : in    std_logic;
    app_ref_ack          : out   std_logic;
    app_zq_req           : in    std_logic;
    app_zq_ack           : out   std_logic;
    ui_clk               : out   std_logic;
    ui_clk_sync_rst      : out   std_logic;
    -- device_temp_i     : in ...,
    init_calib_complete  : out   std_logic );
end component;

------------------------------------------------------------------------
-- Local Type Declarations
------------------------------------------------------------------------
-- FSM
type state_type is (st_IDLE, st_PREP_OP, st_SEND_WRITE,
                  st_SEND_READ, st_WAIT_NEXT_WRITE, st_WAIT_NEXT_READ);

------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------
constant c_MASK_DIFF  : positive := c_DDR_WDF_MASK_WIDTH - (c_APP_DATA_WIDTH-c_DATA_2_MEM_WIDTH)/8;
--report "The value of 'c_MASK_DIFF' is " & integer'image(c_MASK_DIFF);
constant c_MASK       : std_logic_vector(c_DDR_WDF_MASK_WIDTH-1 downto 0)
                            := (c_DDR_WDF_MASK_WIDTH-1 downto c_MASK_DIFF => '1')
                             & (c_MASK_DIFF-1 downto 0 => '0');
--------------------------------------
-- Signals
--------------------------------------
-- state machine
signal st_state, st_next_state      : state_type;


--  active-low reset for the MIG component
signal s_rstn     : std_logic;
signal s_rst_d2   : std_logic_vector(1 downto 0);

-- double registered imputs
signal s_ram_rnw_pre          : std_logic;
signal s_ram_rnw              : std_logic;
signal s_ram_new_instr        : std_logic;
signal s_ram_new_instr_pre    : std_logic;
signal s_ram_end_op_pre       : std_logic;
signal s_ram_end_op           : std_logic;
signal s_ram_data_to_pre      : std_logic_vector(c_DATA_2_MEM_WIDTH-1 downto 0);
signal s_ram_data_to          : std_logic_vector(c_DATA_2_MEM_WIDTH-1 downto 0);
signal s_ram_addr_pre         : std_logic_vector(c_APP_DATA_ADDRESS_WIDTH-1 downto 0);
----------------------------------------
-- We will use 'mem_ui_' for UI with ddr
-- ddr user interface signals
--------------------------------------
signal mem_ui_clk             : std_logic;
signal mem_ui_rst             : std_logic;
signal mem_ui_addr            : std_logic_vector(c_APP_DATA_ADDRESS_WIDTH-1 downto 0); -- address for current request
signal mem_ui_cmd             : std_logic_vector(c_DDR_CMD_WIDTH-1 downto 0); -- command for current request
signal mem_ui_wdf_rdy         : std_logic; -- write data FIFO is ready to receive data (wdf_rdy = 1 & wdf_wren = 1)
signal mem_ui_wdf_data        : std_logic_vector(c_APP_DATA_WIDTH-1 downto 0);
signal mem_ui_wdf_end         : std_logic; -- active-high last 'wdf_data'
signal mem_ui_wdf_mask        : std_logic_vector(c_DDR_WDF_MASK_WIDTH-1 downto 0);
signal mem_ui_wdf_wren        : std_logic;
signal mem_ui_rd_data         : std_logic_vector(c_APP_DATA_WIDTH-1 downto 0);
signal mem_ui_rd_data_end     : std_logic; -- active-high last 'rd_data'
signal mem_ui_rd_data_valid   : std_logic; -- active-high 'rd_data' valid
signal s_calib_complete       : std_logic; -- active-high calibration complete
-- enables the sending of CMD to the ddr (1 pulse per command)
signal mem_ui_en              : std_logic; -- active-high strobe for 'cmd' and 'addr'

-- if HIGH, the CMD sent when mem_ui_en is HIGH has been accepted
signal mem_ui_rdy             : std_logic;

-- registered ack 1 clk pulses
signal s_ram_rd_ack           : std_logic;
signal s_ram_wr_ack           : std_logic;
------------------------------------------------------------------------
-- Module Implementation
------------------------------------------------------------------------
begin

  ------------------------------------------------------------------------
  -- Registering the active-low reset for the MIG component
  -- delay because of FSM
  ------------------------------------------------------------------------
    p_rst_sync: process(clk_200MHz_i)
    begin
        if rising_edge(clk_200MHz_i) then
          s_rst_d2  <= s_rst_d2(0) & rst_i;
          s_rstn    <= not s_rst_d2(1);
        end if;
    end process p_rst_sync;

  ------------------------------------------------------------------------
  -- DDR controller instance
  ------------------------------------------------------------------------
    inst_ddr_xadc: ddr_xadc
    port map (
        -- IOB outputs [Physical Interface]
        ddr2_dq              => ddr2_dq,
        ddr2_dqs_p           => ddr2_dqs_p,
        ddr2_dqs_n           => ddr2_dqs_n,
        ddr2_addr            => ddr2_addr,
        ddr2_ba              => ddr2_ba,
        ddr2_ras_n           => ddr2_ras_n,
        ddr2_cas_n           => ddr2_cas_n,
        ddr2_we_n            => ddr2_we_n,
        ddr2_ck_p            => ddr2_ck_p,
        ddr2_ck_n            => ddr2_ck_n,
        ddr2_cke             => ddr2_cke,
        ddr2_cs_n            => ddr2_cs_n,
        ddr2_dm              => ddr2_dm,
        ddr2_odt             => ddr2_odt,
        -- Inputs
        sys_clk_i            => clk_200MHz_i,
        sys_rst              => s_rstn,
        -- user interface signals
        app_addr             => mem_ui_addr,
        app_cmd              => mem_ui_cmd,
        app_en               => mem_ui_en,
        app_wdf_data         => mem_ui_wdf_data,
        app_wdf_end          => mem_ui_wdf_end,
        app_wdf_mask         => mem_ui_wdf_mask,
        app_wdf_wren         => mem_ui_wdf_wren,
        app_rd_data          => mem_ui_rd_data,
        app_rd_data_end      => mem_ui_rd_data_end,
        app_rd_data_valid    => mem_ui_rd_data_valid,
        app_rdy              => mem_ui_rdy,
        app_wdf_rdy          => mem_ui_wdf_rdy,
        app_sr_req           => '0', -- see UG586
        app_sr_active        => open,
        app_ref_req          => '0', -- see UG586
        app_ref_ack          => open,
        app_zq_req           => '0', -- see UG586
        app_zq_ack           => open,
        ui_clk               => mem_ui_clk,  -- 1/2 or 1/4 of 200Mhz clk, see UG586
        ui_clk_sync_rst      => mem_ui_rst,
        -- device_temp_i        => device_temp_i,
        init_calib_complete  => s_calib_complete
    );

    ------------------------------------------------------------------------
    -- Registering handshake ack
    ------------------------------------------------------------------------
    p_new_instr_ack: process(mem_ui_clk)
    begin
        if rising_edge(mem_ui_clk) then
            if mem_ui_rst='1' or s_calib_complete='0' then
                ram_new_ack_o <= '0';
            else
                ram_new_ack_o <= ram_new_instr_i;
            end if;
        end if;
    end process p_new_instr_ack;

    ------------------------------------------------------------------------
    -- Double Registering all ctrl inputs to 'mem_ui_clk' domain
    ------------------------------------------------------------------------
    p_reg_in_ctrl: process(mem_ui_clk)
    begin
        if rising_edge(mem_ui_clk) then
            if mem_ui_rst='1' then
                -- pre-signals
                s_ram_rnw_pre         <= '0';
                s_ram_new_instr_pre   <= '0';
                s_ram_end_op_pre      <= '0';
                -- valid signals (faster domain)
                s_ram_rnw           <= '0';
                s_ram_new_instr     <= '0';
                s_ram_end_op        <= '0';
            else
                -- pre-signals
                s_ram_rnw_pre         <= ram_rnw_i;
                s_ram_new_instr_pre   <= ram_new_instr_i;
                s_ram_end_op_pre      <= ram_end_op_i;
                -- valid signals (faster domain)
                s_ram_rnw           <= s_ram_rnw_pre;
                s_ram_new_instr     <= s_ram_new_instr_pre;
                s_ram_end_op        <= s_ram_end_op_pre;
            end if;
        end if;
    end process p_reg_in_ctrl;

    ------------------------------------------------------------------------
    -- Double Registering all data inputs to 'mem_ui_clk' domain
    ------------------------------------------------------------------------
    p_reg_in_data: process(mem_ui_clk)
    begin
        if rising_edge(mem_ui_clk) then
            if mem_ui_rst='1' then
                -- pre-signals
                s_ram_addr_pre      <= (others => '0');
                s_ram_data_to_pre   <= (others => '0');
                -- valid signals (faster domain)
                mem_ui_addr         <= (others => '0');
                s_ram_data_to       <= (others => '0');
            else
                -- pre-signals
                s_ram_addr_pre      <= '0' & ram_addr_i; -- rank in DDR2 MT47H64M16HR-25 is '0'
                s_ram_data_to_pre   <= ram_data_to_i;
                -- valid signals (faster domain)
                mem_ui_addr         <= s_ram_addr_pre;
                s_ram_data_to       <= s_ram_data_to_pre;
            end if;
        end if;
    end process p_reg_in_data;

    ------------------------------------------------------------------------
    -- State Machine
    ------------------------------------------------------------------------
    -- Register states
    p_sync_FSM: process(mem_ui_clk)
    begin
      if rising_edge(mem_ui_clk) then
         if mem_ui_rst = '1' then
            st_state <= st_IDLE;
         else
            st_state <= st_next_state;
         end if;
      end if;
    end process p_sync_FSM;

    -- Next state logic
    p_next_state: process(st_state, s_calib_complete, s_ram_new_instr,
      s_ram_rnw, mem_ui_rdy, mem_ui_wdf_rdy, s_ram_end_op)
    begin
        st_next_state <= st_state;
        case(st_state) is
           -- If calibration is done successfully
            when st_IDLE =>
                -- comment for simulation
                if s_calib_complete = '1' then
                    st_next_state <= st_PREP_OP;
                end if;
            -- In st_PREP_OP We store address (for write/read) and data (for write)
            -- operates if conditions are met
            when st_PREP_OP =>
                if s_ram_new_instr = '1' then
                    if s_ram_rnw = '1' then
                        st_next_state <= st_SEND_WRITE;
                    elsif s_ram_rnw = '0' then
                        st_next_state <= st_SEND_READ;
                    end if;
                end if;
            -- We send write the command until accepted (mem_ui_rdy = '1')
            when st_SEND_WRITE =>
                -- end operation if s_ram_new_instr (registered for delay) is deaserted
                if mem_ui_rdy = '1' and mem_ui_wdf_rdy='1' then
                    st_next_state <= st_WAIT_NEXT_WRITE;
                elsif s_ram_end_op = '1' then
                    st_next_state <= st_PREP_OP;
                end if;
            when st_WAIT_NEXT_WRITE =>
                if s_ram_new_instr = '1' then
                    st_next_state <= st_SEND_WRITE;
                elsif s_ram_end_op = '1' then
                    st_next_state <= st_PREP_OP;
                end if;
            -- We send write the command until accepted (mem_ui_rdy = '1')
            when st_SEND_READ =>
                -- end operation if s_ram_new_instr (registered for delay) is deaserted
                if mem_ui_rdy = '1' then
                    st_next_state <= st_WAIT_NEXT_READ;
                elsif s_ram_end_op = '1' then
                    st_next_state <= st_PREP_OP;
                end if;
            when st_WAIT_NEXT_READ =>
                if s_ram_new_instr = '1' then
                    st_next_state <= st_SEND_READ;
                elsif s_ram_end_op = '1' then
                    st_next_state <= st_PREP_OP;
                end if;
            when others => st_next_state <= st_IDLE;
        end case;
    end process;

    ---------------------------------------------------------------
    -- Memory control
    -- Creates mem_ui_en pulse
    ---------------------------------------------------------------
    p_mem_ctrl: process(st_state, mem_ui_wdf_rdy)
    begin
        if st_state = st_SEND_WRITE then
            mem_ui_en  <= mem_ui_wdf_rdy;  -- send control command only if wdf_data can be loaded in fifo
                                           -- until mem_ui_rdy
        elsif st_state = st_SEND_READ then
            mem_ui_en  <= '1';
        else
            mem_ui_en  <= '0';
        end if;
    end process p_mem_ctrl;

    ---------------------------------------------------------------
    -- Memory control 2
    -- Controls CMD Message
    ---------------------------------------------------------------
    p_mem_ctrl_2: process(st_state)
    begin
        -- select command
        if st_state = st_SEND_WRITE then
            mem_ui_cmd <= c_CMD_WRITE;
        elsif st_state = st_SEND_READ then
            mem_ui_cmd <= c_CMD_READ;
        else
            mem_ui_cmd <= c_CMD_READ;
        end if;
    end process p_mem_ctrl_2;

    ------------------------------------------------------------------------
    -- Generating the FIFO control and command signals according to the
    -- current state of the FSM
    ------------------------------------------------------------------------
    p_mem_ctrl_3: process(st_state, mem_ui_wdf_rdy, s_ram_data_to )
    begin
        if st_state = st_SEND_WRITE and mem_ui_wdf_rdy='1' then
            mem_ui_wdf_data     <= (c_APP_DATA_WIDTH-1 downto s_ram_data_to'length => '0') & s_ram_data_to;
            mem_ui_wdf_end      <= '1';
            mem_ui_wdf_mask     <= c_MASK;
            mem_ui_wdf_wren     <= '1';
        elsif st_state = st_SEND_READ then
            mem_ui_wdf_data     <= (others => '0');
            mem_ui_wdf_end      <= '0';
            mem_ui_wdf_mask     <= (others => '1');
            mem_ui_wdf_wren     <= '0';
        else
            mem_ui_wdf_data   <= (others => '0');
            mem_ui_wdf_end    <= '0';
            mem_ui_wdf_mask   <= (others => '1');
            mem_ui_wdf_wren   <= '0';
        end if;
    end process p_mem_ctrl_3;

    ------------------------------------------
    -- ACK signals if registered at outputs
    ------------------------------------------
    p_ack_ctrl: process(st_state, mem_ui_en, mem_ui_rdy)
    begin
        s_ram_wr_ack   <= '0';
        s_ram_rd_ack   <= '0';
        case(st_state) is
            when st_SEND_WRITE =>
                if mem_ui_en='1' and mem_ui_rdy='1' then
                    s_ram_wr_ack   <= '1';
                else
                    s_ram_wr_ack   <= '0';
                end if;
                s_ram_rd_ack       <= '0';
            when st_SEND_READ =>
                if mem_ui_en='1' and mem_ui_rdy='1' then
                    s_ram_rd_ack   <= '1';
                else
                    s_ram_rd_ack   <= '0';
                end if;
                s_ram_wr_ack       <= '0';
            when others =>
                s_ram_wr_ack   <= '0';
                s_ram_rd_ack   <= '0';
        end case;
    end process p_ack_ctrl;


    ------------------------------------------------------------------------
    -- Registering all outputs of the state machine to 'mem_ui_clk' domain
    ------------------------------------------------------------------------
    p_reg_out: process(mem_ui_clk)
    begin
        if rising_edge(mem_ui_clk) then
            if mem_ui_rst='1' or s_calib_complete='0' then
                ram_rd_ack_o          <= '0';
                ram_wr_ack_o          <= '0';
                ram_data_from_o       <= (others => '0');
                ram_available_o       <= '0';
                init_calib_complete_o <= '0';
            else
                ram_rd_ack_o          <= s_ram_rd_ack;
                ram_wr_ack_o          <= s_ram_wr_ack;
                -- if mem_ui_rd_data_end='0' then -- mem_ui_rd_data_end high erases contents on mem_ui_rd_data
                  ram_rd_valid_o        <= mem_ui_rd_data_valid;
                  ram_data_from_o       <= mem_ui_rd_data(ram_data_from_o'length-1 downto 0);
                -- end if;
                if st_state = st_PREP_OP then
                  ram_available_o     <= '1';
                else
                  ram_available_o     <= '0';
                end if;
                init_calib_complete_o <= s_calib_complete;
            end if;
        end if;
    end process p_reg_out;

end behavioral;
