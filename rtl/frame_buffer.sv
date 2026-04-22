// ============================================================================
// frame_buffer.sv - True dual-port BRAM, asynchronous clocks.
//
//   Port A : write side, clocked by clk_wr (camera PCLK).
//   Port B : read  side, clocked by clk_rd (VGA clock).
//
// Storage: 320 x 240 pixels x 8 bits RGB332.  We store RGB332 to stay well
// within the Basys 3 BRAM budget (76,800 x 8 = 614,400 bits ~= 34% of the
// 1.8 Mbit BRAM).  The top-level expands RGB332 back to RGB444 by
// bit-replication before feeding filters so the visual pipeline is unchanged.
//
// Packing with 8-bit words lets Vivado use a RAMB36 in the 4096x9
// configuration, giving about 19 RAMB36 sites for the frame buffer
// (fits comfortably in the Artix-7 35T).
//
// Vivado infers this pattern as a dual-clock dual-port BRAM without any
// primitive instantiations.  We explicitly hint ram_style = "block" and
// omit the address bound check so the tool does not insert a comparator
// that blocks BRAM inference.
// ============================================================================
`timescale 1ns/1ps

module frame_buffer #(
    parameter int DATA_W    = 8,
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

    // Unconditional write: the caller gates "we" when (col,row) are in-range,
    // so no range check is needed here.  Removing it keeps the inference
    // pattern simple and lets Vivado pack efficiently.
    always_ff @(posedge clk_wr) begin
        if (we) mem[addr_wr] <= din;
    end

    always_ff @(posedge clk_rd) begin
        dout <= mem[addr_rd];
    end

endmodule
