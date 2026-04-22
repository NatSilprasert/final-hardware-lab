// ============================================================================
// filter_sobel.sv - 3x3 Sobel edge detection on grayscale input
//
//   Gx = (p02 + 2*p12 + p22) - (p00 + 2*p10 + p20)
//   Gy = (p20 + 2*p21 + p22) - (p00 + 2*p01 + p02)
//   |G| ~= |Gx| + |Gy|
//
// Output is a thresholded black/white RGB444 pixel (0x000 or 0xFFF).
// Threshold is provided at runtime (4-bit slider value).
//
// The 3x3 window is fed by line_buffer_3row; this module only computes
// the convolution.
// ============================================================================
`timescale 1ns/1ps

module filter_sobel (
    input  logic       clk,
    input  logic [3:0] p00, p01, p02,
    input  logic [3:0] p10, p11, p12,
    input  logic [3:0] p20, p21, p22,
    input  logic [3:0] threshold,    // 0..15 -> scaled to 8-bit gradient
    output logic [11:0] pix_out
);

    // Stage 1: compute Gx, Gy
    logic signed [9:0] gx, gy;
    always_ff @(posedge clk) begin
        gx <= $signed({2'b0, p02}) + $signed({1'b0, p12, 1'b0}) + $signed({2'b0, p22})
            - $signed({2'b0, p00}) - $signed({1'b0, p10, 1'b0}) - $signed({2'b0, p20});
        gy <= $signed({2'b0, p20}) + $signed({1'b0, p21, 1'b0}) + $signed({2'b0, p22})
            - $signed({2'b0, p00}) - $signed({1'b0, p01, 1'b0}) - $signed({2'b0, p02});
    end

    // Stage 2: |Gx| + |Gy|
    logic [9:0] abs_gx, abs_gy;
    logic [10:0] mag;
    always_ff @(posedge clk) begin
        abs_gx <= gx[9] ? (~gx + 1'b1) : gx;
        abs_gy <= gy[9] ? (~gy + 1'b1) : gy;
        mag    <= abs_gx + abs_gy;
    end

    // Stage 3: threshold -> B/W
    logic edge_bit;
    always_ff @(posedge clk) begin
        // Scale threshold (4-bit, 0..15) roughly to the range of mag (0..120).
        // Use threshold<<3 -> 0..120.
        edge_bit <= (mag > ({threshold, 3'b000}));
        pix_out  <= edge_bit ? 12'hFFF : 12'h000;
    end

endmodule
