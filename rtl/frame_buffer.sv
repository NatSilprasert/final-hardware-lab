// ============================================================================
// frame_buffer.sv - True dual-port BRAM, asynchronous clocks
//
//   Port A : write side, clocked by clk_wr (camera PCLK).
//   Port B : read  side, clocked by clk_rd (VGA clock).
//
// Size : 320 x 240 pixels x 12 bits RGB444
//   = 76,800 x 12 = 921,600 bits  (~51% of Basys3 BRAM)
//
// Vivado infers this pattern as true dual-port BRAM automatically.
// ============================================================================
`timescale 1ns/1ps

module frame_buffer #(
    parameter int DATA_W    = 12,
    parameter int DEPTH     = 320*240,
    parameter int ADDR_W    = 17     // $clog2(76800) = 17
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

    always_ff @(posedge clk_wr) begin
        if (we && addr_wr < DEPTH) mem[addr_wr] <= din;
    end

    always_ff @(posedge clk_rd) begin
        dout <= mem[addr_rd];
    end

endmodule
