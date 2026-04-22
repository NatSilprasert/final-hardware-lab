// ============================================================================
// tb_top_integration.sv - Light-weight integration test
//
// Stimulates top.sv with:
//   * a 100 MHz clk
//   * an active btnC for 1 us then released
//   * a fake camera PCLK (25 MHz), VSYNC, HREF and a ramp on D[7:0]
// The goal is to make sure all modules connect, synthesize in simulation,
// and produce vga_hs/vga_vs pulses.  Functional verification of image
// contents is left to per-module testbenches.
// ============================================================================
`timescale 1ns/1ps
`define SIMULATION

module tb_top_integration;
    logic clk = 0;            // 100 MHz
    logic btnC = 1;
    logic [15:0] sw = 16'h0000;
    logic [15:0] led;

    logic [3:0] vga_r, vga_g, vga_b;
    logic vga_hs, vga_vs;

    // Camera
    logic [7:0] cam_data = 8'h00;
    logic cam_href = 0, cam_pclk = 0, cam_vsync = 0;
    logic cam_xclk, cam_rst_n, cam_pwdn;
    wire  cam_sioc, cam_siod;

    // Pull-up resistors on SCCB lines
    pullup (cam_sioc);
    pullup (cam_siod);

    always #5 clk = ~clk;            // 100 MHz
    always #20 cam_pclk = ~cam_pclk; // 25 MHz

    top dut (
        .clk(clk), .btnC(btnC), .btnU(1'b0), .btnD(1'b0),
        .btnL(1'b0), .btnR(1'b0), .sw(sw), .led(led),
        .vga_r(vga_r), .vga_g(vga_g), .vga_b(vga_b),
        .vga_hs(vga_hs), .vga_vs(vga_vs),
        .cam_data(cam_data), .cam_href(cam_href),
        .cam_pclk(cam_pclk), .cam_vsync(cam_vsync),
        .cam_xclk(cam_xclk), .cam_rst_n(cam_rst_n),
        .cam_pwdn(cam_pwdn),
        .cam_sioc(cam_sioc), .cam_siod(cam_siod)
    );

    // Release reset shortly after start
    initial begin
        #200 btnC = 0;
    end

    // Simulate a tiny QVGA frame: 10 rows x 16 cols, then stop
    int r, c;
    initial begin
        #2_000;     // wait for some bring-up
        forever begin
            @(posedge cam_pclk) cam_vsync = 1;
            repeat (4) @(posedge cam_pclk);
            cam_vsync = 0;
            for (r = 0; r < 10; r++) begin
                repeat (8) @(posedge cam_pclk);
                cam_href = 1;
                for (c = 0; c < 32; c++) begin  // 16 pixels * 2 bytes = 32
                    @(posedge cam_pclk) cam_data = r*16 + (c >> 1);
                end
                @(posedge cam_pclk) cam_href = 0;
            end
            repeat (50) @(posedge cam_pclk);
        end
    end

    // Watch for VGA sync activity
    int hs_edges;
    always_ff @(posedge vga_hs) hs_edges++;

    initial begin
        hs_edges = 0;
        #5_000_000;   // 5 ms simulated
        $display("HS edges in 5 ms: %0d (expect >0)", hs_edges);
        if (hs_edges == 0) $fatal(1,"No HS edges seen -- VGA output dead");
        $display("tb_top_integration PASSED (smoke test)");
        $finish;
    end
endmodule
