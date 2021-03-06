# ddr_MIG7_ctrl_interface: DDR Interface and Control Project for VHDL Laboratory at ETSIT UPM

* [**Fernando García-Redondo**](http://lsi.die.upm.es/People/fernando-garcia/), Mail: [fgarcia@die.upm.es](mailto:fgarcia@die.upm.es), [fernando.garca@gmail.com](mailto:fernando.garca@gmail.com)
* LSI, Universidad Politécnica de Madrid
* Created for VHDL Laboratory at ETSIT UPM
* Created for Vivado 2017.2

### README Structure:
* Description
* FPGA Target
* TODO
* Changelog
* Clone and Project Creation
* Project Structure
* MIG Parameters for embedded m

## Description
RAM-like interface between Xilinx MIG 7 generated core for ddr2 and ddr3 memories.
The control sends consecutive instructions to sequentially store data in the DDR.
Later, this data is sequentiality read.
The data is simply generated based on the control iteration, and it is stored
in groups whose characteristics (length, % of used DDR's word, etc.) depend on
the parameters specified in **ram_ddr_MIG7_interface_pkg.vhd**.

**IMPORTANT** The memory has XADC internally instantiated. This is required in order to get
the ddr internal temperatured. If it is to be removed, regenerate the IP instance
disabling XADC Instantiation, and drive the temperature signal to the memory.

For simplicity, the DDR memory is working at 300Mhz (using a 200Mhz input clk),
and a PHY to Controller Clock Ratio of **4:1** with **BL8**.
**IMPORTANT** By doing so the ddr's **ui_clk** signal needs to be synchronized with the main 100Mhz clk.
We use a double reg approach together with handshake protocols (see Advanced FPGA design, Steve Kilts).
Double reg approach should be used between slower and faster domains.

The 200Mhz signal is generated using CLKGEN component (100Mhz output phase set at 0º to sync with 200MHz output).

From **ug586**:
*PHY to Controller Clock Ratio – This feature determines the ratio of the physical
layer (memory) clock frequency to the controller and user interface clock frequency.
The 2:1 ratio lowers the maximum memory interface frequency due to fabric timing
limitations. The user interface data bus width of the 2:1 ratio is 4 times the width of
the physical memory interface width, while the bus width of the 4:1 ratio is 8 times the
physical memory interface width. The 2:1 ratio has lower latency. The 4:1 ratio is
necessary for the highest data rates.*
Therefore:

      clk – 0.25x memory clock in 4:1 mode and 0.5x the memory clock in 2:1 mode.
      clk_ref – IDELAYCTRL reference clock, usually 200 MHz.

## Target
Nexys 4 DDR, by Digilent

## Simulation with DDR Model
Refer to the [simulation README](src/hdl/tb/README_tb.md)
We have included the ddr2 model and **sim_tb_top.v/example_top.vhdl** files.
This files have been altered from the originals ---Xilinx example project for MIG instances.

## TODO
* Better handshake mechanisms for:
    * Ending process
    * More complex processes
* Create functions for converting lineal addresses to pair of ddr addresses + write/read masks

## Changelog
* **v1.0rc** *tag: v1.0rc* Deployment version. To be given to pituero@die.upm.es, Github @ituero
* **v0.4** Faster (and word-wider) memory interface
* **v0.3** Will work with a simple control
* **v0.2** CLKGEN 100Mhz output phase set at 0º (to sync with 200MHz output)
* **v0.1** Creation

## Clone and Project Creation

Clone
```
git clone https://github.com/fgr1986/ddr_MIG_ctrl_interface.git
```
Then open Vivado in project folder
```
cd ddr_MIG_ctrl_interface/proj
# open vivado
source create_project.tcl
```
Run the TCL script
```
source create_project.tcl
```

## Project Structure

Folders
```
ram_ddr2_3_MIG7_interface...[root]
    * src...................[sources ]
        * constraints.......[fpga constraints]
        * hdl...............[vhdl/verilog sources]
            * tb............[simulation sources]
        * ip................[ip sources]
        * others............[other]
    * proj..................[vivado project folder]
    * bit_files.............[bitstream folder]
    * doc...................[documentation folder]
    * LICENSE
    * README
```

Synthesis Modules
```
memory_top...[top]
    * ClkGen...................[CLKGEN]
    * ram_ddr_wrapper..........[ram_ddr_wrapper]
        * ddr_xadc.............[IP: ddr_xadc IP]
```

Simulation Modules
```
sim_top.v...........................................[tb top including signal
                                                    generations, ddr models etc]
    * example_top...................................[first instanced module]
        * memory_top................................[main_module for simulation]
            * ClkGen................................[CLKGEN]
            * ram_ddr_wrapper.......................[ram_ddr_wrapper]
                * ddr_xadc..........................[IP: ddr_xadc]
    * wiredly.v.....................................[simulation wire module]
    * ddr2_model....................................[ddr2 model parameters]
    * ddr2_model_parameters.........................[ddr2 model]
```

## MIG Parameters for embedded DDR2 Memory

Refer to the [Generated options](doc/ddr_xadc_options.pdf),
based on [Xilinx ug586 guide](doc/ug586_7Series_MIS.pdf) and
[Nexys4DDR's manual](doc/nexys4ddr_rm.pdf).

The parameters described next have been used in the project.
Most of them (PHY ratio, clks etc.) can be altered.
If so, remember to accordingly change parameters and constants in both
**ram_ddr_MIG7_interface_pkg.vhd** and **sim_tb_top.v** files.
* Vivado Options
    * FPGA Family: Artix-7
    * FPGA Part: xc7a100tcsg324
    * Speed Grade: -1

* MIG Options I
    * Create Design
    * Number of controllers: 1
    * Target FPGA: xc7a100tcsg324 -1
    * Controller Type: DDR2 SDRAM
    * DDR Clk Period: 3333ps (300Mhz)
    * PHY to controller clk ratio: 4:1
    * Memory Part: MT47H64M16HR-25E
    * Data Width: 16
    * ECC (Disabled)
    * Data Mask: Enabled
    * Number of Bank Machines: 4
    * Ordering: Strict
This gives us: 1Gb, x16, row (bits): 13, col: 10, bank: 3, data bits per strobe: 8, data mask and single rank.
Therefore, because the rank in DDR2 MT47H64M16HR-25 is one (and consecuentlly its bit will always be '0'),
we have an effective address (ui_addr) of
```
constant c_DATA_ADDRESS_WIDTH     : t_APP_DATA_ADDRESS_WIDTH := c_APP_DATA_ADDRESS_WIDTH-1;
```
and the **ui_addr** is handled like
```
s_ram_addr_pre      <= '0' & ram_addr_i; -- rank in DDR2 MT47H64M16HR-25 is '0'
```
* MIG Options II
    * Input clk period: 5000ps (200Mhz generated with ClkGen)
    * Burst Type: sequential
    * Output Drive Strength: Fullstrength
    * Controller chip select pin: Enable
    * RTT(nominal) ODT: 50 ohms
    * Memory Address Mapping Selection: Bank-Row-Column.
    * System Clock: No buffer
    * Reference Clock: Use system Clock
    * Debug Signals: OFF
    * Internal Vref: Enabled
    * IO Power reduction: ON
    * XADC Instantiation: Enabled!!!
    * Internal Termination Impedance: 50 ohms
    * Fixed Pin Out: Pre-existing pin out is known and fixed: either use the provided or the constraints file.
* Status Signals, leave them with:
    * sys_rst: select bank, no connect
    * init_calib_complete: select bank, no connect
    * tg_compare_error: select bank, no connect
