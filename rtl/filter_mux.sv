// ============================================================================
// filter_mux.sv - Select between raw / grayscale / invert / sobel.
//
//   filter_sel :
//      2'b00 -> raw RGB444 from buffer
//      2'b01 -> grayscale
//      2'b10 -> color inversion
//      2'b11 -> Sobel edge
//
// All inputs are registered inside their respective filter cores so this
// module is a straightforward 4:1 combinational mux that is further
// registered once for timing.
// ============================================================================
`timescale 1ns/1ps

module filter_mux (
    input  logic        clk,
    input  logic [1:0]  filter_sel,
    input  logic [11:0] raw,
    input  logic [11:0] gray,
    input  logic [11:0] inv,
    input  logic [11:0] sobel,
    output logic [11:0] pix_out
);
    always_ff @(posedge clk) begin
        unique case (filter_sel)
            2'b00: pix_out <= raw;
            2'b01: pix_out <= gray;
            2'b10: pix_out <= inv;
            2'b11: pix_out <= sobel;
            default: pix_out <= raw;
        endcase
    end
endmodule
