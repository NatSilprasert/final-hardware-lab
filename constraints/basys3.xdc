## ==============================================================
## Basys3 XDC Constraints for OV7670 Video Capture Final Project
##
## System inputs : clk (100 MHz), btnC (reset), sw[15:0]
## System outputs: VGA (4-4-4 RGB + HS/VS), Camera XCLK/RST/PWDN/SCCB
## Camera inputs : PCLK, HREF, VSYNC, D[7:0]
## Camera pin assignments follow the project instruction.
## ==============================================================

## ---------- 100 MHz System Clock ----------
set_property PACKAGE_PIN W5 [get_ports clk]
    set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

## ---------- Slide Switches ----------
set_property PACKAGE_PIN V17 [get_ports {sw[0]}]
set_property PACKAGE_PIN V16 [get_ports {sw[1]}]
set_property PACKAGE_PIN W16 [get_ports {sw[2]}]
set_property PACKAGE_PIN W17 [get_ports {sw[3]}]
set_property PACKAGE_PIN W15 [get_ports {sw[4]}]
set_property PACKAGE_PIN V15 [get_ports {sw[5]}]
set_property PACKAGE_PIN W14 [get_ports {sw[6]}]
set_property PACKAGE_PIN W13 [get_ports {sw[7]}]
set_property PACKAGE_PIN V2  [get_ports {sw[8]}]
set_property PACKAGE_PIN T3  [get_ports {sw[9]}]
set_property PACKAGE_PIN T2  [get_ports {sw[10]}]
set_property PACKAGE_PIN R3  [get_ports {sw[11]}]
set_property PACKAGE_PIN W2  [get_ports {sw[12]}]
set_property PACKAGE_PIN U1  [get_ports {sw[13]}]
set_property PACKAGE_PIN T1  [get_ports {sw[14]}]
set_property PACKAGE_PIN R2  [get_ports {sw[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[*]}]

## ---------- Push Buttons ----------
set_property PACKAGE_PIN U18 [get_ports btnC]
    set_property IOSTANDARD LVCMOS33 [get_ports btnC]
set_property PACKAGE_PIN T18 [get_ports btnU]
    set_property IOSTANDARD LVCMOS33 [get_ports btnU]
set_property PACKAGE_PIN U17 [get_ports btnD]
    set_property IOSTANDARD LVCMOS33 [get_ports btnD]
set_property PACKAGE_PIN W19 [get_ports btnL]
    set_property IOSTANDARD LVCMOS33 [get_ports btnL]
set_property PACKAGE_PIN T17 [get_ports btnR]
    set_property IOSTANDARD LVCMOS33 [get_ports btnR]

## ---------- LEDs (debug) ----------
set_property PACKAGE_PIN U16 [get_ports {led[0]}]
set_property PACKAGE_PIN E19 [get_ports {led[1]}]
set_property PACKAGE_PIN U19 [get_ports {led[2]}]
set_property PACKAGE_PIN V19 [get_ports {led[3]}]
set_property PACKAGE_PIN W18 [get_ports {led[4]}]
set_property PACKAGE_PIN U15 [get_ports {led[5]}]
set_property PACKAGE_PIN U14 [get_ports {led[6]}]
set_property PACKAGE_PIN V14 [get_ports {led[7]}]
set_property PACKAGE_PIN V13 [get_ports {led[8]}]
set_property PACKAGE_PIN V3  [get_ports {led[9]}]
set_property PACKAGE_PIN W3  [get_ports {led[10]}]
set_property PACKAGE_PIN U3  [get_ports {led[11]}]
set_property PACKAGE_PIN P3  [get_ports {led[12]}]
set_property PACKAGE_PIN N3  [get_ports {led[13]}]
set_property PACKAGE_PIN P1  [get_ports {led[14]}]
set_property PACKAGE_PIN L1  [get_ports {led[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[*]}]

## ---------- VGA Output (4-bit per channel) ----------
set_property PACKAGE_PIN G19 [get_ports {vga_r[0]}]
set_property PACKAGE_PIN H19 [get_ports {vga_r[1]}]
set_property PACKAGE_PIN J19 [get_ports {vga_r[2]}]
set_property PACKAGE_PIN N19 [get_ports {vga_r[3]}]
set_property PACKAGE_PIN J17 [get_ports {vga_g[0]}]
set_property PACKAGE_PIN H17 [get_ports {vga_g[1]}]
set_property PACKAGE_PIN G17 [get_ports {vga_g[2]}]
set_property PACKAGE_PIN D17 [get_ports {vga_g[3]}]
set_property PACKAGE_PIN N18 [get_ports {vga_b[0]}]
set_property PACKAGE_PIN L18 [get_ports {vga_b[1]}]
set_property PACKAGE_PIN K18 [get_ports {vga_b[2]}]
set_property PACKAGE_PIN J18 [get_ports {vga_b[3]}]
set_property PACKAGE_PIN P19 [get_ports vga_hs]
set_property PACKAGE_PIN R19 [get_ports vga_vs]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_r[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_g[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_b[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports vga_hs]
set_property IOSTANDARD LVCMOS33 [get_ports vga_vs]

## ---------- OV7670 Camera (per project instruction) ----------
## Parallel data bus
set_property PACKAGE_PIN P17 [get_ports {cam_data[0]}]
set_property PACKAGE_PIN N17 [get_ports {cam_data[1]}]
set_property PACKAGE_PIN M19 [get_ports {cam_data[2]}]
set_property PACKAGE_PIN M18 [get_ports {cam_data[3]}]
set_property PACKAGE_PIN L17 [get_ports {cam_data[4]}]
set_property PACKAGE_PIN K17 [get_ports {cam_data[5]}]
set_property PACKAGE_PIN C16 [get_ports {cam_data[6]}]
set_property PACKAGE_PIN B16 [get_ports {cam_data[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cam_data[*]}]

## Synchronization / control
set_property PACKAGE_PIN A17 [get_ports cam_href]
    set_property IOSTANDARD LVCMOS33 [get_ports cam_href]
set_property PACKAGE_PIN A16 [get_ports cam_pclk]
    set_property IOSTANDARD LVCMOS33 [get_ports cam_pclk]
set_property PACKAGE_PIN B15 [get_ports cam_vsync]
    set_property IOSTANDARD LVCMOS33 [get_ports cam_vsync]
set_property PACKAGE_PIN C15 [get_ports cam_xclk]
    set_property IOSTANDARD LVCMOS33 [get_ports cam_xclk]
set_property PACKAGE_PIN R18 [get_ports cam_pwdn]
    set_property IOSTANDARD LVCMOS33 [get_ports cam_pwdn]
set_property PACKAGE_PIN P18 [get_ports cam_rst_n]
    set_property IOSTANDARD LVCMOS33 [get_ports cam_rst_n]

## SCCB (I2C-like) - open-drain style (controller drives pull-low only)
set_property PACKAGE_PIN A14 [get_ports cam_sioc]
    set_property IOSTANDARD LVCMOS33 [get_ports cam_sioc]
    set_property PULLUP true          [get_ports cam_sioc]
set_property PACKAGE_PIN A15 [get_ports cam_siod]
    set_property IOSTANDARD LVCMOS33 [get_ports cam_siod]
    set_property PULLUP true          [get_ports cam_siod]

## Declare PCLK as clock (incoming from camera, ~12-25 MHz)
create_clock -add -name cam_pclk_pin -period 40.00 -waveform {0 20} [get_ports cam_pclk]

## The OV7670 PCLK enters the FPGA on pin A16, which is a Pmod connector
## pin and is NOT a clock-capable (MRCC/SRCC) input.  Vivado will refuse to
## route it onto the dedicated clock network unless we tell it to relax
## the rule below, otherwise we get [Place 30-574]
## "CLOCK_DEDICATED_ROUTE" violations after synthesis.  The frame buffer
## handles CDC via dual-clock BRAM so using a regular routing track is
## acceptable for this design.
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets cam_pclk_IBUF]

## Asynchronous clock domains.
##
## We have two unrelated clock families:
##   * cam_pclk_pin              : OV7670 PCLK (input, ~25 MHz, free-running)
##   * sys_clk_pin + MMCM outputs : 100 MHz board clock and the clk_sys/
##                                  clk_vga/xclk that the MMCM derives from it
##
## Crossings between them go through dual-clock BRAM/FIFO and 2-FF
## synchronisers (rst_pclk_sync / rst_vga_sync), which already handle CDC.
## Group them as asynchronous so the timing engine doesn't try to chase
## inter-clock paths or report bogus violations.
set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks sys_clk_pin] \
    -group [get_clocks cam_pclk_pin]

## Configuration bitstream options
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO        [current_design]
