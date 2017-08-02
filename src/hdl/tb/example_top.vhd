--*****************************************************************************
-- (c) Copyright 2009 - 2012 Xilinx, Inc. All rights reserved.
--
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
--
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
--
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
--
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
--
--*****************************************************************************
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor             : Xilinx
-- \   \   \/     Version            : 4.0
--  \   \         Application        : MIG
--  /   /         Filename           : example_top.vhd
-- /___/   /\     Date Last Modified : $Date: 2011/06/02 08:35:03 $
-- \   \  /  \    Date Created       : Wed Feb 01 2012
--  \___\/\___\
--
-- Device           : 7 Series
-- Design Name      : DDR2 SDRAM
-- Purpose          :
--   Top-level  module. This module serves as an example,
--   and allows the user to synthesize a self-contained design,
--   which they can be used to test their hardware.
--   In addition to the memory controller, the module instantiates:
--     1. Synthesizable testbench - used to model user's backend logic
--        and generate different traffic patterns
-- Reference        :
-- Revision History :
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity example_top is
  generic (

   --***************************************************************************
   -- Traffic Gen related parameters
   --***************************************************************************
   BL_WIDTH              : integer := 10;
   PORT_MODE             : string  := "BI_MODE";
   DATA_MODE             : std_logic_vector(3 downto 0) := "0010";
   ADDR_MODE             : std_logic_vector(3 downto 0) := "0011";
   TST_MEM_INSTR_MODE    : string  := "R_W_INSTR_MODE";
   EYE_TEST              : string  := "FALSE";
                                     -- set EYE_TEST = "TRUE" to probe memory
                                     -- signals. Traffic Generator will only
                                     -- write to one single location and no
                                     -- read transactions will be generated.
   DATA_PATTERN          : string  := "DGEN_ALL";
                                      -- For small devices, choose one only.
                                      -- For large device, choose "DGEN_ALL"
                                      -- "DGEN_HAMMER", "DGEN_WALKING1",
                                      -- "DGEN_WALKING0","DGEN_ADDR","
                                      -- "DGEN_NEIGHBOR","DGEN_PRBS","DGEN_ALL"
   CMD_PATTERN           : string  := "CGEN_ALL";
                                      -- "CGEN_PRBS","CGEN_FIXED","CGEN_BRAM",
                                      -- "CGEN_SEQUENTIAL", "CGEN_ALL"
   BEGIN_ADDRESS         : std_logic_vector(31 downto 0) := X"00000000";
   END_ADDRESS           : std_logic_vector(31 downto 0) := X"00ffffff";
   MEM_ADDR_ORDER        : string  := "BANK_ROW_COLUMN";
                                      --Possible Parameters
                                      --1.BANK_ROW_COLUMN : Address mapping is
                                      --                    in form of Bank Row Column.
                                      --2.ROW_BANK_COLUMN : Address mapping is
                                      --                    in the form of Row Bank Column.
                                      --3.TG_TEST : Scrambles Address bits
                                      --            for distributed Addressing.
   PRBS_EADDR_MASK_POS   : std_logic_vector(31 downto 0) := X"ff000000";
   CMD_WDT               : std_logic_vector(31 downto 0) := X"000003ff";
   WR_WDT                : std_logic_vector(31 downto 0) := X"00001fff";
   RD_WDT                : std_logic_vector(31 downto 0) := X"000003ff";

   --***************************************************************************
   -- The following parameters refer to width of various ports
   --***************************************************************************
   BANK_WIDTH            : integer := 3;
                                     -- # of memory Bank Address bits.
   COL_WIDTH             : integer := 10;
                                     -- # of memory Column Address bits.
   CS_WIDTH              : integer := 1;
                                     -- # of unique CS outputs to memory.
   DQ_WIDTH              : integer := 16;
                                     -- # of DQ (data)
   DQS_WIDTH             : integer := 2;
   DQS_CNT_WIDTH         : integer := 1;
                                     -- = ceil(log2(DQS_WIDTH))
   DRAM_WIDTH            : integer := 8;
                                     -- # of DQ per DQS
   ECC_TEST              : string  := "OFF";
   RANKS                 : integer := 1;
                                     -- # of Ranks.
   ROW_WIDTH             : integer := 13;
                                     -- # of memory Row Address bits.
   ADDR_WIDTH            : integer := 27;
                                     -- # = RANK_WIDTH + BANK_WIDTH
                                     --     + ROW_WIDTH + COL_WIDTH;
                                     -- Chip Select is always tied to low for
                                     -- single rank devices
   --***************************************************************************
   -- The following parameters are mode register settings
   --***************************************************************************
   BURST_MODE            : string  := "8";
                                     -- DDR3 SDRAM:
                                     -- Burst Length (Mode Register 0).
                                     -- # = "8", "4", "OTF".
                                     -- DDR2 SDRAM:
                                     -- Burst Length (Mode Register).
                                     -- # = "8", "4".
   --***************************************************************************
   -- Simulation parameters
   --***************************************************************************
   SIMULATION            : string  := "FALSE";
                                     -- Should be TRUE during design simulations and
                                     -- FALSE during implementations

   --***************************************************************************
   -- IODELAY and PHY related parameters
   --***************************************************************************
   TCQ                   : integer := 100;

   DRAM_TYPE             : string  := "DDR2";


   --***************************************************************************
   -- System clock frequency parameters
   --***************************************************************************
   nCK_PER_CLK           : integer := 4;
                                     -- # of memory CKs per fabric CLK

   --***************************************************************************
   -- Debug parameters
   --***************************************************************************
   DEBUG_PORT            : string  := "OFF";
                                     -- # = "ON" Enable debug signals/controls.
                                     --   = "OFF" Disable debug signals/controls.

   --***************************************************************************
   -- Temparature monitor parameter
   --***************************************************************************
   TEMP_MON_CONTROL         : string  := "INTERNAL"
                                     -- # = "INTERNAL", "EXTERNAL"

--   RST_ACT_LOW           : integer := 1
                                     -- =1 for active low reset,
                                     -- =0 for active high.
   );
  port (

   -- Inouts
   ddr2_dq                        : inout std_logic_vector(15 downto 0);
   ddr2_dqs_p                     : inout std_logic_vector(1 downto 0);
   ddr2_dqs_n                     : inout std_logic_vector(1 downto 0);

   -- Outputs
   ddr2_addr                      : out   std_logic_vector(12 downto 0);
   ddr2_ba                        : out   std_logic_vector(2 downto 0);
   ddr2_ras_n                     : out   std_logic;
   ddr2_cas_n                     : out   std_logic;
   ddr2_we_n                      : out   std_logic;
   ddr2_ck_p                      : out   std_logic_vector(0 downto 0);
   ddr2_ck_n                      : out   std_logic_vector(0 downto 0);
   ddr2_cke                       : out   std_logic_vector(0 downto 0);
   ddr2_cs_n                      : out   std_logic_vector(0 downto 0);
   ddr2_dm                        : out   std_logic_vector(1 downto 0);
   ddr2_odt                       : out   std_logic_vector(0 downto 0);

   -- Inputs
   -- Single-ended system clock
   sys_clk_i                      : in    std_logic;

   tg_compare_error              : out std_logic;
   init_calib_complete           : out std_logic;



   -- System reset - Default polarity of sys_rst pin is Active Low.
   -- System reset polarity will change based on the option
   -- selected in GUI.
      sys_rst                     : in    std_logic
 );

