// ============================================================================
// addr_gen.sv - Pixel-doubling address generator for frame buffer read
//
// In mode A (320x240 buffered), we display the 320x240 image on a 640x480
// monitor by doubling each pixel horizontally AND vertically:
//      fb_col = h_count >> 1    (for h_count = 0..639)
//      fb_row = v_count >> 1    (for v_count = 0..479)
//      addr   = fb_row * 320 + fb_col
//
// We register the address one cycle so it's available when the BRAM returns
// data the next cycle.
// ============================================================================
`timescale 1ns/1ps

module addr_gen #(
    parameter int FB_W      = 320,
    parameter int FB_H      = 240,
    parameter int ADDR_W    = 17
) (
    input  logic              clk,
    input  logic [9:0]        h_count,
    input  logic [9:0]        v_count,
    output logic [ADDR_W-1:0] fb_addr,
    output logic [8:0]        fb_col,   // 0..319
    output logic [7:0]        fb_row    // 0..239
);

    logic [8:0] col_n;
    logic [7:0] row_n;

    assign col_n = h_count[9:1];   // /2, capped by caller
    assign row_n = v_count[8:1];   // /2

    always_ff @(posedge clk) begin
        fb_col  <= col_n;
        fb_row  <= row_n;
        fb_addr <= row_n * FB_W + col_n;
    end

endmodule
