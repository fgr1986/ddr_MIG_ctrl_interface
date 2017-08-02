#README for Test-Bench using DDR Models
## ram_ddr2_3_MIG7_interface: DDR Interface and Control Project

### Fernando García-Redondo, fgarcia@die.upm.es, fernando.garca@gmail.com
### LSI, Universidad Politécnica de Madrid
### To be used in VHDL Laboratory at LSI, UPM

Created for Vivado 2017.2

# Description
1. Configure DDR IP instance using MIG (Xilinx) tool.
Later, (right-click) open the IP example design project.
This will create another project with an example to run the DDR.
**We are going to adapt this project to include our models that we want to simulate**.
2. Locate **sim_tb_top.v** file, **this is the top file of the Test-Bench**.
3. Locate **example_top.vhd** file (this file is refered by the top file **sim_tb_top.v**). To ease the task, you may find attached in this folder an example **example_top.vhd** file, related to this repository project.
4. Alter **example_top.vhd** file so that it instantiates the module to be simulated.
5. Check timing parameters (ref clk, system clk etc.) in **sim_tb_top.v** file.
6. Simulate the customized example project.

# Target
Nexys 4 DDR, by Digilent

# TODO
* Everything

# Changelog
* **v0.2** CLKGEN 100Mhz output phase set at 180º (to sync with 200MHz output)
* **v0.1** Creation
