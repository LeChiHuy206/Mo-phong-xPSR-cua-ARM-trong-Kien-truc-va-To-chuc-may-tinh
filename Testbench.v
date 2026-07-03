`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////
// File Name  : Testbench.v
// Description: Mo phong chuong trinh ARM tinh tong mang va test Ngat
//
// Mo phong doan code ARM:
//   MOV  R0, #0          ; R0 = 0  (tong)
//   MOV  R1, #0          ; R1 = 0  (chi so)
//   ADR  R2, Array       ; R2 tro vao mang [10,20,30,40,50]
//
// Loop:
//   CMP  R1, #5          ; so sanh R1 voi 5
//   BGE  EndLoop         ; neu R1 >= 5 thoat vong lap
//   LDR  R3, [R2], #4    ; nap phan tu thu R1 vao R3, tang dia chi
//   ADD  R0, R0, R3      ; R0 = R0 + R3 (tich luy tong)
//   ADD  R1, R1, #1      ; R1 = R1 + 1  (tang chi so)
//   B    Loop            ; quay lai Loop
//
// EndLoop:
//   ; Ket qua cuoi cung luu o R0 = 10+20+30+40+50 = 150
//
// Array: DCD 10, 20, 30, 40, 50
//////////////////////////////////////////////////////////////////////////

module Testbench;

    reg        clk, rst;
    reg [31:0] A, B;
    reg [3:0]  OpCode;
    reg [31:0] msr_data_in;
    reg        msr_wire_f_en, msr_wire_c_en;
    
    // Bo sung khai bao 2 tin hieu ngat tu ben ngoai
    reg        irq_req;
    reg        fiq_req;

    wire [31:0] Result, cpsr_out;
    // ĐÃ SỬA LỖI CÚ PHÁP: Thay dau phay (,) bang dau cham phay (;)
    wire [31:0] save_cpsr_irq; 
    wire [31:0] save_cpsr_fiq; 
    wire N, Z, C, V;

    Top_ALU_CPSR uut (
        .clk          (clk),
        .rst          (rst),
        .A            (A),
        .B            (B),
        .OpCode       (OpCode),
        .msr_data_in  (msr_data_in),
        .msr_wire_f_en(msr_wire_f_en),
        .msr_wire_c_en(msr_wire_c_en),
        .irq_req      (irq_req), // Noi tin hieu IRQ
        .fiq_req      (fiq_req), // Noi tin hieu FIQ
        .Result       (Result),
        .cpsr_out     (cpsr_out),
        .save_cpsr_fiq(save_cpsr_fiq),
        .save_cpsr_irq(save_cpsr_irq),
        .N(N), .Z(Z), .C(C), .V(V)
    );

    // OpCode
    localparam Op_Add = 4'b0000,
               Op_Sub = 4'b0001,
               Op_RSB = 4'b0010,
               Op_MUL = 4'b0011,
               Op_ADC = 4'b0100,
               Op_SBC = 4'b0101,
               Op_And = 4'b0110,
               Op_Or  = 4'b0111,
               Op_Xor = 4'b1000,
               Op_Bic = 4'b1001,
               Op_Mov = 4'b1010,
               Op_Mvn = 4'b1011,
               Op_Tst = 4'b1100,
               Op_Teq = 4'b1101,
               Op_Cmp = 4'b1110,
               Op_Cmn = 4'b1111;

    // Mang du lieu: Array[5] = {10, 20, 30, 40, 50}
    reg [31:0] Array [0:4];

    // Cac thanh ghi ARM duoc mo phong
    reg [31:0] R0, R1, R2, R3;

    integer i;

    initial clk = 0;
    always #5 clk = ~clk;

    // Task: thuc hien 1 phep toan ALU va doi clock
    task run_alu;
        input [31:0] in_a, in_b;
        input [3:0]  op;
        begin
            A = in_a; B = in_b; OpCode = op;
            @(posedge clk); #1;
        end
    endtask

    // Task: in trang thai hien tai
    task print_state;
        input [63:0] label;
        begin
            $display("[%-8s] R0=%3d R1=%3d R2=%3d R3=%3d | Result=%3d N=%b Z=%b C=%b V=%b | CPSR=%08h",
                label, R0, R1, R2, R3, Result, N, Z, C, V, cpsr_out);
        end
    endtask

    initial begin
        $dumpfile("Testbench.vcd");
        $dumpvars(0, Testbench);

        // Khoi tao mang
        Array[0] = 32'd10;
        Array[1] = 32'd20;
        Array[2] = 32'd30;
        Array[3] = 32'd40;
        Array[4] = 32'd50;

        // Khoi tao tin hieu ALU
        {A, B, OpCode, msr_data_in, msr_wire_f_en, msr_wire_c_en} = 0;
        
        // Khoi tao tin hieu NGAT o muc thap (Chua co ngat)
        irq_req = 0;
        fiq_req = 0;

        //------------------------------------------------------------
        // RESET
        //------------------------------------------------------------
        rst = 1; @(posedge clk); #1; rst = 0;
        $display("============================================================");
        $display(" Mo phong tinh tong mang [10, 20, 30, 40, 50]");
        $display("============================================================");
        $display("[RESET  ] CPSR=%08h", cpsr_out);
        $display("------------------------------------------------------------");
        $display("[%-8s] %-4s %-4s %-4s %-4s | %-8s N Z C V",
                 "BUOC", "R0", "R1", "R2", "R3", "Result");
        $display("------------------------------------------------------------");

        //------------------------------------------------------------
        // MOV R0, #0  =>  R0 = 0  (tong = 0)
        //------------------------------------------------------------
        run_alu(32'd0, 32'd0, Op_Mov);
        R0 = Result;
        print_state("MOV R0,0");

        //------------------------------------------------------------
        // MOV R1, #0  =>  R1 = 0  (chi so = 0)
        //------------------------------------------------------------
        run_alu(32'd0, 32'd0, Op_Mov);
        R1 = Result;
        print_state("MOV R1,0");

        //------------------------------------------------------------
        // ADR R2, Array  =>  R2 = 0 (chi so mang bat dau)
        //------------------------------------------------------------
        run_alu(32'd0, 32'd0, Op_Mov);
        R2 = 0;
        print_state("ADR R2");

        $display("------------------------------------------------------------");

        //------------------------------------------------------------
        // Vong lap: Loop
        //------------------------------------------------------------
        begin : Loop
            for (i = 0; i < 5; i = i + 1) begin

                // CMP R1, #5  =>  tinh R1 - 5, chi cap nhat flags
                run_alu(R1, 32'd5, Op_Cmp);

                // LDR R3, [R2], #4  =>  nap Array[R2] vao R3, tang R2
                R3 = Array[R2];
                R2 = R2 + 1;

                // ADD R0, R0, R3  =>  R0 = R0 + R3
                run_alu(R0, R3, Op_Add);
                R0 = Result;

                // ADD R1, R1, #1  =>  R1 = R1 + 1
                run_alu(R1, 32'd1, Op_Add);
                R1 = Result;

                print_state("LOOP");
            end
        end // Loop

        //------------------------------------------------------------
        // CMP R1, #5 lan cuoi => Z=1 => BGE EndLoop -> thoat
        //------------------------------------------------------------
        run_alu(R1, 32'd5, Op_Cmp);
        $display("------------------------------------------------------------");
        $display("[CMP R1,5] R1=%0d -> N=%b Z=%b C=%b V=%b | CPSR = %08h=> BGE EndLoop", R1, N, Z, C, V, cpsr_out);

        //------------------------------------------------------------
        // EndLoop: ket qua cuoi cung o R0
        //------------------------------------------------------------
        $display("============================================================");
        $display(" ENDLOOP: Tong = R0 = %0d  (mong doi: 150)", R0);
        $display("============================================================");
        
        //------------------------------------------------------------
        // THỬ NGHIỆM TÍN HIỆU NGẮT (IRQ & FIQ TRIGGER)
        //------------------------------------------------------------
        $display("\n============================================================");
        $display(" KIỂM TRA MÔ PHỎNG TÍN HIỆU NGẮT (Lưu CPSR vào SPSR)");
        $display(" CPSR hien tai dang la: %08h", cpsr_out);
        $display("============================================================");
        
        // Giong nhu co thiet bi ngoai vi gui tin hieu ngat IRQ
        @(posedge clk);
        #1; irq_req = 1; 
        @(posedge clk);
        #1; irq_req = 0; 
        $display("[SƯ KIEN IRQ] Kich hoat IRQ! => SPSR_irq duoc cap nhat: %08h", save_cpsr_irq);
        
        // Giong nhu co thiet bi ngoai vi gui tin hieu ngat FIQ
        @(posedge clk);
        #1; fiq_req = 1;
        @(posedge clk);
        #1; fiq_req = 0;
        $display("[SƯ KIEN FIQ] Kich hoat FIQ! => SPSR_fiq duoc cap nhat: %08h", save_cpsr_fiq);
        $display("============================================================");

        $finish;
    end

endmodule