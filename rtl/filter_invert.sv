// ============================================================================
// filter_invert.sv - Color inversion (photographic negative)
//   out = 15 - channel  (bitwise NOT on 4-bit channels)
// Pipelined with 1 register stage for timing parity with other filters.
// ============================================================================
`timescale 1ns/1ps

module filter_invert (
    input  logic        clk,
    input  logic [11:0] pix_in,
    output logic [11:0] pix_out
);
    always_ff @(posedge clk) begin
        pix_out <= ~pix_in;
    end
endmodule
