`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////
// File Name : ALU_ARM.v
// Description: Khoi ALU cua kien truc ARM 32-bit
// Ho tro day du 16 phep tinh:
//   Nhom so hoc : add, sub, rsb, mul, adc, sbc
//   Nhom kiem tra: tst, teq, cmp, cmn  (chi cap nhat co, khong ghi Rd)
//   Nhom logic  : and, or, xor, bic
//   Nhom move   : mov, mvn

//
// Ngo vao:
//   A       [31:0] — Toan hang thu nhat (noi dung thanh ghi Rn)
//   B       [31:0] — Toan hang thu hai  (noi dung thanh ghi Rm hoac immediate)
//   ALUOp   [3:0]  — Ma lenh ALU (tuong ung voi truong opcode cua ARM)
//   Cin            — Carry-in tu CPSR (dung cho ADC, SBC, RSC)
//
// Ngo ra:
//   Result  [31:0] — Ket qua 32 bit (ghi vao thanh ghi Rd)
//   N              — Negative: Result[31]
//   Z              — Zero    : Result == 0
//   C              — Carry   : tran so khong dau
//   V              — Overflow: tran so co dau
//   update_flags   — 1 neu lenh co hau to S (TST/TEQ/CMP/CMN luon = 1)
//////////////////////////////////////////////////////////////////////////

module ALU(
    input wire [31: 0] A, // toan hang 1 Rn
    input wire [31: 0] B, // toan hang 2 Rm / imm
    input wire [3:  0] Op_code,
    input wire         Cin,

    
    output reg [31:0] Result,
    output wire N,Z,
    output reg  C,V,
    output reg alu_update_en
);

localparam [3:  0] 
//---------- Khoi toan hoc -----------//
            Op_Add = 4'b0000,   // Rd = A + B
            Op_Sub = 4'b0001,   // Rd = A - B
            Op_RSB = 4'b0010,   // Rd = B - A
            Op_MUL = 4'b0011,   // Rd = A * B
            Op_ADC = 4'b0100,   // Rd = A + B + Cin
            Op_SBC = 4'b0101,   // Rd = A - B - !Cin

//---------- Khoi Logic --------------//

            Op_And = 4'b0110,   // Rd = A&B
            Op_Or  = 4'b0111,   // Rd = A | B
            Op_Xor = 4'b1000,   // Rd = A^B
            Op_Bic = 4'b1001,   // Rd = A & ~B

//---------- Khoi Move ---------------//

            Op_Mov = 4'b1010,   // Rd = B
            Op_Mvn = 4'b1011,   // Rd = ~B

//---------- Khoi kiem tra co khong ghi vao Rd ----------//

            Op_Tst = 4'b1100,   // Chi co: A & B  (khong ghi Rd)
            Op_Teq = 4'b1101,   // Chi co: A ^ B  (khong ghi Rd)
            Op_Cmp = 4'b1110,   // Chi co: A - B  (khong ghi Rd)
            Op_Cmn = 4'b1111;   // Chi co: A + B  (khong ghi Rd)

//------------------------------------------------------------
// Ket qua ngo ra se ghi vao Rd
// Ket qua ngo ra la 33bit co them 1 bit carry o bit thu 32
//------------------------------------------------------------

    wire [32:0] add_result;   // A + B (33 bit)
    wire [32:0] sub_result;   // A - B = A + ~B + 1
    wire [32:0] adc_result;   // A + B + Cin
    wire [32:0] mul_result;   // A * B
    wire [32:0] sbc_result;   // A - B - !Cin = A + ~B + Cin
    wire [32:0] rsb_result;   // B - A = B + ~ A  + 1

    wire [32:0] cmn_result;   // A + B (cho CMN)
    wire [32:0] cmp_result;   // A - B (cho CMP)

    assign add_result = {1'b0, A} + {1'b0, B};
    assign sub_result = {1'b0, A} + {1'b0, ~B} + 1'b1;
    assign adc_result = {1'b0, A} + {1'b0, B} + {32'b0, Cin};
    assign add_result = {1'b0, A} + {1'b0, B};
    assign mul_result = {1'b0, A} * {1'b0, B};
    assign sbc_result = {1'b0, A} + {1'b0, ~B} + {32'b0, Cin};
    assign rsb_result = {1'b0, B} + {1'b0, ~A} + {32'b0, Cin};
    assign cmn_result = {1'b0, A} + {1'b0, B};
    assign cmp_result = {1'b0, A} + {1'b0, ~B} + 33'd1;

//---------------------------------------------------------------
// Khoi ALU
//---------------------------------------------------------------

    always @(*)
        case(Op_code)
            Op_Add: begin
                Result       = add_result[31:0];
                C            = add_result[32];
                V            = (A[31] == B[31] && add_result[31] != A[31]) ? 1 : 0;
                alu_update_en = 1'b1;
            end

            Op_Sub: begin
                Result       = sub_result[31:0];
                C            = sub_result[32];
                V            = (A[31] == B[31] && sub_result[31] != A[31]) ? 1 : 0;
                alu_update_en =1'b1;
            end

            Op_RSB: begin
                Result       = rsb_result[31:0];
                C            = rsb_result[32];
                V            = (A[31] == B[31] && rsb_result[31] != A[31]) ? 1 : 0;
                alu_update_en =1'b1;
            end

            Op_MUL: begin
                Result       = mul_result[31:0];
                C            = mul_result[32];
                V            = (A[31] == B[31] && mul_result[31] != A[31]) ? 1 : 0;
                alu_update_en =1'b1;
            end

            Op_ADC: begin
                Result       = adc_result[31:0];
                C            = adc_result[32];
                V            = (A[31] == B[31] && adc_result[31] != A[31]) ? 1 : 0;
                alu_update_en =1'b1;
            end

            Op_SBC: begin
                Result       = sbc_result[31:0];
                C            = sbc_result[32];
                V            = (A[31] == B[31] && sbc_result[31] != A[31]) ? 1 : 0;
                alu_update_en =1'b1;
            end
//-------------------------------- Khoi logic ---------------------------------------//
            Op_And: begin
                Result       = A & B;
                C            = 0;
                V            = 0;
                alu_update_en =1'b1;
            end

            Op_Or: begin
                Result       = A | B;
                C            = 0;
                V            = 0;
                alu_update_en =1'b1;
            end

            Op_Xor: begin
                Result       = A ^ B;
                C            = 0;
                V            = 0;
                alu_update_en =1'b1;
            end

            Op_Bic: begin
                Result       = A & ~B;
                C            = 0;
                V            = 0;
                alu_update_en =1'b1;
            end

//--------------------------------- Khoi Move ----------------------------------------//

            Op_Mov: begin
                Result       = B;
                C            = 0;
                V            = 0;
                alu_update_en =1'b1;
            end

            Op_Mvn: begin
                Result       = ~B;
                C            = 0;
                V            = 0;
                alu_update_en =1'b1;
            end

//--------------------------------- Khoi chi kiem tra ------------------------------//

            Op_Tst: begin
                Result       = A & B;
                C            = 0;
                V            = 0;
                alu_update_en =1'b1;
            end

            Op_Teq: begin
                Result       = A ^ B;
                C            = 0;
                V            = 0;
                alu_update_en =1'b1;
            end

            Op_Cmp: begin
                Result       = cmp_result[31:0];
                C            = cmp_result[32];
                V            = (A[31] == B[31] && cmp_result[31] != A[31]) ? 1 : 0;
                alu_update_en =1'b1;
            end

            Op_Cmn: begin
                Result       = cmn_result[31:0];
                C            = cmn_result[32];
                V            = (A[31] == B[31] && cmn_result[31] != A[31]) ? 1 : 0;
                alu_update_en =1'b1;
            end

            default: begin
                Result       = 32'd0;
                C            = 0;
                V            = 0;
                alu_update_en = 1'b0;
            end
        endcase
        
    assign N = Result[31];
    assign Z = (Result == 32'd0) ? 1: 0; 

endmodule