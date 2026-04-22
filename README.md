# Final Project: Real-Time Video Capture and Processing System

Basys 3 FPGA + OV7670 camera module + VGA monitor.
Course: 2110363 Hardware Synthesis Laboratory.

## Repository layout

```
final-proj/
├── rtl/                  # SystemVerilog RTL sources
│   ├── top.sv
│   ├── clk_gen.sv
│   ├── sccb_master.sv
│   ├── sccb_rom.sv
│   ├── cam_configurator.sv
│   ├── ov7670_capture.sv
│   ├── frame_buffer.sv
│   ├── line_buffer_3row.sv
│   ├── vga_sync.sv
│   ├── addr_gen.sv
│   ├── filter_grayscale.sv
│   ├── filter_invert.sv
│   ├── filter_sobel.sv
│   ├── filter_mux.sv
│   ├── mode_ctrl.sv
│   └── debounce.sv
├── sim/                  # SystemVerilog testbenches
│   ├── tb_vga_sync.sv
│   ├── tb_sccb_master.sv
│   ├── tb_frame_buffer.sv
│   ├── tb_ov7670_capture.sv
│   ├── tb_filter_sobel.sv
│   └── tb_top_integration.sv
├── constraints/
│   └── basys3.xdc
├── doc/
│   ├── report.md
│   ├── block_diagram.md
│   └── ai_usage.md
└── README.md
```

## Creating the Vivado project

1. Launch Vivado (tested with 2020.2).
2. `File -> New Project`. Pick `Artix-7 xc7a35tcpg236-1` (Basys 3).
3. Add all files under `rtl/` as design sources.
4. Add `constraints/basys3.xdc` as a constraint.
5. Set the top module to `top`.
6. Add all files under `sim/` as simulation sources.  The default sim
   top-level can be switched to `tb_vga_sync`, `tb_sccb_master`, etc.
7. `Run Synthesis -> Run Implementation -> Generate Bitstream -> Program Device`.

## Board usage

| Control       | Function                                            |
|---------------|-----------------------------------------------------|
| `btnC`        | Global reset                                        |
| `sw[1:0]`     | Filter select: 00 raw, 01 grayscale, 10 invert, 11 Sobel |
| `sw[5:2]`     | Sobel threshold (0..15)                             |
| `sw[15]`      | Resolution: 0 = 320x240 (buffered), 1 = 640x480 (stream-through) |
| `led[0]`      | MMCM locked                                         |
| `led[1]`      | SCCB configuration complete                         |
| `led[2]`      | SCCB busy                                           |
| `led[3]`      | Camera VSYNC (raw)                                  |
| `led[4]`      | Camera HREF (raw)                                   |
| `led[5]`      | Mode select                                         |
| `led[7:6]`    | Active filter                                       |
| `led[11:8]`   | Sobel threshold                                     |
| `led[14]`     | Pixel-valid pulse from capture                      |
| `led[15]`     | rst_sys                                             |

## Wiring (per project instruction)

See `constraints/basys3.xdc`.  The camera connects via Pmod headers JB and JC.

| FPGA | Camera | FPGA | Camera |
|------|--------|------|--------|
| P17  | D0     | A17  | HREF   |
| N17  | D1     | A16  | PCLK   |
| M19  | D2     | R18  | PWDN   |
| M18  | D3     | P18  | RESET  |
| L17  | D4     | A14  | SIOC   |
| K17  | D5     | A15  | SIOD   |
| C16  | D6     | B15  | VSYNC  |
| B16  | D7     | C15  | XCLK   |

Note: do NOT connect OV7670 VCC/VDD to the 3.3 V rail directly if your
camera module lacks regulators; use the module's own 3.3 V input.

## Simulation quick start

Open Vivado simulator:

```
run_sim -top tb_vga_sync
run_sim -top tb_sccb_master
run_sim -top tb_frame_buffer
run_sim -top tb_ov7670_capture
run_sim -top tb_filter_sobel
run_sim -top tb_top_integration
```

All five unit testbenches print `PASSED` on success.

## AI usage

See `doc/ai_usage.md` for the disclosure required by the project rubric.
