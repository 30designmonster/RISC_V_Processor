// Immediate value generator for different RISC-V instruction formats
// Author: Praveen Saravanan

`timescale 1ns/1ps

module immediate_generator (
    input  logic [31:0] instruction,    // 32-bit instruction
    output logic [31:0] immediate       // Sign-extended immediate value
);

logic [6:0] opcode;
logic [2:0] funct3;

assign opcode = instruction[6:0];
assign funct3 = instruction[14:12];

// RISC-V opcodes for immediate format identification
localparam [6:0] OP_I_TYPE    = 7'b0010011;  // I-type (immediate)
localparam [6:0] OP_LOAD      = 7'b0000011;  // Load instructions
localparam [6:0] OP_STORE     = 7'b0100011;  // Store instructions
localparam [6:0] OP_BRANCH    = 7'b1100011;  // Branch instructions
localparam [6:0] OP_LUI       = 7'b0110111;  // Load Upper Immediate
localparam [6:0] OP_AUIPC     = 7'b0010111;  // Add Upper Immediate to PC
localparam [6:0] OP_JAL       = 7'b1101111;  // Jump and Link
localparam [6:0] OP_JALR      = 7'b1100111;  // Jump and Link Register

always_comb begin
    case (opcode)
        // I-type immediate: [31:20] sign-extended
        OP_I_TYPE, OP_LOAD, OP_JALR: begin
            immediate = {{20{instruction[31]}}, instruction[31:20]};
        end
        
        // S-type immediate: [31:25|11:7] sign-extended
        OP_STORE: begin
            immediate = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
        end
        
        // B-type immediate: [31|7|30:25|11:8] << 1, sign-extended
        OP_BRANCH: begin
            immediate = {{19{instruction[31]}}, instruction[31], instruction[7], 
                        instruction[30:25], instruction[11:8], 1'b0};
        end
        
        // U-type immediate: [31:12] << 12
        OP_LUI, OP_AUIPC: begin
            immediate = {instruction[31:12], 12'b0};
        end
        
        // J-type immediate: [31|19:12|20|30:21] << 1, sign-extended
        OP_JAL: begin
            immediate = {{11{instruction[31]}}, instruction[31], instruction[19:12], 
                        instruction[20], instruction[30:21], 1'b0};
        end
        
        default: begin
            immediate = 32'h0;
        end
    endcase
end

endmodule
