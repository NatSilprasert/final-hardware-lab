# Final Project Report
## Real-Time Video Capture and Processing on Basys 3

Course: 2110363 Hardware Synthesis Laboratory

### 1. Overview

The system captures live video from an OV7670 CMOS camera, stores (or
streams) it through internal Block RAM, and displays it on a VGA monitor
with three selectable image-processing filters:

1. Grayscale conversion
2. Color inversion (negative)
3. Sobel edge detection (3x3 convolution)

Two display resolutions are supported and runtime-selectable via a slide
switch:

* Mode A — **320x240 buffered**: QVGA frame buffered in BRAM, displayed
  as 640x480 on the monitor via 2x pixel doubling.
* Mode B — **640x480 stream-through**: camera configured in VGA mode;
  pixels flow through a line buffer and out to the monitor without a
  full frame buffer.  Extra-credit candidate.

### 2. Data path and clocking

```
         100 MHz (W5)                  25 MHz              25 MHz
         ----|clk_in|----+--MMCM-->----|clk_vga|--> VGA sync
                         +--MMCM-->----|xclk|----> OV7670 XCLK
                         +--pass---->--|clk_sys|--> SCCB, control, cam_configurator
         OV7670 PCLK ----|cam_pclk|--> ov7670_capture, line_buffer_3row, frame_buffer (wr)
```

#### Clock-domain crossings
* Camera PCLK ↔ VGA clock: handled by the dual-port BRAM in
  `frame_buffer.sv`.  Vivado infers a dual-clock BRAM; timing is
  explicitly broken with `set_false_path` in the XDC.
* Control signals (VSYNC, frame_start, rst) cross domains via 3-stage
  flip-flop synchronizers.

### 3. Module-by-module description

| Module                | Role |
|----------------------|------|
| `clk_gen`            | MMCM wrapper (100→25 MHz ×2) |
| `mode_ctrl`          | Debounce/decode switches and buttons |
| `sccb_master`        | 3-phase SCCB write FSM (~100 kHz) |
| `sccb_rom`           | Register tables for QVGA and VGA RGB565 |
| `cam_configurator`   | Power-up sequence and ROM streamer |
| `ov7670_capture`     | Byte assembly + column/row counters |
| `frame_buffer`       | 320x240 × 12-bit dual-clock BRAM |
| `line_buffer_3row`   | 3x3 sliding window for convolution |
| `vga_sync`           | 640x480@60 sync generator |
| `addr_gen`           | Frame-buffer read address w/ pixel doubling |
| `filter_grayscale`   | Shift-add luma approximation |
| `filter_invert`      | Bitwise NOT on 12-bit RGB |
| `filter_sobel`       | 3x3 Sobel, thresholded to B/W |
| `filter_mux`         | 4:1 output selector |
| `debounce`           | Counter-based mechanical debouncer |

### 4. Memory budget

Basys 3 provides **1,800 Kbits** of BRAM.

| Structure              | Size              | Bits     |
|------------------------|-------------------|----------|
| `frame_buffer`         | 320×240 × 12 bit  | 921,600  |
| `line_buffer_3row`     | 2 × 640 × 4 bit   | 5,120    |
| Miscellaneous          | —                 | <1 Kb    |
| **Total**              |                   | **~928 Kb** |

Approximately **51%** of BRAM is used, leaving ample headroom for
future expansion (e.g., a larger line buffer for convolution in Mode B,
or upgrading to RGB565 storage).

### 5. Filter design notes

* **Grayscale**: uses the shift-add approximation
  `Y = (5R + 9G + 2B) >> 4`, which sums to 16 and avoids multipliers.
  The luma is replicated onto all three channels for display.
* **Invert**: straight bitwise NOT; output is simply `~pixel`.
* **Sobel**: classic 3x3 with `|G| ≈ |Gx| + |Gy|`, thresholded by a
  user-adjustable 4-bit value (`sw[5:2]`).  Output is black/white.
  Implemented as a 3-stage pipeline for timing.

### 6. SCCB initialization sequence

1. Drive `cam_rst_n` low for 10 ms (power-on reset).
2. Release `cam_rst_n`, wait 10 ms for internal PLL to lock.
3. Walk the `sccb_rom` table (either QVGA or VGA variant) writing every
   `{sub_addr, data}` entry via `sccb_master`.  Each write takes ~300 μs
   at 100 kHz SIOC plus inter-command gaps.
4. When the table terminates, raise `cfg_done` (LED 1 on).

If `mode_sel` toggles at runtime, the configurator restarts from the
power-on step — this makes switching resolutions on-the-fly idiot-proof.

### 7. VGA timing

Standard VESA 640×480 @ 60 Hz, pixel clock 25 MHz (within tolerance of
the ideal 25.175 MHz for modern monitors).

| Horizontal | Value |
|------------|-------|
| Visible    | 640   |
| Front porch| 16    |
| Sync pulse | 96    |
| Back porch | 48    |
| Total      | 800   |

| Vertical   | Value |
|------------|-------|
| Visible    | 480   |
| Front porch| 10    |
| Sync pulse | 2     |
| Back porch | 33    |
| Total      | 525   |

Both sync pulses are active-low.

### 8. Challenges faced

* **PCLK polarity.** OV7670 ships with a variable PCLK phase.  Register
  `0x15 COM10[4]` can flip its polarity; we left it at default and
  adjust the capture FSM to sample on rising edges if necessary.
* **SCCB ACK.** The OV7670 does not always drive ACK cleanly; we use
  the "don't-care" bit (high-Z by the master, relying on the pull-up).
* **Memory budget for full VGA.** A full 640×480 × 12-bit frame buffer
  would be 3.6 Mb — more than the Basys 3 has.  Mode B sidesteps this
  by keeping only 3 rows of grayscale data in the line buffer.
* **Cross-domain BRAM writes.** Avoided by using a genuine dual-clock
  BRAM inference pattern and adding `set_false_path` constraints.

### 9. Testbench coverage

| TB                         | What it verifies |
|----------------------------|------------------|
| `tb_vga_sync`              | HS/VS polarity and pulse widths, 640x480 visible count |
| `tb_sccb_master`           | START/STOP conditions, 27 SIOC edges, done pulse |
| `tb_frame_buffer`          | Write/read across independent clocks |
| `tb_ov7670_capture`        | Byte assembly, column/row tracking on a fake frame |
| `tb_filter_sobel`          | Edge detected on synthetic vertical-edge image, rejected on flat |
| `tb_top_integration`       | Smoke test that the assembled top drives HS/VS |

### 10. Future work / extra credit roadmap

* True 640x480 stream-through with phase-locked camera-VSYNC to
  monitor-VSYNC (PLL the camera XCLK off the VGA pixel clock).
* Bilinear upscale 320x240 → 640x480 (non-trivial upscaling).
* Finn-compiled tiny CNN for binary classification (e.g. hand vs no-hand)
  fed by the 4-bit grayscale stream.

### 11. AI usage disclosure

See `doc/ai_usage.md`.
