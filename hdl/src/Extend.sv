`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: National University of Singapore
// Engineer: Neil Banerjee
//
// Create Date: 05.03.2025 23:43:42
// Design Name: RISCV-MMC
// Module Name: Extend
// Project Name: CS2100DE Labs
// Target Devices: Nexys 4/Nexys 4 DDR
// Tool Versions: Vivado 2023.2
// Description: Module for extending immediates
//
// Dependencies: Nil
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module Extend(
    input  wire [31:7] instr_imm,
    input  wire [2:0]  imm_src,
    output reg  [31:0] ext_imm
    );

    always_comb begin
        case (imm_src)
            3'b011:
            begin // I
                ext_imm = {{20{instr_imm[31]}}, instr_imm[31:20]};
            end
            3'b110:
            begin // S
                ext_imm = {{20{instr_imm[31]}}, instr_imm[31:25], instr_imm[11:7]};
            end
            3'b111:
            begin // B
                ext_imm = {{20{instr_imm[31]}}, instr_imm[7], instr_imm[30:25], instr_imm[11:8], 1'b0};
            end
            3'b000:
            begin // U
                ext_imm = {instr_imm[31:12], 12'b0};
            end
            3'b010:
            begin // J/UJ
                ext_imm = {{12{instr_imm[31]}}, instr_imm[19:12], instr_imm[20], instr_imm[30:21], 1'b0};
            end
            default:
            begin
                ext_imm = 32'b0;
            end
        endcase
    end
endmodule
