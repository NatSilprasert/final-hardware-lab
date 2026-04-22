// ============================================================================
// ov7670_capture.sv - OV7670 parallel-port capture (PCLK domain)
//
// OV7670 in RGB565 mode outputs 2 bytes per pixel on D[7:0]:
//   Byte 0 (first PCLK with HREF=1):  R[4:0], G[5:3]   -> D[7:0]
//   Byte 1 (second PCLK)            :  G[2:0], B[4:0]  -> D[7:0]
// Giving 16-bit pixel: {R[4:0], G[5:0], B[4:0]}
//
// We repack to 12-bit RGB444 (drop LSB) to fit our frame buffer:
//   {R[4:1], G[5:2], B[4:1]}
//
// Outputs a write-enable + address + pixel every second PCLK.  Coordinates
// reset on VSYNC (frame start).  Column counter advances on HREF high;
// row counter advances on HREF falling edge.
//
// In QVGA mode the camera itself outputs 320 columns x 240 rows so
// capture simply passes through; in VGA mode (mode_sel=1) the same
// module emits 640x480.  Downstream modules decide how to use the data.
// ============================================================================
`timescale 1ns/1ps

module ov7670_capture #(
    parameter int FB_ADDR_W = 17   // 320x240 -> 76800 pixels -> 17 bits
) (
    input  logic                    pclk,
    input  logic                    rst,          // sync to pclk
    input  logic                    vsync,
    input  logic                    href,
    input  logic [7:0]              d,

    // Pixel stream output (synchronous to pclk)
    output logic                    pix_valid,
    output logic [11:0]             pix_rgb444,
    output logic [15:0]             pix_rgb565,
    output logic [9:0]              col,          // 0..639
    output logic [9:0]              row,          // 0..479
    output logic                    frame_start,  // pulse on VSYNC rising
    output logic                    frame_end,    // pulse on VSYNC falling

    // Linear address for 320x240 frame buffer (valid when pix_valid & in-range)
    output logic [FB_ADDR_W-1:0]    fb_addr
);

    logic       byte_sel;       // 0 = expecting MSB byte, 1 = expecting LSB byte
    logic [7:0] msb_byte;
    logic       href_q, vsync_q;

    // Detect VSYNC transitions
    always_ff @(posedge pclk) begin
        if (rst) begin
            vsync_q <= 1'b0;
            href_q  <= 1'b0;
        end else begin
            vsync_q <= vsync;
            href_q  <= href;
        end
    end
    assign frame_start = (!vsync_q) &&  vsync; // rising
    assign frame_end   =  vsync_q  && !vsync;  // falling

    // Row/column counters
    always_ff @(posedge pclk) begin
        if (rst) begin
            col      <= '0;
            row      <= '0;
            byte_sel <= 1'b0;
            msb_byte <= '0;
        end else begin
            // VSYNC rising edge -> new frame
            if (frame_start) begin
                col      <= '0;
                row      <= '0;
                byte_sel <= 1'b0;
            end else begin
                if (href) begin
                    byte_sel <= ~byte_sel;
                    if (byte_sel == 1'b0) begin
                        msb_byte <= d;
                    end else begin
                        // Second byte arrived -> one complete pixel
                        if (col != 10'd1023) col <= col + 10'd1;
                    end
                end else begin
                    // HREF low: between lines
                    byte_sel <= 1'b0;
                    if (href_q && !href) begin
                        // HREF falling edge -> next row
                        row <= row + 10'd1;
                        col <= '0;
                    end
                end
            end
        end
    end

    // Pixel assembly
    logic        pix_valid_r;
    logic [15:0] rgb565_r;
    always_ff @(posedge pclk) begin
        if (rst) begin
            pix_valid_r <= 1'b0;
            rgb565_r    <= '0;
        end else begin
            pix_valid_r <= 1'b0;
            if (href && (byte_sel == 1'b1)) begin
                rgb565_r    <= {msb_byte, d};
                pix_valid_r <= 1'b1;
            end
        end
    end

    assign pix_valid  = pix_valid_r;
    assign pix_rgb565 = rgb565_r;
    // RGB565 -> RGB444: drop 1 bit of R, 2 bits of G, 1 bit of B
    assign pix_rgb444 = {rgb565_r[15:12], rgb565_r[10:7], rgb565_r[4:1]};

    // Linear frame buffer address for QVGA (320x240).  The caller gates this
    // with (col<320 && row<240) before committing the write.  We still
    // compute the address here so it's valid in-range.
    logic [31:0] linear_addr;
    assign linear_addr = row * 32'd320 + col;
    assign fb_addr     = linear_addr[FB_ADDR_W-1:0];

endmodule
