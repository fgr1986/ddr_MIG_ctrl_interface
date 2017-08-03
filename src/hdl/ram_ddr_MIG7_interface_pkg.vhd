----------------------------------------------------------------------------
----------------------------------------------------------------------------
-- Author:  Fernando García Redondo, fgarcia@die.upm.es
----------------------------------------------------------------------------
----------------------------------------------------------------------------

-- Create Date:    15:45:01 20/07/2017
-- Design Name:    Nexys4 DDR UPM VHDL Lab Project
-- Module Name:    top_upm_vhdl_lab - behavioral
-- Project Name:   UPM VHDL Lab Project
-- Target Devices: Nexys4 DDR Development Board, containing a XC7a100t-1 csg324 device
-- Tool versions:
-- Description:
--

-- RAM-like interface between Xilinx MIG 7 generated core for ddr2 and ddr3 memories.
-- For simplicity, the DDR memory is working at 300Mhz (using a 200Mhz input clk),
-- and a PHY to Controller Clock Ratio of **4:1** with **BL8**.
-- **IMPORTANT** By doing so the ddr's **ui_clk** signal needs to be synchronized with the main 100Mhz clk.
-- We use a double reg approach together with handshake protocols (see Advanced FPGA design, Steve Kilts).
-- Double reg approach should be used between slower and faster domains.
--
-- The 200Mhz signal is generated using CLKGEN component (100Mhz output phase set at 0º to sync with 200MHz output).
--
-- From **ug586**:
-- *PHY to Controller Clock Ratio – This feature determines the ratio of the physical
-- layer (memory) clock frequency to the controller and user interface clock frequency.
-- The 2:1 ratio lowers the maximum memory interface frequency due to fabric timing
-- limitations. The user interface data bus width of the 2:1 ratio is 4 times the width of
-- the physical memory interface width, while the bus width of the 4:1 ratio is 8 times the
-- physical memory interface width. The 2:1 ratio has lower latency. The 4:1 ratio is
-- necessary for the highest data rates.*
-- Therefore:
--
--       clk – 0.25x memory clock in 4:1 mode and 0.5x the memory clock in 2:1 mode.
--       clk_ref – IDELAYCTRL reference clock, usually 200 MHz.
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
----------------------------------------------------------------------------------
-- Libraries
----------------------------------------------------------------------------------
library work;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package ram_ddr_MIG7_interface_pkg is

  subtype t_DATA_WIDTH             is positive range 16 to 128;
  subtype t_APP_DATA_ADDRESS_WIDTH is positive range 16 to 27; -- rank in DDR2
                                                               -- MT47H64M16HR-25 is '0'

  ------------------------------------------------------------------------
  -- Constant Declarations
  ------------------------------------------------------------------------

  --------------------------------
  -- System
  --------------------------------
  constant c_nCK_PER_CLK            : positive := 4; -- 2 or 4
  constant c_DDR_DATA_WIDTH         : t_DATA_WIDTH := 16;
  constant c_PAYLOAD_WIDTH          : integer := c_DDR_DATA_WIDTH;
  constant c_APP_DATA_WIDTH         : t_DATA_WIDTH := 2*c_nCK_PER_CLK*c_PAYLOAD_WIDTH; -- 128 or 64
  constant c_APP_DATA_ADDRESS_WIDTH : t_APP_DATA_ADDRESS_WIDTH := 27;
  -- rank in DDR2 MT47H64M16HR-25 is '0'
  constant c_DDR_ADDRESS_WIDTH      : integer := 13;
  constant c_DDR_DQ_WIDTH           : integer := 16;
  constant c_DDR_WDF_MASK_WIDTH     : integer := c_APP_DATA_WIDTH/8; -- 16 or 8
  constant c_DDR_BANK_WIDTH         : integer := 3;
  constant c_DDR_DM_WIDTH           : integer := 2;
  constant c_DDR_DQS_WIDTH          : integer := 2;
  constant c_DDR_CMD_WIDTH          : integer := 3;

  constant c_DATA_2_MEM_WIDTH       : t_DATA_WIDTH := c_APP_DATA_WIDTH;
  constant c_DATA_WIDTH             : t_DATA_WIDTH := c_DDR_DATA_WIDTH;
  -- rank in DDR2 MT47H64M16HR-25 is '0'
  constant c_DATA_ADDRESS_WIDTH     : t_APP_DATA_ADDRESS_WIDTH := c_APP_DATA_ADDRESS_WIDTH-1;
  constant c_ADDR_INC               : integer := c_APP_DATA_WIDTH/c_DDR_DATA_WIDTH;

  -- how many words send at once to memory
  constant c_WORDS_2_MEM  : positive := (c_DATA_2_MEM_WIDTH/c_DATA_WIDTH);

  -- data out of memory type
  type t_DATA_OUT_MEM is array(c_WORDS_2_MEM-1 downto 0)
        of std_logic_vector( c_DATA_WIDTH-1 downto 0);

  constant c_SYS_CLK_FREQ_MHZ       : positive := 100;

  --------------------------------
  -- DDR/RAM
  --------------------------------
  -- ddr commands
  constant c_CMD_WRITE              : std_logic_vector(2 downto 0) := "000";
  constant c_CMD_READ               : std_logic_vector(2 downto 0) := "001";


