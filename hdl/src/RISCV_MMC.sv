`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: National University of Singapore
// Engineer: Neil Banerjee
//
// Create Date: 22.02.2025 21:29:09
// Design Name: RISCV-MMC
// Module Name: RISCV_MMC
// Project Name: CS2100DE Labs
// Target Devices: Nexys 4/Nexys 4 DDR
// Tool Versions: Vivado 2023.2
// Description: The main RISC-V CPU
//
// Dependencies: Nil
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module RISCV_MMC(
    input  wire         clk,
    input  wire         rst,
    //input Interrupt,      // for optional future use.
    input  wire [31:0]  instr,
    input  wire [31:0]  mem_read_data,       // v2: Renamed to support lb/lbu/lh/lhu
    output wire         mem_read,
    output wire         mem_write,  // Delete reg for release. v2: Changed to column-wise write enable to support sb/sw. Each column is a byte.
    output wire [31:0]  PC,
    output wire [31:0]  alu_result,
    output wire [31:0]  mem_write_data  // Delete reg for release. v2: Renamed to support sb/sw
    );

	// Create all the wires/logic signals you need here

    // Extend signals
    // Inputs
    wire [31:7] extend_instr_imm;
    wire [2:0]  extend_imm_src;
    // Outputs
    wire [31:0] extend_ext_imm;

    // Decoder signals
    // Inputs
    wire [31:0] decoder_instr;
    // Outputs
    wire [1:0]  decoder_PCS;
    wire        decoder_mem_to_reg;
    wire        decoder_mem_write;
    wire [3:0]  decoder_alu_control;
    wire [1:0]  decoder_alu_src_a;
    wire [1:0]  decoder_alu_src_b;
    wire [2:0]  decoder_imm_src;
    wire        decoder_reg_write;

    // ALU signals
    // Inputs
    logic [31:0] alu_src_a;
    logic [31:0] alu_src_b;
    wire [3:0]  alu_control;
    // Outputs
    // wire [31:0] alu_result;
    wire [2:0]  alu_flags;

    // Register File signals
    // Inputs
    wire        reg_file_clk;
    wire        reg_file_we;
    wire [4:0]  reg_file_rs1;
    wire [4:0]  reg_file_rs2;
    wire [4:0]  reg_file_rd;
    wire [31:0] reg_file_WD;
    // Outputs
    wire [31:0] reg_file_RD1;
    wire [31:0] reg_file_RD2;

    // PC Logic signals
    // Inputs
    wire [1:0]  pc_logic_PCS;
    wire [2:0]  pc_logic_funct3;
    wire [2:0]  pc_logic_alu_flags;
    // Outputs
    wire [1:0]  pc_logic_PC_src;

    // Program Counter signals
    // Inputs
    wire            pc_clk;
    wire            pc_rst;
    wire [31:0]     pc_src_a;
    wire [31:0]     pc_src_b;
    wire [31:0]     pc_in;
    // Outputs
    wire [31:0]     pc;

    // Signal assignments
    // Module output signals
    assign mem_read = decoder_mem_to_reg; // This is needed for the proper functionality of some devices such as UART CONSOLE
    assign mem_write = decoder_mem_write;
    assign PC = pc;
    assign mem_write_data = reg_file_RD2;

    // Extend signals
    assign extend_instr_imm = instr[31:7];
    assign extend_imm_src = decoder_imm_src;

    // Decoder signals
    assign decoder_instr = instr;

    // ALU signals
    always_comb
    begin: aluSrcALogic
        if (decoder_alu_src_a[0])
        begin
            if (decoder_alu_src_a[1])
                alu_src_a = pc;
            else
                alu_src_a = '0;
        end
        else
            alu_src_a = reg_file_RD1;
    end

    always_comb
    begin: aluSrcBLogic
        if (decoder_alu_src_b[0])
        begin
            if (decoder_alu_src_b[1])
                alu_src_b = extend_ext_imm;
            else
                alu_src_b = 32'h4;
        end
        else
            alu_src_b = reg_file_RD2;
    end

    assign alu_control = decoder_alu_control;

    // Register File signals
    assign reg_file_clk = clk;
    assign reg_file_we = decoder_reg_write;
    assign reg_file_rs1 = instr[19:15];
    assign reg_file_rs2 = instr[24:20];
    assign reg_file_rd = instr[11:7];
    assign reg_file_WD = (decoder_mem_to_reg) ? mem_read_data : alu_result;

    // PC Logic signals
    assign pc_logic_PCS = decoder_PCS;
    assign pc_logic_funct3 = instr[14:12];
    assign pc_logic_alu_flags = alu_flags;

    // Program Counter signals
    assign pc_clk = clk;
    assign pc_rst = rst;
    assign pc_src_a = pc_logic_PC_src[0] ? extend_ext_imm : 32'h4;
    assign pc_src_b = pc_logic_PC_src[1] ? reg_file_RD1 : pc;
    assign pc_in = pc_src_a + pc_src_b;

	// Instantiate your extender module here
    Extend extender (
        .instr_imm(extend_instr_imm),
        .imm_src(extend_imm_src),
        .ext_imm(extend_ext_imm)
    );

    Decoder decoder (
        .instr(decoder_instr),
        .PCS(decoder_PCS),
        .mem_to_reg(decoder_mem_to_reg),
        .mem_write(decoder_mem_write),
        .alu_control(decoder_alu_control),
        .alu_src_a(decoder_alu_src_a),
        .alu_src_b(decoder_alu_src_b),
        .imm_src(decoder_imm_src),
        .reg_write(decoder_reg_write)
    );

    ALU alu (
        .src_a(alu_src_a),
        .src_b(alu_src_b),
        .control(alu_control),
        .result(alu_result),
        .flags(alu_flags)
    );

    RegFile reg_file (
        .clk(reg_file_clk),
        .we(reg_file_we),
        .rs1(reg_file_rs1),
        .rs2(reg_file_rs2),
        .rd(reg_file_rd),
        .WD(reg_file_WD),
        .RD1(reg_file_RD1),
        .RD2(reg_file_RD2)
    );

    PC_Logic pc_logic (
        .PCS(pc_logic_PCS),
        .funct3(pc_logic_funct3),
        .alu_flags(pc_logic_alu_flags),
        .PC_src(pc_logic_PC_src)
    );

    ProgramCounter program_counter(
        .clk(pc_clk),
        .rst(pc_rst),
        .pc_in(pc_in),
        .pc(pc)
    );

endmodule