end entity example_top;

architecture arch_example_top of example_top is


  -- clogb2 function - ceiling of log base 2
  function clogb2 (size : integer) return integer is
    variable base : integer := 1;
    variable inp : integer := 0;
  begin
    inp := size - 1;
    while (inp > 1) loop
      inp := inp/2 ;
      base := base + 1;
    end loop;
    return base;
  end function;function STR_TO_INT(BM : string) return integer is
  begin
   if(BM = "8") then
     return 8;
   elsif(BM = "4") then
     return 4;
   else
     return 0;
   end if;
  end function;

  constant RANK_WIDTH : integer := clogb2(RANKS);

  function XWIDTH return integer is
  begin
    if(CS_WIDTH = 1) then
      return 0;
    else
      return RANK_WIDTH;
    end if;
  end function;



  constant CMD_PIPE_PLUS1        : string  := "ON";
                                     -- add pipeline stage between MC and PHY
  constant tPRDI                 : integer := 1000000;
                                     -- memory tPRDI paramter in pS.
  constant DATA_WIDTH            : integer := 16;
  constant PAYLOAD_WIDTH         : integer := DATA_WIDTH;
  constant BURST_LENGTH          : integer := STR_TO_INT(BURST_MODE);
  constant APP_DATA_WIDTH        : integer := 2 * nCK_PER_CLK * PAYLOAD_WIDTH;
  constant APP_MASK_WIDTH        : integer := APP_DATA_WIDTH / 8;

  --***************************************************************************
  -- Traffic Gen related parameters (derived)
  --***************************************************************************
  constant  TG_ADDR_WIDTH        : integer := XWIDTH + BANK_WIDTH + ROW_WIDTH + COL_WIDTH;
  constant MASK_SIZE             : integer := DATA_WIDTH/8;

  signal s_init_calibration_complete       : std_logic;

-- Start of User Design memory_ctrl component
component memory_ctrl
port
(-- Clock in ports
      clk_100MHz_i          : in  std_logic;
      rstn_i                : in  std_logic;
      init_calib_complete_o : out std_logic; -- when calibrated
      -- DDR2 interface signals
      ddr2_addr      : out   std_logic_vector(12 downto 0);
      ddr2_ba        : out   std_logic_vector(2 downto 0);
      ddr2_ras_n     : out   std_logic;
      ddr2_cas_n     : out   std_logic;
      ddr2_we_n      : out   std_logic;
      ddr2_ck_p      : out   std_logic_vector(0 downto 0);
      ddr2_ck_n      : out   std_logic_vector(0 downto 0);
      ddr2_cke       : out   std_logic_vector(0 downto 0);
      ddr2_cs_n      : out   std_logic_vector(0 downto 0);
      ddr2_dm        : out   std_logic_vector(1 downto 0);
      ddr2_odt       : out   std_logic_vector(0 downto 0);
      ddr2_dq        : inout std_logic_vector(15 downto 0);
      ddr2_dqs_p     : inout std_logic_vector(1 downto 0);
      ddr2_dqs_n     : inout std_logic_vector(1 downto 0)
);
end component;


begin

--***************************************************************************


    cmp_memory_ctrl : entity work.memory_ctrl
    port map (
           clk_100MHz_i   => sys_clk_i,
           rstn_i         => sys_rst,
           init_calib_complete_o  => s_init_calibration_complete,
           -- DDR2 interface signals
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
          ddr2_odt       => ddr2_odt,
          ddr2_dq        => ddr2_dq,
          ddr2_dqs_p     => ddr2_dqs_p,
          ddr2_dqs_n     => ddr2_dqs_n );

        init_calib_complete <= s_init_calibration_complete;
        tg_compare_error <= '0';

end architecture arch_example_top;
