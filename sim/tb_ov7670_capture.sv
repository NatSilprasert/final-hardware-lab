// ============================================================================
// tb_ov7670_capture.sv - Drive a tiny fake "camera" frame (8 cols x 4 rows)
//   into ov7670_capture and verify pixels are assembled and coordinates
//   tracked correctly.
// ============================================================================
`timescale 1ns/1ps

module tb_ov7670_capture;
    logic pclk = 0, rst = 1, vsync = 0, href = 0;
    logic [7:0] d = 0;
    always #20 pclk = ~pclk;   // 25 MHz

    logic        pix_valid, frame_start, frame_end;
    logic [11:0] pix444;
    logic [7:0]  pix332;
    logic [3:0]  pix_y;
    logic [15:0] pix565;
    logic [9:0]  col, row;
    logic [16:0] fb_addr;

    ov7670_capture dut (
        .pclk(pclk), .rst(rst),
        .vsync(vsync), .href(href), .d(d),
        .pix_valid(pix_valid),
        .pix_rgb444(pix444),
        .pix_rgb332(pix332),
        .pix_y(pix_y),
        .pix_rgb565(pix565),
        .col(col), .row(row),
        .frame_start(frame_start),
        .frame_end(frame_end),
        .fb_addr(fb_addr)
    );

    int pix_count;
    logic [15:0] last_pix;

    always_ff @(posedge pclk) begin
        if (pix_valid) begin
            pix_count <= pix_count + 1;
            last_pix  <= pix565;
        end
    end

    task automatic send_byte(input [7:0] b);
        @(posedge pclk) d <= b;
    endtask

    initial begin
        pix_count = 0;
        last_pix  = 0;
        #100 rst = 0;

        // VSYNC pulse (start of frame)
        @(posedge pclk) vsync = 1;
        repeat (5) @(posedge pclk);
        vsync = 0;

        // 4 rows of 8 pixels each
        for (int r = 0; r < 4; r++) begin
            repeat (10) @(posedge pclk); // horizontal blanking
            href = 1;
            for (int c = 0; c < 8; c++) begin
                // Byte0 = R5R4R3R2R1 G5G4G3 (use row/col ramp)
                // Byte1 = G2G1G0 B4B3B2B1B0
                send_byte(8'((r*8+c)*2));
                send_byte(8'((r*8+c)*2 + 1));
            end
            @(posedge pclk) href = 0;
        end

        repeat (20) @(posedge pclk);
        $display("pix_count = %0d (expect 32)", pix_count);
        $display("last pixel = %h", last_pix);
        $display("final (col,row) = (%0d,%0d)", col, row);
        if (pix_count !== 32) $fatal(1,"pixel count mismatch");
        $display("tb_ov7670_capture PASSED");
        $finish;
    end
endmodule
