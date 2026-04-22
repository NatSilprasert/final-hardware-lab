// ============================================================================
// cam_configurator.sv - Walks the SCCB ROM and writes every entry to the
//                       camera at boot.  Re-triggers whenever mode_sel toggles.
//
//  * Holds rst_cam low briefly at start-up.
//  * Issues SCCB writes for each ROM entry in order.
//  * Handles "delay" markers (0xFF, N) by stalling for N ms (CLK_FREQ_HZ-based).
//  * Asserts "cfg_done" when the whole table is flushed.
// ============================================================================
`timescale 1ns/1ps

module cam_configurator #(
    parameter int CLK_FREQ_HZ = 100_000_000
) (
    input  logic        clk,
    input  logic        rst,
    input  logic        mode_sel,   // 0=QVGA, 1=VGA  (edge -> restart cfg)

    // Drive camera power-up signals
    output logic        cam_rst_n,
    output logic        cam_pwdn,

    // Hook to SCCB master
    output logic        start,
    output logic [7:0]  dev_id,
    output logic [7:0]  sub_addr,
    output logic [7:0]  data,
    input  logic        busy,
    input  logic        done,

    output logic        cfg_done
);

    localparam int MS_TICKS = CLK_FREQ_HZ / 1000;  // cycles per 1 ms

    typedef enum logic [3:0] {
        S_POR_RESET,      // hold cam reset low
        S_POR_WAIT,       // release reset, wait 10 ms before SCCB
        S_FETCH,
        S_DELAY,
        S_WRITE_START,
        S_WRITE_WAIT,
        S_NEXT,
        S_DONE
    } state_t;

    state_t state;
    logic [7:0]  idx;
    logic [31:0] wait_cnt;
    logic [15:0] delay_ms_left;

    // ROM outputs
    logic [7:0] rom_sub, rom_data;
    logic       rom_end, rom_delay;
    sccb_rom u_rom (
        .mode_sel (mode_sel),
        .index    (idx),
        .sub_addr (rom_sub),
        .data     (rom_data),
        .is_end   (rom_end),
        .is_delay (rom_delay)
    );

    // Detect mode_sel change -> restart configuration
    logic mode_sel_q;
    logic mode_changed;
    always_ff @(posedge clk) begin
        if (rst) mode_sel_q <= mode_sel;
        else     mode_sel_q <= mode_sel;
    end
    assign mode_changed = (mode_sel != mode_sel_q);

    assign dev_id   = 8'h42;
    assign sub_addr = rom_sub;
    assign data     = rom_data;

    always_ff @(posedge clk) begin
        if (rst) begin
            state         <= S_POR_RESET;
            idx           <= '0;
            wait_cnt      <= '0;
            delay_ms_left <= '0;
            cam_rst_n     <= 1'b0;  // hold reset low
            cam_pwdn      <= 1'b0;  // powered on
            start         <= 1'b0;
            cfg_done      <= 1'b0;
        end else begin
            start <= 1'b0;

            if (mode_changed) begin
                // Restart the whole config sequence
                state    <= S_POR_RESET;
                idx      <= '0;
                wait_cnt <= '0;
                cfg_done <= 1'b0;
            end

            unique case (state)
                S_POR_RESET: begin
                    cam_rst_n <= 1'b0;
                    if (wait_cnt == 32'd10*MS_TICKS) begin  // 10 ms
                        cam_rst_n <= 1'b1;
                        wait_cnt  <= '0;
                        state     <= S_POR_WAIT;
                    end else wait_cnt <= wait_cnt + 1;
                end
                S_POR_WAIT: begin
                    cam_rst_n <= 1'b1;
                    if (wait_cnt == 32'd10*MS_TICKS) begin
                        wait_cnt <= '0;
                        state    <= S_FETCH;
                    end else wait_cnt <= wait_cnt + 1;
                end
                S_FETCH: begin
                    if (rom_end) begin
                        state    <= S_DONE;
                        cfg_done <= 1'b1;
                    end else if (rom_delay) begin
                        delay_ms_left <= {8'd0, rom_data};
                        wait_cnt      <= '0;
                        state         <= S_DELAY;
                    end else begin
                        state <= S_WRITE_START;
                    end
                end
                S_DELAY: begin
                    if (wait_cnt == MS_TICKS - 1) begin
                        wait_cnt <= '0;
                        if (delay_ms_left == 16'd1) begin
                            idx   <= idx + 1;
                            state <= S_FETCH;
                        end else begin
                            delay_ms_left <= delay_ms_left - 1;
                        end
                    end else wait_cnt <= wait_cnt + 1;
                end
                S_WRITE_START: begin
                    if (!busy) begin
                        start <= 1'b1;
                        state <= S_WRITE_WAIT;
                    end
                end
                S_WRITE_WAIT: begin
                    if (done) begin
                        idx   <= idx + 1;
                        state <= S_NEXT;
                    end
                end
                S_NEXT: begin
                    // Small inter-command gap (~1 quarter-ms)
                    if (wait_cnt == (MS_TICKS/4)) begin
                        wait_cnt <= '0;
                        state    <= S_FETCH;
                    end else wait_cnt <= wait_cnt + 1;
                end
                S_DONE: begin
                    cfg_done <= 1'b1;
                end
                default: state <= S_POR_RESET;
            endcase
        end
    end

endmodule