end ram_ddr_MIG7_interface_pkg;

package body ram_ddr_MIG7_interface_pkg is  --start of package body

  -- 2^c_DATA_ADDRESS_WIDTH * c_DDR_DATA_WIDTH = 1Gbps in Nexys4 DDR
  -- ui address is c_APP_DATA_ADDRESS_WIDTH width->
  -- Rank + bank + row + col, but as there is only one rank,
  -- then ui_address's MSb = '0' (therefore c_DATA_ADDRESS_WIDTH)
  -- Depending on the burst, we have c_WORDS_2_MEM
  -- function lineal_to_ui_addr ( lineal : unsigned(c_DATA_ADDRESS_WIDTH-1 downto 0) ) return unsigned is
  --
  --       begin
  --       return floor(lineal/c_ADDR_INC);
  -- end lineal_to_ui_addr;
  --
  -- function lineal_to_ui_mask ( lineal : unsigned(c_DATA_ADDRESS_WIDTH-1 downto 0) ) return std_logic_vector is
  --   --
  --   -- constant c_MASK       : std_logic_vector(c_DDR_WDF_MASK_WIDTH-1 downto 0)
  --   --                             := (c_DDR_WDF_MASK_WIDTH-1 downto c_MASK_DIFF => '1')
  --   --                              & (c_MASK_DIFF-1 downto 0 => '0');
  --       variable mask : std_logic_vector(c_DDR_WDF_MASK_WIDTH-1 downto 0);
  --       variable diff : integer:=0;
  --       begin
  --         diff = lineal - (c_APP_DATA_WIDTH/c_DDR_DATA_WIDTH)*floor(lineal/(c_APP_DATA_WIDTH/c_DDR_DATA_WIDTH));
  --       return (c_DDR_WDF_MASK_WIDTH-1 downto c_MASK_DIFF => '0');
  -- end lineal_to_ui_mask;

--    function to_bcd ( bin : unsigned(7 downto 0) ) return unsigned is
--         variable i : integer:=0;
--         variable bcd : unsigned(11 downto 0) := (others => '0');
--         variable bint : unsigned(7 downto 0) := bin;

--         begin
--             for i in 0 to 7 loop  -- repeating 8 times.
--                 bcd(11 downto 1) := bcd(10 downto 0);  --shifting the bits.
--                 bcd(0) := bint(7);
--                 bint(7 downto 1) := bint(6 downto 0);
--                 bint(0) :='0';


--                 if(i < 7 and bcd(3 downto 0) > "0100") then --add 3 if BCD digit is greater than 4.
--                 bcd(3 downto 0) := bcd(3 downto 0) + "0011";
--                 end if;

--                 if(i < 7 and bcd(7 downto 4) > "0100") then --add 3 if BCD digit is greater than 4.
--                 bcd(7 downto 4) := bcd(7 downto 4) + "0011";
--                 end if;

--                 if(i < 7 and bcd(11 downto 8) > "0100") then  --add 3 if BCD digit is greater than 4.
--                 bcd(11 downto 8) := bcd(11 downto 8) + "0011";
--                 end if;

--             end loop;
--         return bcd;
--     end to_bcd;

end ram_ddr_MIG7_interface_pkg;
