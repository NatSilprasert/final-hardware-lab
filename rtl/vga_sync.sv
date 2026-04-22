// ============================================================================
// vga_sync.sv - 640x480 @ 60 Hz VGA synchronization generator
//
// VESA timing (pixel clock = 25.175 MHz nominal; we use 25.000 MHz from MMCM,
// which is within monitor tolerance):
//
//   Horizontal (pixels):  visible 640 | front 16 | sync 96 | back 48  = 800
//   Vertical   (lines) :  visible 480 | front 10 | sync  2 | back 33  = 525
//   Sync polarity      :  negative (active low for both HS and VS)
//
// Outputs counters and video_on so downstream logic can fetch pixel data
// during the visible region only.
// ============================================================================
`timescale 1ns/1ps

module vga_sync #(
    parameter int H_VISIBLE = 640,
    parameter int H_FRONT   = 16,
    parameter int H_SYNC    = 96,
    parameter int H_BACK    = 48,
    parameter int V_VISIBLE = 480,
    parameter int V_FRONT   = 10,
    parameter int V_SYNC    = 2,
    parameter int V_BACK    = 33
) (
    input  logic        clk_vga,
    input  logic        rst,
    output logic        hs,
    output logic        vs,
    output logic        video_on,
    output logic [9:0]  h_count,   // 0..799
    output logic [9:0]  v_count,   // 0..524
    output logic        frame_start // 1-cycle pulse at (0,0)
);

    localparam int H_TOTAL = H_VISIBLE + H_FRONT + H_SYNC + H_BACK; // 800
    localparam int V_TOTAL = V_VISIBLE + V_FRONT + V_SYNC + V_BACK; // 525

    localparam int H_SYNC_START = H_VISIBLE + H_FRONT;              // 656
    localparam int H_SYNC_END   = H_SYNC_START + H_SYNC;            // 752
    localparam int V_SYNC_START = V_VISIBLE + V_FRONT;              // 490
    localparam int V_SYNC_END   = V_SYNC_START + V_SYNC;            // 492

    // Pixel and line counters
    always_ff @(posedge clk_vga) begin
        if (rst) begin
            h_count <= '0;
            v_count <= '0;
        end else if (h_count == H_TOTAL - 1) begin
            h_count <= '0;
            v_count <= (v_count == V_TOTAL - 1) ? '0 : v_count + 10'd1;
        end else begin
            h_count <= h_count + 10'd1;
        end
    end

    // Active-low sync pulses
    assign hs       = ~((h_count >= H_SYNC_START) && (h_count < H_SYNC_END));
    assign vs       = ~((v_count >= V_SYNC_START) && (v_count < V_SYNC_END));
    assign video_on = (h_count < H_VISIBLE) && (v_count < V_VISIBLE);
    assign frame_start = (h_count == 10'd0) && (v_count == 10'd0);

endmodule
