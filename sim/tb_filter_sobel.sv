// ============================================================================
// tb_filter_sobel.sv - Verify Sobel on a simple synthetic 8x8 image where
//   the left half is black and the right half is white.  The edge column
//   should produce high magnitude; other columns should be near 0.
// ============================================================================
`timescale 1ns/1ps

module tb_filter_sobel;
    logic clk = 0;
    always #5 clk = ~clk;
    logic [3:0] p00,p01,p02,p10,p11,p12,p20,p21,p22;
    logic [3:0] thr = 4'd2;
    logic [11:0] pix;

    filter_sobel dut (
        .clk(clk),
        .p00(p00),.p01(p01),.p02(p02),
        .p10(p10),.p11(p11),.p12(p12),
        .p20(p20),.p21(p21),.p22(p22),
        .threshold(thr),
        .pix_out(pix)
    );

    // Build a 5x5 image of an edge at column 2: 00 00 0F 0F 0F per row
    logic [3:0] img [0:4][0:4];
    int r,c;
    initial begin
        for (r=0;r<5;r++) for (c=0;c<5;c++)
            img[r][c] = (c >= 2) ? 4'hF : 4'h0;

        // Present the center 3x3 window at (1..3,1..3) with center at (2,2)
        p00=img[1][1]; p01=img[1][2]; p02=img[1][3];
        p10=img[2][1]; p11=img[2][2]; p12=img[2][3];
        p20=img[3][1]; p21=img[3][2]; p22=img[3][3];

        repeat (5) @(posedge clk);
        $display("Sobel on vertical edge: pix_out=%h (expect FFF)", pix);
        if (pix !== 12'hFFF) $fatal(1,"edge not detected");

        // Uniform area (all 0x5): should be below threshold
        for (r=0;r<5;r++) for (c=0;c<5;c++) img[r][c] = 4'h5;
        p00=img[1][1]; p01=img[1][2]; p02=img[1][3];
        p10=img[2][1]; p11=img[2][2]; p12=img[2][3];
        p20=img[3][1]; p21=img[3][2]; p22=img[3][3];

        repeat (5) @(posedge clk);
        $display("Sobel on flat area:   pix_out=%h (expect 000)", pix);
        if (pix !== 12'h000) $fatal(1,"false edge on flat area");

        $display("tb_filter_sobel PASSED");
        $finish;
    end
endmodule
