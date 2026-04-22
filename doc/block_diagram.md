# System Block Diagram

```mermaid
flowchart LR
    subgraph BoardIO [Basys 3 I/O]
        Clk100[100 MHz clk W5]
        BTN[btnC reset]
        SW[sw 15:0]
        LED[led 15:0]
        VGAPins[VGA R/G/B/HS/VS]
    end

    subgraph Camera [OV7670 Camera]
        CamD[D 7:0]
        CamHREF[HREF]
        CamVSYNC[VSYNC]
        CamPCLK[PCLK]
        CamXCLK[XCLK in]
        CamSIOC[SIOC]
        CamSIOD[SIOD]
        CamRST[RESET]
        CamPWDN[PWDN]
    end

    subgraph FPGA [FPGA top]
        MMCM[clk_gen MMCM]
        Ctrl[mode_ctrl]
        Cfg[cam_configurator]
        SCCB[sccb_master]
        ROM[sccb_rom]
        Cap[ov7670_capture]
        FB[frame_buffer 320x240 x 4-bit Y luma]
        LB[line_buffer_3row 3 x 640 x 4-bit]
        VGASync[vga_sync 640x480 60Hz]
        AddrGen[addr_gen pixel doubler]
        Gray[filter_grayscale]
        Inv[filter_invert]
        Sobel[filter_sobel]
        Mux[filter_mux]
    end

    Clk100 --> MMCM
    MMCM -- "clk_sys 100" --> Ctrl
    MMCM -- "clk_sys 100" --> Cfg
    MMCM -- "clk_sys 100" --> SCCB
    MMCM -- "xclk 25"  --> CamXCLK
    MMCM -- "clk_vga 25" --> VGASync
    MMCM -- "clk_vga 25" --> AddrGen
    MMCM -- "clk_vga 25" --> Gray
    MMCM -- "clk_vga 25" --> Inv
    MMCM -- "clk_vga 25" --> Sobel
    MMCM -- "clk_vga 25" --> Mux

    BTN --> Ctrl
    SW  --> Ctrl
    Ctrl -- "rst, filter_sel, mode_sel, sobel_thr" --> Cfg
    Ctrl --> Mux
    Ctrl --> Sobel

    Cfg <--> ROM
    Cfg -- "id/sub/data/start" --> SCCB
    SCCB -- "SIOC/SIOD open-drain" --> CamSIOC
    SCCB --> CamSIOD
    Cfg -- "cam_rst_n, cam_pwdn" --> CamRST
    Cfg --> CamPWDN

    CamPCLK --> Cap
    CamVSYNC --> Cap
    CamHREF --> Cap
    CamD --> Cap

    Cap -- "pix_y (4-bit), addr, we" --> FB
    Cap -- "cap_y (4-bit)" --> LB
    LB -- "3x3 window" --> Sobel
    FB -- "dout" --> Gray
    FB --> Inv
    FB --> Mux
    AddrGen -- "rd_addr" --> FB
    VGASync -- "h,v,video_on,hs,vs" --> AddrGen
    VGASync --> Mux

    Mux -- "R4,G4,B4" --> VGAPins

    Ctrl --> LED
    Cfg --> LED
```

## Clock domains (color-coded textually)

- **clk_in (100 MHz)** — only feeds the MMCM.
- **clk_sys (100 MHz)** — `mode_ctrl`, `cam_configurator`, `sccb_master`.
- **xclk (25 MHz)** — drives the camera.
- **cam_pclk (≈25 MHz, async)** — `ov7670_capture`, line buffer write
  port, frame-buffer write port.
- **clk_vga (25 MHz)** — `vga_sync`, `addr_gen`, every filter, the
  output mux, frame-buffer read port.

The only hard CDC is camera PCLK ↔ clk_vga, which is handled inside
`frame_buffer` (dual-clock BRAM).  `cam_vsync` and `frame_start` are
synchronized with 3-FF chains before use.

## Data paths (by mode)

### Mode A — 320x240 buffered

```
OV7670 (PCLK) -> ov7670_capture -> frame_buffer -> filters -> VGA
```

### Mode B — 640x480 stream-through

```
OV7670 (PCLK) -> ov7670_capture -> line_buffer_3row -> Sobel -> VGA
                                -> bypass path        -> raw/gray/invert -> VGA
```
