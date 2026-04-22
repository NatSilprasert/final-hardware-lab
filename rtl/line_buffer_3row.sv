// ============================================================================
// line_buffer_3row.sv - shifting 3-row window for 3x3 convolutions
//
//   Every new pixel is written into row0 at (we_col).  Before being over-
//   written, the old row0 value is forwarded into row1, and row1 into row2.
//   This is implemented with three simple dual-port BRAM line buffers (one
//   per row) and two forwarding registers.
//
//   Outputs the 3x3 window [p00..p22] for the (we_col-1) pixel:
//        p00 p01 p02        p02 = incoming current row (same row new pixel)
//        p10 p11 p12        p11 = center pixel (previous-row at col-1)
//        p20 p21 p22        p22 = oldest row (2 rows back)
//
// Note: for the first two rows of a frame the window is not meaningful;
// caller must mask those output pixels.
// ============================================================================
`timescale 1ns/1ps

module line_buffer_3row #(
    parameter int DATA_W    = 4,    // intensity width (4-bit grayscale)
    parameter int MAX_COLS  = 640,
    parameter int COL_W     = $clog2(MAX_COLS)
) (
    input  logic                clk,
    input  logic                rst,
    input  logic                we,          // strobe each valid pixel
    input  logic [DATA_W-1:0]   din,
    input  logic [COL_W-1:0]    col,         // column index of current pixel
    input  logic                new_row,     // pulse at start of every row

    output logic [DATA_W-1:0]   p00, p01, p02,
    output logic [DATA_W-1:0]   p10, p11, p12,
    output logic [DATA_W-1:0]   p20, p21, p22,
    output logic [COL_W-1:0]    win_col,     // col of center pixel (p11)
    output logic                win_valid    // 1 when window has >=3 rows
);

    // ---- BRAM for the two older rows ----
    (* ram_style = "block" *) logic [DATA_W-1:0] ram_row1 [0:MAX_COLS-1];
    (* ram_style = "block" *) logic [DATA_W-1:0] ram_row2 [0:MAX_COLS-1];

    logic [DATA_W-1:0] row1_q, row2_q;

    // Forward shift regs for left/center neighbours within current row
    logic [DATA_W-1:0] r0_0, r0_1, r0_2;   // p00=r0_2, p01=r0_1, p02=r0_0? see below
    logic [DATA_W-1:0] r1_0, r1_1, r1_2;
    logic [DATA_W-1:0] r2_0, r2_1, r2_2;

    // We track how many rows have been received
    logic [1:0] rows_seen;
    always_ff @(posedge clk) begin
        if (rst) rows_seen <= 2'd0;
        else if (new_row && rows_seen != 2'd3) rows_seen <= rows_seen + 2'd1;
    end
    assign win_valid = (rows_seen >= 2'd3);

    // Read BRAM one cycle ahead (synchronous read)
    always_ff @(posedge clk) begin
        row1_q <= ram_row1[col];
        row2_q <= ram_row2[col];
    end

    // Write paths: incoming pixel goes into row0 (forwarding), then when
    // we advance the column, the old row1 value is written into row2 and
    // the old row0 value (register) into row1.
    //
    // Simple 3-row rolling buffer implementation: we write the incoming
    // pixel to ram_row1 at (col), and the old ram_row1[col] (row1_q) to
    // ram_row2[col] on the same cycle.  This gives us 3 virtual rows.
    always_ff @(posedge clk) begin
        if (we) begin
            ram_row2[col] <= row1_q;
            ram_row1[col] <= din;
        end
    end

    // Column shift registers for producing 3-wide horizontal window
    always_ff @(posedge clk) begin
        if (we) begin
            // Row 0 (current)
            r0_2 <= r0_1; r0_1 <= r0_0; r0_0 <= din;
            // Row 1 (previous)  - row1_q is delayed-by-1 relative to din;
            // keep in-phase by feeding row1_q
            r1_2 <= r1_1; r1_1 <= r1_0; r1_0 <= row1_q;
            // Row 2 (two back)
            r2_2 <= r2_1; r2_1 <= r2_0; r2_0 <= row2_q;
        end
    end

    // Map to conventional 3x3 window (p00 is top-left, p22 is bottom-right)
    // Top row    = ram_row2   -> r2_*
    // Middle row = ram_row1_q -> r1_*
    // Bottom row = current    -> r0_*
    assign p00 = r2_2; assign p01 = r2_1; assign p02 = r2_0;
    assign p10 = r1_2; assign p11 = r1_1; assign p12 = r1_0;
    assign p20 = r0_2; assign p21 = r0_1; assign p22 = r0_0;

    // Center pixel column = col - 1 (accounting for 1 col-wide shift)
    assign win_col = (col == 0) ? '0 : col - 1;

endmodule
