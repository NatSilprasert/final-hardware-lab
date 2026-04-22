// ============================================================================
// frame_buffer.sv - 320 x 240 x 12-bit RGB444 asynchronous dual-port frame
// buffer, implemented with the Xilinx Parameterized Macro xpm_memory_sdpram.
//
// Why XPM instead of raw SystemVerilog inference?
//   A pure-RTL "simple dual-port" template can be mis-inferred by Vivado as
//   true dual-port with an output register, which doubles BRAM usage because
//   the 76,800-deep x 12-bit shape does not map cleanly to any native
//   RAMB36/RAMB18 geometry.  xpm_memory_sdpram lets us ask *explicitly* for
//   Simple Dual-Port with independent clocks, matching what the reference
//   design achieves via a blk_mem_gen IP core.
//
//   Size : 76,800 words x 12 bits = 921,600 bits ~= 25 RAMB36 (AMOUNT_WASTED
//          tiles are negligible because 76,800 close to 2 * RAMB36 cap).
//
// The top-level writes the camera pixel in RGB444 on PCLK and the VGA reader
// reads it on clk_vga.  Both clocks are declared asynchronous in the XDC
// (set_clock_groups -asynchronous), so the macro handles CDC internally.
// ============================================================================
`timescale 1ns/1ps

module frame_buffer #(
    parameter int DATA_W    = 12,
    parameter int DEPTH     = 320*240,
    parameter int ADDR_W    = $clog2(320*240)   // 17
) (
    // Write port (camera)
    input  logic              clk_wr,
    input  logic              we,
    input  logic [ADDR_W-1:0] addr_wr,
    input  logic [DATA_W-1:0] din,

    // Read port (VGA)
    input  logic              clk_rd,
    input  logic [ADDR_W-1:0] addr_rd,
    output logic [DATA_W-1:0] dout
);

    // xpm_memory_sdpram: Simple Dual-Port RAM
    //   - Independent read/write clocks
    //   - No output register on read port (READ_LATENCY_B = 1)
    //   - Common clocking disabled (CLOCKING_MODE = "independent_clock")
    //
    // Reference: UG953 (xpm_memory), Vivado 2019.1+ supports it natively.
    xpm_memory_sdpram #(
        .MEMORY_SIZE             (DEPTH * DATA_W),   // total bits
        .MEMORY_PRIMITIVE        ("block"),
        .CLOCKING_MODE           ("independent_clock"),
        .MEMORY_INIT_FILE        ("none"),
        .MEMORY_INIT_PARAM       ("0"),
        .USE_MEM_INIT            (1),
        .WAKEUP_TIME             ("disable_sleep"),
        .MESSAGE_CONTROL         (0),
        .ECC_MODE                ("no_ecc"),
        .AUTO_SLEEP_TIME         (0),

        // Write port A
        .WRITE_DATA_WIDTH_A      (DATA_W),
        .BYTE_WRITE_WIDTH_A      (DATA_W),
        .ADDR_WIDTH_A            (ADDR_W),

        // Read port B
        .READ_DATA_WIDTH_B       (DATA_W),
        .ADDR_WIDTH_B            (ADDR_W),
        .READ_RESET_VALUE_B      ("0"),
        .READ_LATENCY_B          (1),
        .WRITE_MODE_B            ("no_change"),

        .RST_MODE_A              ("SYNC"),
        .RST_MODE_B              ("SYNC")
    ) u_bram (
        // Write port
        .clka   (clk_wr),
        .ena    (we),
        .wea    (we),
        .addra  (addr_wr),
        .dina   (din),

        // Read port
        .clkb   (clk_rd),
        .enb    (1'b1),
        .rstb   (1'b0),
        .regceb (1'b1),
        .addrb  (addr_rd),
        .doutb  (dout),

        // Unused (tie off)
        .injectdbiterra (1'b0),
        .injectsbiterra (1'b0),
        .sleep          (1'b0),
        .dbiterrb       (),
        .sbiterrb       ()
    );

endmodule
