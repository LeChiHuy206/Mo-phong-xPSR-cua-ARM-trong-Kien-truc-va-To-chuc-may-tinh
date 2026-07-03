`timescale 1ns/1ps
module CPSR_Regsister(
    input wire clk,
    input wire rst,

    input wire [3:0] alu_flags_in,
    input wire alu_update_en,

    input wire [31:0] msr_data_in,
    input wire msr_wire_f_en,
    input wire msr_wire_c_en,

    output wire [31:0] cpsr_out,
    output wire N, Z, C, V
);
    reg [31:0] cpsr_reg;
    localparam RESET_STATE = 32'h000000D3;

    always @(posedge clk or posedge rst) begin
        if(rst) 
            cpsr_reg <= RESET_STATE;
        else begin
            if(msr_wire_f_en) begin
                cpsr_reg[31:28] <= msr_data_in[31:28];
            end

            else 
                if(alu_update_en) begin 
                    cpsr_reg[31:28] <= alu_flags_in[3:0];
                end

            if(msr_wire_c_en) begin 
                cpsr_reg[7:0] <= msr_data_in[7:0];
            end
            
        end
    end

    assign cpsr_out = cpsr_reg;
    assign {N,Z,C,V} = cpsr_reg[31:28];

endmodule