`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////
// File Name : Top_ALU_CPSR.v
// Description: Top-level noi ALU_ARM va CPSR_Regsister
//
// So do ket noi:
//   A, B, ALUOp --------> ALU_ARM
//   ALU.{N,Z,C,V} ------> CPSR.alu_flags_in
//   ALU.update_flags ---> CPSR.alu_update_en
//   CPSR.cpsr_out[29] --> ALU.Cin  (feedback carry)
//   msr_* --------------> CPSR truc tiep
//////////////////////////////////////////////////////////////////////////

module Top_ALU_CPSR (
    input  wire        clk,
    input  wire        rst,
    // Ngo vao ALU
    input  wire [31:0] A,
    input  wire [31:0] B,
    input  wire [3:0]  OpCode,
    // Ngo vao MSR
    input  wire [31:0] msr_data_in,
    input  wire        msr_wire_f_en,
    input  wire        msr_wire_c_en,
    input  wire        irq_req,
    input  wire        fiq_req,
    // Ngo ra
    output wire [31:0] Result,
    output wire [31:0] cpsr_out,
    output wire [31:0] save_cpsr_irq,
    output wire [31:0] save_cpsr_fiq,
    output wire        N, Z, C, V
);

    // Day noi noi bo
    wire       alu_N, alu_Z, alu_C, alu_V;
    wire       alu_update_flags;
    wire       cin_from_cpsr;

    // Lay Cin tu CPSR[29] (co C hien tai)
    assign cin_from_cpsr = cpsr_out[29];

    // --- Khoi ALU ---
    ALU u_alu (
        .A           (A),
        .B           (B),
        .Op_code       (OpCode),
        .Cin         (cin_from_cpsr),
        .Result      (Result),
        .N           (alu_N),
        .Z           (alu_Z),
        .C           (alu_C),
        .V           (alu_V),
        .alu_update_en(alu_update_flags)
    );

    // --- Khoi CPSR ---
    CPSR_Regsister u_cpsr (
        .clk          (clk),
        .rst          (rst),
        .alu_flags_in ({alu_N, alu_Z, alu_C, alu_V}),
        .alu_update_en(alu_update_flags),
        .msr_data_in  (msr_data_in),
        .msr_wire_f_en(msr_wire_f_en),
        .msr_wire_c_en(msr_wire_c_en),
        .cpsr_out     (cpsr_out),
        .N(N), .Z(Z), .C(C), .V(V)
    );

    wire I, F;

    assign I = irq_req;
    assign F = fiq_req;

    SPSR_Regsister u_spsr (
        .clk (clk),
        .rst (rst),
        .cpsr_in(cpsr_out),
        .fiq_flag(F),
        .irq_flag(I),
        .spsr_fiq_out(save_cpsr_fiq),
        .spsr_irq_out(save_cpsr_irq)
    );

endmodule