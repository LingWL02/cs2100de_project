`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: National University of Singapore
// Engineer: Neil Banerjee
//
// Module Name: Decoder_Extend_sim
// Description: Self-checking testbench for Decoder and Extend modules.
//              Covers R, I, Load, S, B, and J instruction types.
//////////////////////////////////////////////////////////////////////////////////

module Decoder_Extend_sim();

    logic [31:0]    instr;
    logic [1:0]     PCS;
    logic           mem_to_reg;
    logic           mem_write;
    logic [3:0]     alu_control;
    logic           alu_src_b;
    logic [2:0]     imm_src;
    logic           reg_write;
    logic [31:0]    ext_imm;

    int pass_count = 0;
    int fail_count = 0;

    Decoder decoder_uut (
        .instr      (instr),
        .PCS        (PCS),
        .imm_src    (imm_src),
        .mem_to_reg (mem_to_reg),
        .mem_write  (mem_write),
        .alu_control(alu_control),
        .alu_src_b  (alu_src_b),
        .reg_write  (reg_write)
    );

    Extend extender_uut (
        .instr_imm  (instr[31:7]),
        .imm_src    (imm_src),
        .ext_imm    (ext_imm)
    );

    // -----------------------------------------------------------------------
    // Self-check task: compares got vs expected, prints on failure only
    // -----------------------------------------------------------------------
    task automatic chk;
        input string      label;
        input string      sig;
        input logic [31:0] got;
        input logic [31:0] exp;
        begin
            if (got === exp)
                pass_count++;
            else begin
                $display("  FAIL [%s] %s : expected 0x%0h, got 0x%0h",
                         label, sig, exp, got);
                fail_count++;
            end
        end
    endtask

    // -----------------------------------------------------------------------
    // Test cases
    // -----------------------------------------------------------------------
    initial begin
        $display("=== Decoder + Extend Testbench ===\n");

        // ------------------------------------------------------------------
        // T1 : ADDI x20, x20, -8   (I-type, funct3=000)
        //      instr[31:20]=0xFFF, rs1=x20, funct3=000, rd=x20, op=0010011
        //      alu_control = {000, 0} = 0000   ext_imm = -8 = 0xFFFFFFF8
        // ------------------------------------------------------------------
        instr = 32'hFF8A0A13; #10;
        $display("[T1] ADDI x20, x20, -8  (instr=0x%08h)", instr);
        chk("T1", "PCS",         PCS,         2'b00);
        chk("T1", "mem_to_reg",  mem_to_reg,  1'b0);
        chk("T1", "mem_write",   mem_write,   1'b0);
        chk("T1", "alu_control", alu_control, 4'b0000);
        chk("T1", "alu_src_b",   alu_src_b,   1'b1);
        chk("T1", "imm_src",     imm_src,     3'b011);
        chk("T1", "reg_write",   reg_write,   1'b1);
        chk("T1", "ext_imm",     ext_imm,     32'hFFFFFFF8);

        // ------------------------------------------------------------------
        // T2 : ADD x1, x2, x3   (R-type, funct7=0000000, funct3=000)
        //      alu_control = {000, 0} = 0000   (no immediate)
        // ------------------------------------------------------------------
        instr = 32'h00310033; #10;
        $display("[T2] ADD x1, x2, x3     (instr=0x%08h)", instr);
        chk("T2", "PCS",         PCS,         2'b00);
        chk("T2", "mem_to_reg",  mem_to_reg,  1'b0);
        chk("T2", "mem_write",   mem_write,   1'b0);
        chk("T2", "alu_control", alu_control, 4'b0000);
        chk("T2", "alu_src_b",   alu_src_b,   1'b0);
        chk("T2", "reg_write",   reg_write,   1'b1);

        // ------------------------------------------------------------------
        // T3 : SUB x1, x2, x3   (R-type, funct7=0100000, funct3=000)
        //      alu_control = {000, funct7[5]=1} = 0001
        // ------------------------------------------------------------------
        instr = 32'h40310033; #10;
        $display("[T3] SUB x1, x2, x3     (instr=0x%08h)", instr);
        chk("T3", "PCS",         PCS,         2'b00);
        chk("T3", "mem_to_reg",  mem_to_reg,  1'b0);
        chk("T3", "mem_write",   mem_write,   1'b0);
        chk("T3", "alu_control", alu_control, 4'b0001);
        chk("T3", "alu_src_b",   alu_src_b,   1'b0);
        chk("T3", "reg_write",   reg_write,   1'b1);

        // ------------------------------------------------------------------
        // T4 : LW x5, 12(x6)   (Load, funct3=010)
        //      mem_to_reg=1   ext_imm = 12 = 0x0000000C
        // ------------------------------------------------------------------
        instr = 32'h00C32283; #10;
        $display("[T4] LW x5, 12(x6)      (instr=0x%08h)", instr);
        chk("T4", "PCS",         PCS,         2'b00);
        chk("T4", "mem_to_reg",  mem_to_reg,  1'b1);
        chk("T4", "mem_write",   mem_write,   1'b0);
        chk("T4", "alu_control", alu_control, 4'b0000);
        chk("T4", "alu_src_b",   alu_src_b,   1'b1);
        chk("T4", "imm_src",     imm_src,     3'b011);
        chk("T4", "reg_write",   reg_write,   1'b1);
        chk("T4", "ext_imm",     ext_imm,     32'h0000000C);

        // ------------------------------------------------------------------
        // T5 : SW x5, 8(x6)   (S-type, funct3=010)
        //      mem_write=1   imm_src=110   ext_imm = 8 = 0x00000008
        // ------------------------------------------------------------------
        instr = 32'h00532423; #10;
        $display("[T5] SW x5, 8(x6)       (instr=0x%08h)", instr);
        chk("T5", "PCS",         PCS,         2'b00);
        chk("T5", "mem_write",   mem_write,   1'b1);
        chk("T5", "alu_control", alu_control, 4'b0000);
        chk("T5", "alu_src_b",   alu_src_b,   1'b1);
        chk("T5", "imm_src",     imm_src,     3'b110);
        chk("T5", "reg_write",   reg_write,   1'b0);
        chk("T5", "ext_imm",     ext_imm,     32'h00000008);

        // ------------------------------------------------------------------
        // T6 : BEQ x1, x2, +4   (B-type, funct3=000)
        //      PCS=01  alu_control=0001  imm_src=111  ext_imm = 4
        // ------------------------------------------------------------------
        instr = 32'h00208263; #10;
        $display("[T6] BEQ x1, x2, +4     (instr=0x%08h)", instr);
        chk("T6", "PCS",         PCS,         2'b01);
        chk("T6", "mem_write",   mem_write,   1'b0);
        chk("T6", "alu_control", alu_control, 4'b0001);
        chk("T6", "alu_src_b",   alu_src_b,   1'b0);
        chk("T6", "imm_src",     imm_src,     3'b111);
        chk("T6", "reg_write",   reg_write,   1'b0);
        chk("T6", "ext_imm",     ext_imm,     32'h00000004);

        // ------------------------------------------------------------------
        // T7 : JAL x1, +8   (J-type)
        //      PCS=10  imm_src=010  ext_imm = 8 = 0x00000008
        // ------------------------------------------------------------------
        instr = 32'h008000EF; #10;
        $display("[T7] JAL x1, +8         (instr=0x%08h)", instr);
        chk("T7", "PCS",       PCS,       2'b10);
        chk("T7", "mem_write", mem_write, 1'b0);
        chk("T7", "imm_src",   imm_src,   3'b010);
        chk("T7", "reg_write", reg_write, 1'b0);
        chk("T7", "ext_imm",   ext_imm,   32'h00000008);

        // ------------------------------------------------------------------
        // T8 : SLTI x3, x4, 5   (I-type, funct3=010)
        //      alu_control = {010, 0} = 0100   ext_imm = 5
        // ------------------------------------------------------------------
        instr = 32'h00522193; #10;
        $display("[T8] SLTI x3, x4, 5     (instr=0x%08h)", instr);
        chk("T8", "PCS",         PCS,         2'b00);
        chk("T8", "mem_to_reg",  mem_to_reg,  1'b0);
        chk("T8", "mem_write",   mem_write,   1'b0);
        chk("T8", "alu_control", alu_control, 4'b0100);
        chk("T8", "alu_src_b",   alu_src_b,   1'b1);
        chk("T8", "imm_src",     imm_src,     3'b011);
        chk("T8", "reg_write",   reg_write,   1'b1);
        chk("T8", "ext_imm",     ext_imm,     32'h00000005);

        // ------------------------------------------------------------------
        // T9 : SRAI x3, x3, 2   (I-type shift, funct3=101, funct7[5]=1)
        //      alu_control = {101, funct7[5]=1} = 1011
        //      ext_imm = sign_extend(0x402) = 0x00000402
        // ------------------------------------------------------------------
        instr = 32'h4021D193; #10;
        $display("[T9] SRAI x3, x3, 2     (instr=0x%08h)", instr);
        chk("T9", "PCS",         PCS,         2'b00);
        chk("T9", "mem_to_reg",  mem_to_reg,  1'b0);
        chk("T9", "mem_write",   mem_write,   1'b0);
        chk("T9", "alu_control", alu_control, 4'b1011);
        chk("T9", "alu_src_b",   alu_src_b,   1'b1);
        chk("T9", "imm_src",     imm_src,     3'b011);
        chk("T9", "reg_write",   reg_write,   1'b1);
        chk("T9", "ext_imm",     ext_imm,     32'h00000402);

        // ------------------------------------------------------------------
        // Summary
        // ------------------------------------------------------------------
        $display("\n=== Results: %0d passed, %0d failed ===",
                 pass_count, fail_count);
        if (fail_count == 0)
            $display("ALL TESTS PASSED!");

        $finish;
    end

endmodule