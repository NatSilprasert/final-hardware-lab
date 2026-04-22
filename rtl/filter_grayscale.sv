// ============================================================================
// filter_grayscale.sv - RGB444 -> grayscale (replicate Y on all channels)
//
// Luma approximation: Y = 0.299 R + 0.587 G + 0.114 B
// Integer form using 4-bit channels:
//   Y_8bit = (R*77 + G*150 + B*29) / 256        // standard
// Since R,G,B are 4-bit (0..15), shift them back up by 4 first, or use a
// simpler shift-add approximation:
//   Y ≈ (R*5 + G*9 + B*2) >> 4     (coefficients sum to 16)
// Result is a 4-bit intensity that we replicate onto R/G/B for display.
// ============================================================================
`timescale 1ns/1ps

module filter_grayscale (
    input  logic        clk,
    input  logic [11:0] pix_in,      // {R4, G4, B4}
    output logic [11:0] pix_out
);
    logic [3:0] r, g, b;
    assign r = pix_in[11:8];
    assign g = pix_in[7:4];
    assign b = pix_in[3:0];

    logic [7:0] sum;
    logic [3:0] y;

    always_ff @(posedge clk) begin
        sum <= r * 4'd5 + g * 4'd9 + b * 4'd2;
    end
    assign y = sum[7:4];
    assign pix_out = {y, y, y};
endmodule
