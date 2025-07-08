// File: rtl/core/alu.sv
// Arithmetic Logic Unit for 32-bit RISC processor
//Authpr:Praveen Saravanan

`timescale 1ns/1ps

module alu #(
    parameter WIDTH = 32
)(
    input  logic [WIDTH-1:0] a,           // First operand
    input  logic [WIDTH-1:0] b,           // Second operand  
    input  logic [3:0] alu_control,       // ALU operation select
    output logic [WIDTH-1:0] result,      // ALU result
    output logic zero,                     // Zero flag
    output logic overflow,                 // Overflow flag
    output logic negative                  // Negative flag
);

// ALU operation codes
localparam [3:0] ALU_ADD  = 4'b0000;    // Addition
localparam [3:0] ALU_SUB  = 4'b0001;    // Subtraction
localparam [3:0] ALU_AND  = 4'b0010;    // Bitwise AND
localparam [3:0] ALU_OR   = 4'b0011;    // Bitwise OR
localparam [3:0] ALU_XOR  = 4'b0100;    // Bitwise XOR
localparam [3:0] ALU_SLT  = 4'b0101;    // Set less than (signed)
localparam [3:0] ALU_SLTU = 4'b0110;    // Set less than (unsigned)
localparam [3:0] ALU_SLL  = 4'b0111;    // Shift left logical
localparam [3:0] ALU_SRL  = 4'b1000;    // Shift right logical
localparam [3:0] ALU_SRA  = 4'b1001;    // Shift right arithmetic

logic [WIDTH-1:0] add_result;
logic [WIDTH-1:0] sub_result;
logic add_overflow, sub_overflow;

// Addition and subtraction with overflow detection
assign add_result = a + b;
assign sub_result = a - b;

// Overflow detection for addition: occurs when signs of operands are same but result sign differs
assign add_overflow = (a[WIDTH-1] == b[WIDTH-1]) && (add_result[WIDTH-1] != a[WIDTH-1]);

// Overflow detection for subtraction: a - b = a + (-b)
assign sub_overflow = (a[WIDTH-1] != b[WIDTH-1]) && (sub_result[WIDTH-1] != a[WIDTH-1]);

// Main ALU operation
always_comb begin
    case (alu_control)
        ALU_ADD: begin
            result = add_result;
            overflow = add_overflow;
        end
        ALU_SUB: begin
            result = sub_result;
            overflow = sub_overflow;
        end
        ALU_AND: begin
            result = a & b;
            overflow = 1'b0;
        end
        ALU_OR: begin
            result = a | b;
            overflow = 1'b0;
        end
        ALU_XOR: begin
            result = a ^ b;
            overflow = 1'b0;
        end
        ALU_SLT: begin
            result = ($signed(a) < $signed(b)) ? 32'h1 : 32'h0;
            overflow = 1'b0;
        end
        ALU_SLTU: begin
            result = (a < b) ? 32'h1 : 32'h0;
            overflow = 1'b0;
        end
        ALU_SLL: begin
            result = a << b[4:0];  // Only use lower 5 bits for shift amount
            overflow = 1'b0;
        end
        ALU_SRL: begin
            result = a >> b[4:0];
            overflow = 1'b0;
        end
        ALU_SRA: begin
            result = $signed(a) >>> b[4:0];
            overflow = 1'b0;
        end
        default: begin
            result = 32'h0;
            overflow = 1'b0;
        end
    endcase
end

// Status flags
assign zero = (result == 32'h0);
assign negative = result[WIDTH-1];

endmodule
