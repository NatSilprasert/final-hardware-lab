// ============================================================================
// clk_gen.sv - Clock generation using Xilinx MMCM
//
// From 100 MHz Basys3 input produce:
//   - xclk       : 25 MHz  -> OV7670 camera XCLK
//   - clk_vga    : 25 MHz  -> VGA 640x480 pixel clock (ideal 25.175 MHz,
//                              25 MHz is within VESA tolerance for most monitors)
//   - clk_sys    : 100 MHz -> SCCB and control FSMs
//
// Note: we use a simple behavioral MMCM instantiation.  On Basys3 (Artix-7)
// the MMCME2_BASE primitive produces the same clocks with proper skew/jitter;
// for simulation we fall back to divided counters.
// ============================================================================
`timescale 1ns/1ps

module clk_gen (
    input  logic clk_in_100,   // 100 MHz input
    input  logic rst_async,    // async reset (active high)
    output logic clk_sys,      // 100 MHz buffered
    output logic clk_vga,      // 25 MHz pixel clock
    output logic xclk,         // 25 MHz camera clock
    output logic locked        // MMCM locked
);

`ifdef SIMULATION
    // Simple behavioural dividers for simulation
    logic [1:0] div;
    always_ff @(posedge clk_in_100 or posedge rst_async) begin
        if (rst_async) div <= 2'd0;
        else           div <= div + 2'd1;
    end
    assign clk_sys = clk_in_100;
    assign clk_vga = div[1];    // /4 -> 25 MHz
    assign xclk    = div[1];
    assign locked  = ~rst_async;
`else
    logic clk_fb;
    logic clk_sys_u, clk_vga_u, xclk_u;

    // MMCME2_BASE: VCO = 100 MHz * 10 = 1000 MHz.  Divide-by-10 -> 100 MHz,
    // divide-by-40 -> 25 MHz.
    MMCME2_BASE #(
        .CLKFBOUT_MULT_F (10.0),
        .CLKIN1_PERIOD   (10.0),
        .CLKOUT0_DIVIDE_F(10.0),   // 100 MHz  clk_sys
        .CLKOUT1_DIVIDE  (40),     // 25 MHz   clk_vga
        .CLKOUT2_DIVIDE  (40),     // 25 MHz   xclk
        .DIVCLK_DIVIDE   (1)
    ) mmcm_i (
        .CLKIN1   (clk_in_100),
        .CLKFBIN  (clk_fb),
        .CLKFBOUT (clk_fb),
        .CLKOUT0  (clk_sys_u),
        .CLKOUT1  (clk_vga_u),
        .CLKOUT2  (xclk_u),
        .PWRDWN   (1'b0),
        .RST      (rst_async),
        .LOCKED   (locked)
    );

    BUFG bufg_sys (.I(clk_sys_u), .O(clk_sys));
    BUFG bufg_vga (.I(clk_vga_u), .O(clk_vga));
    BUFG bufg_xck (.I(xclk_u),    .O(xclk));
`endif

endmodule
