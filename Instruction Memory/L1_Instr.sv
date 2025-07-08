// Instruction memory (should be an L1_I cache in IF stage)for processor
// Author : Praveen Saravanan

`timescale 1ns/1ps

module instruction_memory #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter MEM_SIZE = 1024        // Number of 32-bit words
)(
    input  logic [ADDR_WIDTH-1:0] address,
    output logic [DATA_WIDTH-1:0] instruction
);

// Memory array
logic [DATA_WIDTH-1:0] memory [0:MEM_SIZE-1];

// Word-aligned address (ignore lower 2 bits)
logic [ADDR_WIDTH-3:0] word_addr;
assign word_addr = address[ADDR_WIDTH-1:2];

// Read instruction (combinational)
always_comb begin
    if (word_addr < MEM_SIZE) begin
        instruction = memory[word_addr];
    end else begin
        instruction = 32'h0000_0013;  // NOP instruction (ADDI x0, x0, 0)
    end
end

// Initialize memory with some sample RISC-V instructions
initial begin
    // Initialize all memory to NOP instructions
    for (int i = 0; i < MEM_SIZE; i++) begin
        memory[i] = 32'h0000_0013;  // NOP (ADDI x0, x0, 0)
    end
    
    // Sample program - simple addition
    memory[0] = 32'h00500093;   // ADDI x1, x0, 5      (x1 = 5)
    memory[1] = 32'h00300113;   // ADDI x2, x0, 3      (x2 = 3)
    memory[2] = 32'h002081b3;   // ADD  x3, x1, x2     (x3 = x1 + x2 = 8)
    memory[3] = 32'h40208233;   // SUB  x4, x1, x2     (x4 = x1 - x2 = 2)
    memory[4] = 32'h0020f2b3;   // AND  x5, x1, x2     (x5 = x1 & x2 = 1)
    memory[5] = 32'h0020e333;   // OR   x6, x1, x2     (x6 = x1 | x2 = 7)
    memory[6] = 32'h0020c3b3;   // XOR  x7, x1, x2     (x7 = x1 ^ x2 = 6)
    memory[7] = 32'h0020a433;   // SLT  x8, x1, x2     (x8 = (x1 < x2) = 0)
    memory[8] = 32'h00000013;   // NOP
    memory[9] = 32'h00000013;   // NOP
    
    // Add more instructions as needed for testing
end

// Load program from file
`ifdef LOAD_PROGRAM
initial begin
    $readmemh("program.hex", memory);
end
`endif

endmodule
