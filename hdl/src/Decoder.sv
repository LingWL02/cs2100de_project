`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: National University of Singapore
// Engineer: Neil Banerjee
//
// Create Date: 22.02.2025 20:37:13
// Design Name: RISCV-MMC
// Module Name: Decoder
// Project Name: CS2100DE Labs
// Target Devices: Nexys 4/Nexys 4 DDR
// Tool Versions: Vivado 2023.2
// Description: Instruction decoder and Control Unit for the RISC-V CPU we are building
//
// Dependencies: Nil
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module Decoder(
    input  wire [31:0]  instr,
    output reg  [1:0]   PCS,
    output reg          mem_to_reg,
    output reg          mem_write,
    output reg  [3:0]   alu_control,
    output reg  [1:0]   alu_src_a,
    output reg  [1:0]   alu_src_b,
    output reg  [2:0]   imm_src,
    output reg          reg_write
    );
    parameter [6:0] OP_R = 7'b0110011;
    parameter [6:0] OP_I = 7'b0010011;
    parameter [6:0] OP_S = 7'b0100011;
    parameter [6:0] OP_B = 7'b1100011;

    parameter [6:0] OP_L    = 7'b0000011;
    parameter [6:0] OP_JAL  = 7'b1101111;
    parameter [6:0] OP_JALR = 7'b1100111;
    parameter [6:0] OP_LUI  = 7'b0110111;
    parameter [6:0] OP_AUIPC= 7'b0010111;

    wire [6:0] opcode;
    wire [2:0] funct3;
    wire [6:0] funct7;

    assign opcode = instr[6:0];
    assign funct3 = instr[14:12];
    assign funct7 = instr[31:25];

    always_comb begin
        PCS         = 2'b00;
        mem_to_reg  = 1'b0;
        mem_write   = 1'b0;
        alu_control = 4'b0;
        alu_src_a   = 2'b00;
        alu_src_b   = 2'b00;
        imm_src     = 3'b0;
        reg_write   = 1'b0;

        case (opcode)
            OP_R:
            begin
                PCS         = 2'b00;
                mem_to_reg  = 1'b0;
                mem_write   = 1'b0;
                alu_control = {funct7[5], funct3};
                alu_src_a   = 2'b00;
                alu_src_b   = 2'b00;
                reg_write   = 1'b1;
            end
            OP_I:
            begin
                PCS         = 2'b00;
                mem_to_reg  = 1'b0;
                mem_write   = 1'b0;
                alu_control = {((funct3 == 3'h5) ? funct7[5] : 1'b0), funct3};
                alu_src_a   = 2'b00;
                alu_src_b   = 2'b11;
                imm_src     = 3'b011;
                reg_write   = 1'b1;
            end
            OP_L:
            begin
                PCS         = 2'b00;
                mem_to_reg  = 1'b1;
                mem_write   = 1'b0;
                alu_control = 4'b0;
                alu_src_a   = 2'b00;
                alu_src_b   = 2'b11;
                imm_src     = 3'b011;
                reg_write   = 1'b1;
            end
            OP_S:
            begin
                PCS         = 2'b00;
                mem_write   = 1'b1;
                alu_control = 4'b0;
                alu_src_a   = 2'b00;
                alu_src_b   = 2'b11;
                imm_src     = 3'b110;
                reg_write   = 1'b0;
            end
            OP_B:
            begin
                PCS         = 2'b01;
                mem_write   = 1'b0;
                alu_control = 4'b0001;
                alu_src_a   = 2'b00;
                alu_src_b   = 2'b00;
                imm_src     = 3'b111;
                reg_write   = 1'b0;
            end
            OP_JAL:
            begin
                PCS         = 2'b10;
                mem_to_reg  = 1'b0;
                mem_write   = 1'b0;
                alu_control = 4'b0000;
                alu_src_a   = 2'b11;
                alu_src_b   = 2'b01;  // PC + 4
                imm_src     = 3'b010;
                reg_write   = 1'b1;
            end
            OP_AUIPC:
            begin
                PCS         = 2'b00;
                mem_to_reg  = 1'b0;
                reg_write   = 1'b1;
                mem_write   = 1'b0;
                alu_src_a   = 2'b11;
                alu_src_b   = 2'b11;
                imm_src     = 3'b000;
                alu_control = 4'b0000;
            end
            OP_LUI:
            begin
                PCS         = 2'b00;
                mem_to_reg  = 1'b0;
                reg_write   = 1'b1;
                mem_write   = 1'b0;
                alu_src_a   = 2'b01;
                alu_src_b   = 2'b11;
                imm_src     = 3'b000;
                alu_control = 4'b0000;
            end
            OP_JALR:
            begin
                PCS         = 2'b11;
                mem_to_reg  = 1'b0;
                mem_write   = 1'b0;
                alu_control = 4'b0000;
                alu_src_a   = 2'b11;
                alu_src_b   = 2'b01;
                imm_src     = 3'b011;
                reg_write   = 1'b1;
            end
        endcase
    end

endmodule
