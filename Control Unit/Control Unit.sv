// Main control unit for RISC-V processor
// Author : Praveen Saravanan

`timescale 1ns/1ps

module control_unit (
    input  logic [6:0] opcode,        // Instruction opcode
    input  logic [2:0] funct3,        // Function field 3
    input  logic [6:0] funct7,        // Function field 7
    
    // Control signals
    output logic reg_write,           // Register write enable
    output logic mem_read,            // Memory read enable
    output logic mem_write,           // Memory write enable
    output logic branch,              // Branch instruction
    output logic jump,                // Jump instruction
    output logic [1:0] alu_src,       // ALU source selection
    output logic [3:0] alu_control,   // ALU operation
    output logic [1:0] reg_src        // Register write source
);

// RISC-V opcodes
localparam [6:0] OP_R_TYPE    = 7'b0110011;  // R-type (register-register)
localparam [6:0] OP_I_TYPE    = 7'b0010011;  // I-type (immediate)
localparam [6:0] OP_LOAD      = 7'b0000011;  // Load instructions
localparam [6:0] OP_STORE     = 7'b0100011;  // Store instructions
localparam [6:0] OP_BRANCH    = 7'b1100011;  // Branch instructions
localparam [6:0] OP_LUI       = 7'b0110111;  // Load Upper Immediate
localparam [6:0] OP_AUIPC     = 7'b0010111;  // Add Upper Immediate to PC
localparam [6:0] OP_JAL       = 7'b1101111;  // Jump and Link
localparam [6:0] OP_JALR      = 7'b1100111;  // Jump and Link Register

// ALU source selection
localparam [1:0] ALU_SRC_REG  = 2'b00;      // Register
localparam [1:0] ALU_SRC_IMM  = 2'b01;      // Immediate
localparam [1:0] ALU_SRC_PC   = 2'b10;      // PC

// Register write source selection
localparam [1:0] REG_SRC_ALU  = 2'b00;      // ALU result
localparam [1:0] REG_SRC_MEM  = 2'b01;      // Memory data
localparam [1:0] REG_SRC_PC4  = 2'b10;      // PC + 4

// ALU control codes (matching ALU module)
localparam [3:0] ALU_ADD  = 4'b0000;
localparam [3:0] ALU_SUB  = 4'b0001;
localparam [3:0] ALU_AND  = 4'b0010;
localparam [3:0] ALU_OR   = 4'b0011;
localparam [3:0] ALU_XOR  = 4'b0100;
localparam [3:0] ALU_SLT  = 4'b0101;
localparam [3:0] ALU_SLTU = 4'b0110;
localparam [3:0] ALU_SLL  = 4'b0111;
localparam [3:0] ALU_SRL  = 4'b1000;
localparam [3:0] ALU_SRA  = 4'b1001;

always_comb begin
    // Default values
    reg_write = 1'b0;
    mem_read = 1'b0;
    mem_write = 1'b0;
    branch = 1'b0;
    jump = 1'b0;
    alu_src = ALU_SRC_REG;
    alu_control = ALU_ADD;
    reg_src = REG_SRC_ALU;
    
    case (opcode)
        OP_R_TYPE: begin
            reg_write = 1'b1;
            alu_src = ALU_SRC_REG;
            reg_src = REG_SRC_ALU;
            
            // Determine ALU operation from funct3 and funct7
            case (funct3)
                3'b000: alu_control = (funct7[5]) ? ALU_SUB : ALU_ADD;  // ADD/SUB
                3'b001: alu_control = ALU_SLL;                          // SLL
                3'b010: alu_control = ALU_SLT;                          // SLT
                3'b011: alu_control = ALU_SLTU;                         // SLTU
                3'b100: alu_control = ALU_XOR;                          // XOR
                3'b101: alu_control = (funct7[5]) ? ALU_SRA : ALU_SRL;  // SRL/SRA
                3'b110: alu_control = ALU_OR;                           // OR
                3'b111: alu_control = ALU_AND;                          // AND
                default: alu_control = ALU_ADD;
            endcase
        end
        
        OP_I_TYPE: begin
            reg_write = 1'b1;
            alu_src = ALU_SRC_IMM;
            reg_src = REG_SRC_ALU;
            
            case (funct3)
                3'b000: alu_control = ALU_ADD;                          // ADDI
                3'b001: alu_control = ALU_SLL;                          // SLLI
                3'b010: alu_control = ALU_SLT;                          // SLTI
                3'b011: alu_control = ALU_SLTU;                         // SLTIU
                3'b100: alu_control = ALU_XOR;                          // XORI
                3'b101: alu_control = (funct7[5]) ? ALU_SRA : ALU_SRL;  // SRLI/SRAI
                3'b110: alu_control = ALU_OR;                           // ORI
                3'b111: alu_control = ALU_AND;                          // ANDI
                default: alu_control = ALU_ADD;
            endcase
        end
        
        OP_LOAD: begin
            reg_write = 1'b1;
            mem_read = 1'b1;
            alu_src = ALU_SRC_IMM;
            alu_control = ALU_ADD;
            reg_src = REG_SRC_MEM;
        end
        
        OP_STORE: begin
            mem_write = 1'b1;
            alu_src = ALU_SRC_IMM;
            alu_control = ALU_ADD;
        end
        
        OP_BRANCH: begin
            branch = 1'b1;
            alu_src = ALU_SRC_REG;
            
            case (funct3)
                3'b000: alu_control = ALU_SUB;  // BEQ (subtract for comparison)
                3'b001: alu_control = ALU_SUB;  // BNE
                3'b100: alu_control = ALU_SLT;  // BLT
                3'b101: alu_control = ALU_SLT;  // BGE
                3'b110: alu_control = ALU_SLTU; // BLTU
                3'b111: alu_control = ALU_SLTU; // BGEU
                default: alu_control = ALU_SUB;
            endcase
        end
        
        OP_LUI: begin
            reg_write = 1'b1;
            alu_src = ALU_SRC_IMM;
            alu_control = ALU_ADD;  // Pass immediate through
            reg_src = REG_SRC_ALU;
        end
        
        OP_AUIPC: begin
            reg_write = 1'b1;
            alu_src = ALU_SRC_PC;
            alu_control = ALU_ADD;
            reg_src = REG_SRC_ALU;
        end
        
        OP_JAL: begin
            reg_write = 1'b1;
            jump = 1'b1;
            reg_src = REG_SRC_PC4;
        end
        
        OP_JALR: begin
            reg_write = 1'b1;
            jump = 1'b1;
            alu_src = ALU_SRC_IMM;
            alu_control = ALU_ADD;
            reg_src = REG_SRC_PC4;
        end
        
        default: begin
            // All signals remain at default values
        end
    endcase
end

endmodule
