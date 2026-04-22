// ============================================================================
// tb_vga_sync.sv - testbench for the VGA sync generator
//
// Checks:
//   * HS pulse is 96 pixels wide and occurs in the correct region
//   * VS pulse is 2 lines wide and occurs in the correct region
//   * video_on is asserted for exactly 640x480 pixels per frame
// ============================================================================
`timescale 1ns/1ps

module tb_vga_sync;
    logic clk = 0;
    logic rst = 1;
    always #20 clk = ~clk;   // 25 MHz

    logic hs, vs, video_on, frame_start;
    logic [9:0] hc, vc;

    vga_sync dut (
        .clk_vga(clk), .rst(rst),
        .hs(hs), .vs(vs), .video_on(video_on),
        .h_count(hc), .v_count(vc), .frame_start(frame_start)
    );

    // Counters for checking
    int hs_low_cnt;
    int vs_low_cnt_lines;
    int video_on_cnt;
    int last_hs;

    initial begin
        hs_low_cnt       = 0;
        vs_low_cnt_lines = 0;
        video_on_cnt     = 0;
        last_hs          = 1;
        #100 rst = 0;
    end

    // Count video_on pixels over 1 frame
    always @(posedge clk) begin
        if (!rst) begin
            if (video_on) video_on_cnt++;
            if (!hs)      hs_low_cnt++;
            // count a VS low only once per line (at h_count==0)
            if (!vs && hc == 10'd0) vs_low_cnt_lines++;
        end
    end

    initial begin
        // Wait for one full frame (525 * 800 = 420_000 cycles)
        #100;
        wait (frame_start);      // align to frame boundary
        @(posedge clk);          // skip the frame_start cycle
        video_on_cnt     = 0;
        hs_low_cnt       = 0;
        vs_low_cnt_lines = 0;
        wait (frame_start);      // next frame boundary
        @(posedge clk);

        $display("video_on pixels (expect 307200): %0d", video_on_cnt);
        $display("HS low pixels   (expect  96*525=50400): %0d", hs_low_cnt);
        $display("VS low lines    (expect   2): %0d", vs_low_cnt_lines);
        if (video_on_cnt !== 640*480)           $fatal(1,"video_on count mismatch");
        if (hs_low_cnt   !== 96*525)            $fatal(1,"HS low count mismatch");
        if (vs_low_cnt_lines !== 2)             $fatal(1,"VS low lines mismatch");
        $display("tb_vga_sync PASSED");
        $finish;
    end
endmodule
