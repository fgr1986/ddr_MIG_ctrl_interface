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

## Description
RAM-like interface between Xilinx MIG 7 generated core for ddr2 and ddr3 memories.
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
*

## Changelog
* **v0.4** Faster (and word-wider) memory interface
* **v0.3** Will work with a simple control
* **v0.2** CLKGEN 100Mhz output phase set at 0º (to sync with 200MHz output)
* **v0.1** Creation

## Clone and Project Creation

Clone
```
git clone https://github.com/fgr1986/ram_ddr2_3_MIG7_interface.git
```
Then open Vivado in project folder
```
cd ram_ddr2_3_MIG7_interface/proj
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
    * inst_ClkGen...................[CLKGEN]
    * inst_ram_ddr_wrapper..........[ram_ddr_wrapper]
        * inst_ddr_xadc.............[ddr_xadc]
```

Simulation Modules
```
sim_top.v...........................................[tb top including signal
                                                    generations, ddr models etc]
    * example_top...................................[first instanced module]
        * memory_top................................[main_module for simulation]
            * inst_ClkGen...........................[CLKGEN]
            * inst_ram_ddr_wrapper..................[ram_ddr_wrapper]
                * inst_ddr_xadc.....................[ddr_xadc]
    * wiredly.v.....................................[simulation wire module]
    * ddr2_model....................................[ddr2 model parameters]
    * ddr2_model_parameters.........................[ddr2 model]
```
