// ============================================================================
// sccb_master.sv - SCCB (I2C-like) 3-phase write master for OV7670
//
// Operation:
//   * Idle while start=0; on start=1 perform one 3-phase write:
//       Phase 1: device ID (0x42 = OV7670 write address)
//       Phase 2: sub-address (register)
//       Phase 3: data
//     followed by STOP.
//   * "done" pulses high one sys_clk cycle after STOP completes.
//
// Timing:
//   * tCYC >= 10us (SCCB spec 2.2).  We therefore target ~100 kHz SIOC
//     using a programmable prescaler from the system clock.
//   * SIOC/SIOD are driven as open-drain: we only drive low or Z (high-Z),
//     relying on the external pull-up (configured in XDC).  In the 2-wire
//     modified SCCB used by OV7670 the master can just drive high/low too
//     and note transitions; we use open-drain which is safer.
// ============================================================================
`timescale 1ns/1ps

module sccb_master #(
    parameter int CLK_FREQ_HZ  = 100_000_000, // system clock
    parameter int SCCB_FREQ_HZ = 100_000      // target SIOC frequency
) (
    input  logic        clk,
    input  logic        rst,

    input  logic        start,       // pulse high to begin one transaction
    input  logic [7:0]  dev_id,      // normally 8'h42
    input  logic [7:0]  sub_addr,    // register address
    input  logic [7:0]  data,        // register value
    output logic        busy,
    output logic        done,        // 1-cycle when a transaction completes

    // Open-drain tri-state SCCB pads (top-level wires these to IOBUF)
    output logic        sioc,        // 1 = release (pull-up), 0 = drive low
    output logic        siod
);

    // ---------- Bit-time prescaler ----------
    // One SCCB bit = 4 quarters (to build setup/hold on SIOD around SIOC).
    // So the prescaler interval = CLK_FREQ_HZ / (SCCB_FREQ_HZ * 4)
    localparam int QUARTER_DIV = CLK_FREQ_HZ / (SCCB_FREQ_HZ * 4);
    localparam int CNT_W       = $clog2(QUARTER_DIV + 1);

    logic [CNT_W-1:0] q_cnt;     // quarter-tick prescaler
    logic             q_tick;    // one-cycle pulse every quarter-bit
    logic [1:0]       phase_q;   // 0..3 inside a bit

    // ---------- FSM ----------
    typedef enum logic [3:0] {
        S_IDLE,
        S_START1, S_START2,   // generate START (SIOD 1->0 while SIOC=1)
        S_BIT,                // shifting 27 bits of payload
        S_STOP1, S_STOP2,     // generate STOP  (SIOD 0->1 while SIOC=1)
        S_DONE
    } state_t;

    state_t state, next_state;

    // Shift register holds the 27-bit SCCB payload:
    //   ID(8) + ACK(1=don'tcare) + SUB(8) + ACK(1) + DATA(8) + ACK(1)  = 27 bits
    logic [26:0] shreg;
    logic [4:0]  bit_cnt;   // counts 0..26

    // Drive values (1 = release line, 0 = pull low)
    logic sioc_drv, siod_drv;

    // Quarter-bit prescaler
    always_ff @(posedge clk) begin
        if (rst) begin
            q_cnt  <= '0;
            q_tick <= 1'b0;
        end else if (q_cnt == QUARTER_DIV - 1) begin
            q_cnt  <= '0;
            q_tick <= 1'b1;
        end else begin
            q_cnt  <= q_cnt + 1'b1;
            q_tick <= 1'b0;
        end
    end

    // Phase within a bit
    always_ff @(posedge clk) begin
        if (rst)                               phase_q <= 2'd0;
        else if (q_tick && state != S_IDLE)    phase_q <= phase_q + 2'd1;
        else if (state == S_IDLE)              phase_q <= 2'd0;
    end

    // Main FSM
    always_ff @(posedge clk) begin
        if (rst) begin
            state   <= S_IDLE;
            bit_cnt <= '0;
            shreg   <= '0;
        end else begin
            case (state)
                S_IDLE: begin
                    bit_cnt <= '0;
                    if (start) begin
                        shreg <= {dev_id, 1'b1, sub_addr, 1'b1, data, 1'b1};
                        state <= S_START1;
                    end
                end
                S_START1: if (q_tick && phase_q == 2'd3) state <= S_START2;
                S_START2: if (q_tick && phase_q == 2'd3) state <= S_BIT;
                S_BIT: begin
                    if (q_tick && phase_q == 2'd3) begin
                        shreg   <= {shreg[25:0], 1'b1};
                        if (bit_cnt == 5'd26) begin
                            state   <= S_STOP1;
                            bit_cnt <= '0;
                        end else begin
                            bit_cnt <= bit_cnt + 5'd1;
                        end
                    end
                end
                S_STOP1:  if (q_tick && phase_q == 2'd3) state <= S_STOP2;
                S_STOP2:  if (q_tick && phase_q == 2'd3) state <= S_DONE;
                S_DONE:   state <= S_IDLE;
                default:  state <= S_IDLE;
            endcase
        end
    end

    // Line driving logic (open-drain: 1 means release, 0 means pull low)
    //
    // Bit phases (q = 0..3):
    //   q=0: SIOC low, SIOD setup
    //   q=1: SIOC high (data latched by slave on rising edge)
    //   q=2: SIOC high
    //   q=3: SIOC low
    always_comb begin
        sioc_drv = 1'b1;
        siod_drv = 1'b1;
        unique case (state)
            S_IDLE: begin
                sioc_drv = 1'b1; siod_drv = 1'b1;
            end
            S_START1: begin
                // Both high first half, then SIOD goes low (start condition)
                sioc_drv = 1'b1;
                siod_drv = (phase_q < 2'd2) ? 1'b1 : 1'b0;
            end
            S_START2: begin
                // SIOD stays low, SIOC goes low
                sioc_drv = (phase_q < 2'd2) ? 1'b1 : 1'b0;
                siod_drv = 1'b0;
            end
            S_BIT: begin
                // SIOC: low in q=0 and q=3, high in q=1 and q=2
                sioc_drv = (phase_q == 2'd1) || (phase_q == 2'd2);
                // SIOD: MSB first from shreg
                siod_drv = shreg[26];
            end
            S_STOP1: begin
                // SIOC rises while SIOD still low
                sioc_drv = (phase_q >= 2'd1);
                siod_drv = 1'b0;
            end
            S_STOP2: begin
                // SIOD rises -> stop condition
                sioc_drv = 1'b1;
                siod_drv = (phase_q >= 2'd1);
            end
            S_DONE: begin
                sioc_drv = 1'b1; siod_drv = 1'b1;
            end
            default: begin
                sioc_drv = 1'b1; siod_drv = 1'b1;
            end
        endcase
    end

    assign sioc = sioc_drv;
    assign siod = siod_drv;
    assign busy = (state != S_IDLE);
    assign done = (state == S_DONE);

endmodule
