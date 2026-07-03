`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////
// File Name  : SPSR_Bank.v
// Description: Ngan hang SPSR - chi luu CPSR khi co FIQ hoac IRQ
//
// Ngo vao:
//   clk, rst          : clock va reset
//   cpsr_in  [31:0]   : gia tri CPSR hien tai can luu
//   save_fiq          : xung 1 chu ky -> luu cpsr_in vao SPSR_fiq
//   save_irq          : xung 1 chu ky -> luu cpsr_in vao SPSR_irq
//
// Ngo ra:
//   spsr_fiq_out [31:0] : noi dung SPSR_fiq hien tai
//   spsr_irq_out [31:0] : noi dung SPSR_irq hien tai
//////////////////////////////////////////////////////////////////////////

module SPSR_Regsister(
    input  wire        clk,
    input  wire        rst,

    input  wire [31:0] cpsr_in,
    input  wire        fiq_flag, // IO 7
    input  wire        irq_flag, // IO 6

    output wire [31:0] spsr_fiq_out,
    output wire [31:0] spsr_irq_out
);
    reg [31:0] spsr_fiq;
    reg [31:0] spsr_irq;

    localparam RESET_STATE = 32'h000000D3;

    wire d_fiq, d_irq;
    assign d_fiq = fiq_flag & ~irq_flag;
    assign d_irq = irq_flag & ~fiq_flag;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            spsr_fiq <= RESET_STATE;
            spsr_irq <= RESET_STATE;
        end else begin
            if (d_fiq) spsr_fiq <= cpsr_in;
            if (d_irq) spsr_irq <= cpsr_in;
        end
    end

    assign spsr_fiq_out = spsr_fiq;
    assign spsr_irq_out = spsr_irq;

endmodule