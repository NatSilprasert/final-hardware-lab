// ============================================================================
// mode_ctrl.sv - Switch/button decoding and user-controllable parameters
//
//   sw[1:0]   : filter select   -> filter_sel
//   sw[5:2]   : Sobel threshold (4 bits, 0..15)
//   sw[15]    : resolution mode -> 0 = QVGA buffered, 1 = VGA stream-through
//   btnC      : global reset
// ============================================================================
`timescale 1ns/1ps

module mode_ctrl #(
    parameter int CLK_FREQ_HZ = 100_000_000
) (
    input  logic        clk,
    input  logic        rst_ext,        // raw btnC
    input  logic [15:0] sw,
    output logic        rst,            // synchronous reset pulse
    output logic [1:0]  filter_sel,
    output logic [3:0]  sobel_thr,
    output logic        mode_sel        // 0=QVGA, 1=VGA
);
    logic btn_clean;
    debounce #(.CLK_FREQ_HZ(CLK_FREQ_HZ), .BOUNCE_MS(5)) u_btn (
        .clk(clk), .rst(1'b0), .noisy(rst_ext), .clean(btn_clean)
    );

    // Synchronize switches (no debounce needed for slide switches)
    logic [15:0] sw_s0, sw_s1;
    always_ff @(posedge clk) begin
        sw_s0 <= sw;
        sw_s1 <= sw_s0;
    end

    assign rst        = btn_clean;
    assign filter_sel = sw_s1[1:0];
    assign sobel_thr  = sw_s1[5:2];
    assign mode_sel   = sw_s1[15];
endmodule
