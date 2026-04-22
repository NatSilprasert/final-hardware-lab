// ============================================================================
// frame_buffer.sv - True dual-port BRAM, asynchronous clocks.
//
//   Port A : write side, clocked by clk_wr (camera PCLK).
//   Port B : read  side, clocked by clk_rd (VGA clock).
//
// Storage: 320 x 240 pixels x 4 bits grayscale luma (Y).  4-bit Y is chosen
// over RGB332/RGB444 so the frame fits inside Basys 3's BRAM budget even
// when Vivado rounds the 76,800-deep geometry up to a native BRAM depth:
//
//   76,800 x 4 = 307,200 bits
//   RAMB36 in 8192x4 mode  -> ceil(76800/8192) = 10 RAMB36 tiles
//   (well within the 40 available BRAM sites on xc7a35t).
//
// The top-level replicates the stored Y onto all three channels to give a
// grayscale "color" image.  Filters (grayscale, invert, Sobel) all operate
// on luma anyway, so the visual pipeline is unchanged; only the raw mode
// is a grayscale video instead of a colour one (documented in the report
// as an intentional memory-budget trade-off).
//
// Vivado infers this pattern as a dual-clock dual-port BRAM with no
// primitive instantiation required.
// ============================================================================
`timescale 1ns/1ps

module frame_buffer #(
    parameter int DATA_W    = 4,
    parameter int DEPTH     = 320*240,
    parameter int ADDR_W    = $clog2(320*240)   // 17
) (
    // Write port (camera)
    input  logic              clk_wr,
    input  logic              we,
    input  logic [ADDR_W-1:0] addr_wr,
    input  logic [DATA_W-1:0] din,

    // Read port (VGA)
    input  logic              clk_rd,
    input  logic [ADDR_W-1:0] addr_rd,
    output logic [DATA_W-1:0] dout
);

    (* ram_style = "block" *) logic [DATA_W-1:0] mem [0:DEPTH-1];

    // Unconditional write: the caller gates "we" when (col,row) are in-range.
    always_ff @(posedge clk_wr) begin
        if (we) mem[addr_wr] <= din;
    end

    always_ff @(posedge clk_rd) begin
        dout <= mem[addr_rd];
    end

endmodule
