// Program Counter with branch/jump support
// Author : Praveen Saravanan

`timescale 1ns/1ps

module program_counter #(
    parameter WIDTH = 32,
    parameter RESET_ADDR = 32'h0000_0000
)(
    input  logic clk,
    input  logic reset,
    input  logic stall,                 // Pipeline stall signal
    input  logic take_branch,           // Branch taken signal
    input  logic [WIDTH-1:0] branch_target, // Branch/jump target address
    output logic [WIDTH-1:0] pc,       // Current PC
    output logic [WIDTH-1:0] pc_plus4  // PC + 4
);

logic [WIDTH-1:0] next_pc;

// PC + 4 calculation
assign pc_plus4 = pc + 32'd4;

// Next PC selection
always_comb begin
    if (take_branch) begin
        next_pc = branch_target;
    end else begin
        next_pc = pc_plus4;
    end
end

// PC register update
always_ff @(posedge clk) begin
    if (reset) begin
        pc <= RESET_ADDR;
    end else if (!stall) begin
        pc <= next_pc;
    end
    // If stall is asserted, PC maintains its current value
end

endmodule
