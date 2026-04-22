# AI Usage Disclosure

This document is required by the project rubric.  Please edit this file
before submission to accurately describe how AI tools (if any) were used.

## Tools used (example template — replace with actual usage)

- **Cursor (Anthropic Claude model)**: assisted in drafting the initial
  SystemVerilog scaffolding, XDC constraint set-up, and the project
  README/report templates.  All generated code was reviewed, tested
  with simulation, and modified by the team before being committed.

- **ChatGPT / Gemini / Copilot (if used)**: list here what was asked
  and which modules were influenced.

## What was NOT AI-generated

- The final SCCB register values were hand-verified against the
  OV7670 datasheet (v1.4, Aug 2006).
- All testbench stimuli and pass/fail checks were authored and
  reviewed by the team.
- Hardware bring-up on the Basys 3 board, debugging of PCLK polarity,
  on-bench scope measurements, and VGA monitor verification were
  performed by the team.

## Per-module acknowledgement

| Module                | AI assistance |
|-----------------------|---------------|
| `top.sv`              | scaffolding + wiring (reviewed) |
| `clk_gen.sv`          | MMCM template (reviewed) |
| `sccb_master.sv`      | FSM skeleton (timing values hand-tuned) |
| `sccb_rom.sv`         | register list cross-checked vs datasheet |
| `vga_sync.sv`         | VESA constants cross-checked |
| `filter_sobel.sv`     | convolution math hand-verified |
| Testbenches           | stimuli authored by team |

If NO AI tools were used at all, replace this document with a single
line stating that explicitly.
