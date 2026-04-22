// ============================================================================
// sccb_rom.sv - Static OV7670 register table for two resolutions
//
// Two configuration sets selectable via mode_sel:
//   0 : QVGA (320x240) RGB565 with scaler (~30 fps)
//   1 : VGA  (640x480) RGB565 (stream-through mode)
//
// The table is read serially from index 0.  A value of {0xFF,0xFF} means END.
// A value of sub=0xFF data!=0xFF is a "delay N ms" marker (not a register).
// ============================================================================
`timescale 1ns/1ps

module sccb_rom (
    input  logic       mode_sel,   // 0 = QVGA, 1 = VGA
    input  logic [7:0] index,
    output logic [7:0] sub_addr,
    output logic [7:0] data,
    output logic       is_end,
    output logic       is_delay
);

    logic [15:0] entry_q, entry_v;
    logic [15:0] entry;

    // ---- QVGA RGB565 table ----
    always_comb begin
        unique case (index)
            //               {sub_addr, data}
            8'd0  : entry_q = 16'h12_80;   // COM7 reset all
            8'd1  : entry_q = 16'hFF_01;   // delay 1 ms (marker)
            8'd2  : entry_q = 16'h12_14;   // COM7 QVGA + RGB
            8'd3  : entry_q = 16'h11_80;   // CLKRC use internal clock
            8'd4  : entry_q = 16'h0C_04;   // COM3 enable scale
            8'd5  : entry_q = 16'h3E_19;   // COM14 divide PCLK
            8'd6  : entry_q = 16'h40_D0;   // COM15 RGB565, full output range
            8'd7  : entry_q = 16'h3A_04;   // TSLB set UV order
            8'd8  : entry_q = 16'h8C_00;   // RGB444 disable (use 565)
            // Scaling (QVGA sub-sampling)
            8'd9  : entry_q = 16'h70_3A;
            8'd10 : entry_q = 16'h71_35;
            8'd11 : entry_q = 16'h72_11;
            8'd12 : entry_q = 16'h73_F1;
            8'd13 : entry_q = 16'hA2_02;
            // Window
            8'd14 : entry_q = 16'h17_16;   // HSTART
            8'd15 : entry_q = 16'h18_04;   // HSTOP
            8'd16 : entry_q = 16'h32_80;   // HREF
            8'd17 : entry_q = 16'h19_03;   // VSTART
            8'd18 : entry_q = 16'h1A_7B;   // VSTOP
            8'd19 : entry_q = 16'h03_0A;   // VREF
            // Exposure / gain / AWB defaults
            8'd20 : entry_q = 16'h13_E7;   // COM8 enable AGC/AWB/AEC
            8'd21 : entry_q = 16'h14_38;   // COM9 max AGC
            8'd22 : entry_q = 16'h41_08;   // COM16 AWB gain enable
            8'd23 : entry_q = 16'h42_00;   // COM17 test pattern off
            // Gamma curve (minimal)
            8'd24 : entry_q = 16'h7A_20;
            8'd25 : entry_q = 16'h7B_10;
            8'd26 : entry_q = 16'h7C_1E;
            8'd27 : entry_q = 16'h7D_35;
            8'd28 : entry_q = 16'h7E_5A;
            8'd29 : entry_q = 16'h7F_69;
            8'd30 : entry_q = 16'h80_76;
            8'd31 : entry_q = 16'h81_80;
            8'd32 : entry_q = 16'h82_88;
            8'd33 : entry_q = 16'h83_8F;
            8'd34 : entry_q = 16'h84_96;
            8'd35 : entry_q = 16'h85_A3;
            8'd36 : entry_q = 16'h86_AF;
            8'd37 : entry_q = 16'h87_C4;
            8'd38 : entry_q = 16'h88_D7;
            8'd39 : entry_q = 16'h89_E8;
            default: entry_q = 16'hFF_FF;   // END sentinel
        endcase
    end

    // ---- VGA RGB565 table ----
    always_comb begin
        unique case (index)
            8'd0  : entry_v = 16'h12_80;   // COM7 reset
            8'd1  : entry_v = 16'hFF_01;   // delay 1 ms
            8'd2  : entry_v = 16'h12_04;   // COM7 VGA + RGB
            8'd3  : entry_v = 16'h11_80;   // CLKRC internal
            8'd4  : entry_v = 16'h0C_00;   // COM3 no scale
            8'd5  : entry_v = 16'h3E_00;   // COM14 PCLK not divided
            8'd6  : entry_v = 16'h40_D0;   // COM15 RGB565
            8'd7  : entry_v = 16'h3A_04;
            8'd8  : entry_v = 16'h8C_00;
            8'd9  : entry_v = 16'h17_13;   // HSTART (VGA)
            8'd10 : entry_v = 16'h18_01;   // HSTOP
            8'd11 : entry_v = 16'h32_B6;
            8'd12 : entry_v = 16'h19_02;   // VSTART
            8'd13 : entry_v = 16'h1A_7A;   // VSTOP
            8'd14 : entry_v = 16'h03_0A;
            8'd15 : entry_v = 16'h13_E7;
            8'd16 : entry_v = 16'h14_38;
            8'd17 : entry_v = 16'h41_08;
            8'd18 : entry_v = 16'h42_00;
            // Share gamma
            8'd19 : entry_v = 16'h7A_20;
            8'd20 : entry_v = 16'h7B_10;
            8'd21 : entry_v = 16'h7C_1E;
            8'd22 : entry_v = 16'h7D_35;
            8'd23 : entry_v = 16'h7E_5A;
            8'd24 : entry_v = 16'h7F_69;
            8'd25 : entry_v = 16'h80_76;
            8'd26 : entry_v = 16'h81_80;
            8'd27 : entry_v = 16'h82_88;
            8'd28 : entry_v = 16'h83_8F;
            8'd29 : entry_v = 16'h84_96;
            8'd30 : entry_v = 16'h85_A3;
            8'd31 : entry_v = 16'h86_AF;
            8'd32 : entry_v = 16'h87_C4;
            8'd33 : entry_v = 16'h88_D7;
            8'd34 : entry_v = 16'h89_E8;
            default: entry_v = 16'hFF_FF;
        endcase
    end

    assign entry    = mode_sel ? entry_v : entry_q;
    assign sub_addr = entry[15:8];
    assign data     = entry[7:0];
    assign is_end   = (sub_addr == 8'hFF) && (data == 8'hFF);
    assign is_delay = (sub_addr == 8'hFF) && (data != 8'hFF);

endmodule
