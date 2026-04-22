// ============================================================================
// tb_frame_buffer.sv - write ramp pattern from port A, read back from port B
//   at a different clock rate to verify dual-clock BRAM behavior.
// ============================================================================
`timescale 1ns/1ps

module tb_frame_buffer;
    localparam int DW = 12;
    localparam int DEPTH = 320*240;
    localparam int AW = 17;

    logic clk_wr = 0, clk_rd = 0;
    always #10 clk_wr = ~clk_wr;   // 50 MHz
    always #20 clk_rd = ~clk_rd;   // 25 MHz

    logic we = 0;
    logic [AW-1:0] aw_ = 0, ar_ = 0;
    logic [DW-1:0] din = 0, dout;

    frame_buffer #(.DATA_W(DW), .DEPTH(DEPTH), .ADDR_W(AW)) dut (
        .clk_wr(clk_wr), .we(we), .addr_wr(aw_), .din(din),
        .clk_rd(clk_rd), .addr_rd(ar_), .dout(dout)
    );

    initial begin
        // Write 256 ramp values
        for (int i = 0; i < 256; i++) begin
            @(posedge clk_wr);
            aw_ <= i;
            din <= i[11:0];
            we  <= 1;
        end
        @(posedge clk_wr) we <= 0;

        // Read back with separate (slower) clock
        repeat (4) @(posedge clk_rd);
        for (int i = 0; i < 256; i++) begin
            @(posedge clk_rd) ar_ <= i;
            @(posedge clk_rd);   // pipelined BRAM output
            if (dout !== i[11:0]) begin
                $fatal(1,"Mismatch at addr %0d: got %h expected %h",
                       i, dout, i[11:0]);
            end
        end
        $display("tb_frame_buffer PASSED");
        $finish;
    end
endmodule
