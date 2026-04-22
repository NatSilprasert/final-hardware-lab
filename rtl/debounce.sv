// ============================================================================
// debounce.sv - Simple slow-clock resampling debouncer.
// Suitable for slide switches and push buttons on Basys3.
// ============================================================================
`timescale 1ns/1ps

module debounce #(
    parameter int CLK_FREQ_HZ = 100_000_000,
    parameter int BOUNCE_MS   = 5
) (
    input  logic clk,
    input  logic rst,
    input  logic noisy,
    output logic clean
);
    localparam int MAX = CLK_FREQ_HZ / 1000 * BOUNCE_MS;
    localparam int W   = $clog2(MAX + 1);

    logic [W-1:0] cnt;
    logic         sync0, sync1;

    always_ff @(posedge clk) begin
        sync0 <= noisy;
        sync1 <= sync0;
        if (rst) begin
            cnt   <= '0;
            clean <= 1'b0;
        end else if (sync1 != clean) begin
            if (cnt == MAX - 1) begin
                clean <= sync1;
                cnt   <= '0;
            end else cnt <= cnt + 1;
        end else cnt <= '0;
    end
endmodule
