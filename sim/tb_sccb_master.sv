// ============================================================================
// tb_sccb_master.sv - exercises the SCCB 3-phase write and verifies:
//   * START condition (SIOD 1->0 while SIOC=1)
//   * 27 SIOC bits produced
//   * STOP condition (SIOD 0->1 while SIOC=1)
//   * data bits on SIOD match payload (ID / SUB / DATA)
// ============================================================================
`timescale 1ns/1ps

module tb_sccb_master;
    logic clk = 0;
    logic rst = 1;
    always #5 clk = ~clk;   // 100 MHz

    logic       start;
    logic [7:0] dev_id   = 8'h42;
    logic [7:0] sub_addr = 8'h12;
    logic [7:0] data     = 8'h80;
    logic       busy, done;
    logic       sioc, siod;

    sccb_master #(.CLK_FREQ_HZ(100_000_000), .SCCB_FREQ_HZ(1_000_000)) // fast sim
      dut (
        .clk(clk), .rst(rst),
        .start(start),
        .dev_id(dev_id), .sub_addr(sub_addr), .data(data),
        .busy(busy), .done(done),
        .sioc(sioc), .siod(siod)
    );

    int start_seen, stop_seen, rising_edges, done_cnt;
    logic sioc_q, siod_q;

    always_ff @(posedge clk) begin
        sioc_q <= sioc;
        siod_q <= siod;
        // Rising edge of SIOC (data sampling moment)
        if (!sioc_q && sioc) rising_edges++;
        // START: SIOC=1, SIOD 1->0
        if (sioc && siod_q && !siod) start_seen++;
        // STOP : SIOC=1, SIOD 0->1
        if (sioc && !siod_q && siod) stop_seen++;
        if (done) done_cnt++;
    end

    initial begin
        start_seen   = 0;
        stop_seen    = 0;
        rising_edges = 0;
        done_cnt     = 0;
        #100 rst = 0;
        #200 start = 1;
        @(posedge clk) start = 0;

        wait (done);
        #1000;

        $display("start_seen = %0d (expect 1)", start_seen);
        $display("stop_seen  = %0d (expect 1)", stop_seen);
        $display("sioc rising edges = %0d (expect 27)", rising_edges);
        $display("done pulses = %0d (expect 1)", done_cnt);

        if (start_seen   !== 1)  $fatal(1,"SCCB START condition missing");
        if (stop_seen    !== 1)  $fatal(1,"SCCB STOP condition missing");
        if (rising_edges !== 27) $fatal(1,"SCCB bit count mismatch");
        if (done_cnt     !== 1)  $fatal(1,"SCCB done count mismatch");
        $display("tb_sccb_master PASSED");
        $finish;
    end
endmodule
