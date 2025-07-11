// Branch condition evaluation unit
// Author : Praveen Saravanan

`timescale 1ns/1ps

module branch_unit (
    input  logic [31:0] rs1_data,      // First register data
    input  logic [31:0] rs2_data,      // Second register data
    input  logic [2:0] funct3,         // Function field from instruction
    input  logic branch,               // Branch instruction signal
    input  logic jump,                 // Jump instruction signal
    output logic take_branch           // Branch taken signal
);

logic eq, lt, ltu;

// Comparison operations
assign eq  = (rs1_data == rs2_data);
assign lt  = ($signed(rs1_data) < $signed(rs2_data));
assign ltu = (rs1_data < rs2_data);

always_comb begin
    if (jump) begin
        // Unconditional jump
        take_branch = 1'b1;
    end else if (branch) begin
        // Conditional branch based on funct3
        case (funct3)
            3'b000: take_branch = eq;       // BEQ - branch if equal
            3'b001: take_branch = ~eq;      // BNE - branch if not equal
            3'b100: take_branch = lt;       // BLT - branch if less than (signed)
            3'b101: take_branch = ~lt;      // BGE - branch if greater or equal (signed)
            3'b110: take_branch = ltu;      // BLTU - branch if less than (unsigned)
            3'b111: take_branch = ~ltu;     // BGEU - branch if greater or equal (unsigned)
            default: take_branch = 1'b0;
        endcase
    end else begin
        // No branch/jump
        take_branch = 1'b0;
    end
end

endmodule
