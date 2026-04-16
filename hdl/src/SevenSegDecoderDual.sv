`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 02.04.2025 19:02:15
// Design Name:
// Module Name: SevenSegDecoder
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module SevenSegDecoderDual(
  input  wire        clk,
  input  wire [31:0] cfg_word,
  input  wire [31:0] data_word0,
  input  wire [31:0] data_word1,
  output logic [6:0] seg,
  output logic [7:0] an
  );

  localparam integer CFG_ASCII_MODE_BIT = 0;

  logic [12:0] refresh_counter;
  logic [2:0]  digit_sel;

  logic [3:0]  nibble_to_display;
  logic [7:0]  ascii_to_display;
  logic        ascii_mode;

  function automatic [6:0] hex_to_seg(input [3:0] nibble);
    case (nibble)
      4'h0: hex_to_seg = 7'b1000000;
      4'h1: hex_to_seg = 7'b1111001;
      4'h2: hex_to_seg = 7'b0100100;
      4'h3: hex_to_seg = 7'b0110000;
      4'h4: hex_to_seg = 7'b0011001;
      4'h5: hex_to_seg = 7'b0010010;
      4'h6: hex_to_seg = 7'b0000010;
      4'h7: hex_to_seg = 7'b1111000;
      4'h8: hex_to_seg = 7'b0000000;
      4'h9: hex_to_seg = 7'b0010000;
      4'hA: hex_to_seg = 7'b0001000;
      4'hB: hex_to_seg = 7'b0000011;
      4'hC: hex_to_seg = 7'b1000110;
      4'hD: hex_to_seg = 7'b0100001;
      4'hE: hex_to_seg = 7'b0000110;
      4'hF: hex_to_seg = 7'b0001110;
      default: hex_to_seg = 7'b1111111;
    endcase
  endfunction

  function automatic [6:0] ascii_to_seg_fn(input [7:0] ch);
    case (ch)
      8'h20: ascii_to_seg_fn = 7'b1111111; // space
      8'h2D: ascii_to_seg_fn = 7'b0111111; // -
      8'h30: ascii_to_seg_fn = 7'b1000000; // 0
      8'h31: ascii_to_seg_fn = 7'b1111001; // 1
      8'h32: ascii_to_seg_fn = 7'b0100100; // 2
      8'h33: ascii_to_seg_fn = 7'b0110000; // 3
      8'h34: ascii_to_seg_fn = 7'b0011001; // 4
      8'h35: ascii_to_seg_fn = 7'b0010010; // 5
      8'h36: ascii_to_seg_fn = 7'b0000010; // 6
      8'h37: ascii_to_seg_fn = 7'b1111000; // 7
      8'h38: ascii_to_seg_fn = 7'b0000000; // 8
      8'h39: ascii_to_seg_fn = 7'b0010000; // 9
      8'h41, 8'h61: ascii_to_seg_fn = 7'b0001000; // A/a
      8'h42, 8'h62: ascii_to_seg_fn = 7'b0000011; // B/b
      8'h43, 8'h63: ascii_to_seg_fn = 7'b1000110; // C/c
      8'h44, 8'h64: ascii_to_seg_fn = 7'b0100001; // D/d
      8'h45, 8'h65: ascii_to_seg_fn = 7'b0000110; // E/e
      8'h46, 8'h66: ascii_to_seg_fn = 7'b0001110; // F/f
      8'h47, 8'h67: ascii_to_seg_fn = 7'b1000010; // G/g
      8'h48, 8'h68: ascii_to_seg_fn = 7'b0001001; // H/h
      8'h49, 8'h69: ascii_to_seg_fn = 7'b1111001; // I/i
      8'h4A, 8'h6A: ascii_to_seg_fn = 7'b1100001; // J/j
      8'h4B, 8'h6B: ascii_to_seg_fn = 7'b0001010; // K/k
      8'h4C, 8'h6C: ascii_to_seg_fn = 7'b1000111; // L/l
      8'h4D, 8'h6D: ascii_to_seg_fn = 7'b0101010; // M/m
      8'h4E, 8'h6E: ascii_to_seg_fn = 7'b0101011; // N/n
      8'h4F, 8'h6F: ascii_to_seg_fn = 7'b1000000; // O/o
      8'h50, 8'h70: ascii_to_seg_fn = 7'b0001100; // P/p
      8'h51, 8'h71: ascii_to_seg_fn = 7'b0011000; // Q/q
      8'h52, 8'h72: ascii_to_seg_fn = 7'b0101111; // R/r
      8'h53, 8'h73: ascii_to_seg_fn = 7'b0010010; // S/s
      8'h54, 8'h74: ascii_to_seg_fn = 7'b0000111; // T/t
      8'h55, 8'h75: ascii_to_seg_fn = 7'b1000001; // U/u
      8'h56, 8'h76: ascii_to_seg_fn = 7'b1100011; // V/v
      8'h57, 8'h77: ascii_to_seg_fn = 7'b1010101; // W/w
      8'h58, 8'h78: ascii_to_seg_fn = 7'b0001001; // X/x
      8'h59, 8'h79: ascii_to_seg_fn = 7'b0010001; // Y/y
      8'h5A, 8'h7A: ascii_to_seg_fn = 7'b0100100; // Z/z
      default: ascii_to_seg_fn = 7'b1111111; // unsupported chars are blank
    endcase
  endfunction

  initial begin
    refresh_counter <= 13'b0;
    digit_sel <= 3'b0;
  end

  always_ff @(posedge clk) begin
    refresh_counter <= refresh_counter + 13'b1;
    if (refresh_counter == 13'b0) begin
      digit_sel <= digit_sel + 3'b1;
    end
  end

  always_comb begin
    ascii_mode = cfg_word[CFG_ASCII_MODE_BIT];
    nibble_to_display = 4'h0;
    ascii_to_display = 8'h20;

    case (digit_sel)
      3'b000: begin
        an = ~8'h80;
        nibble_to_display = data_word0[31:28];
        ascii_to_display = data_word0[31:24];
      end
      3'b001: begin
        an = ~8'h40;
        nibble_to_display = data_word0[27:24];
        ascii_to_display = data_word0[23:16];
      end
      3'b010: begin
        an = ~8'h20;
        nibble_to_display = data_word0[23:20];
        ascii_to_display = data_word0[15:8];
      end
      3'b011: begin
        an = ~8'h10;
        nibble_to_display = data_word0[19:16];
        ascii_to_display = data_word0[7:0];
      end
      3'b100: begin
        an = ~8'h08;
        nibble_to_display = data_word0[15:12];
        ascii_to_display = data_word1[31:24];
      end
      3'b101: begin
        an = ~8'h04;
        nibble_to_display = data_word0[11:8];
        ascii_to_display = data_word1[23:16];
      end
      3'b110: begin
        an = ~8'h02;
        nibble_to_display = data_word0[7:4];
        ascii_to_display = data_word1[15:8];
      end
      3'b111: begin
        an = ~8'h01;
        nibble_to_display = data_word0[3:0];
        ascii_to_display = data_word1[7:0];
      end
      default: begin
        an = 8'hFF;
        nibble_to_display = 4'h0;
        ascii_to_display = 8'h20;
      end
    endcase

    seg = ascii_mode ? ascii_to_seg_fn(ascii_to_display) : hex_to_seg(nibble_to_display);
  end

endmodule
