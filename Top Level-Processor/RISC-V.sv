// Top Module
// Author:Praveen Saravanan
// RISC-V processor 

`timescale 1ns/1ps

//=============================================================================
// 2-Input Multiplexer
//=============================================================================
module mux2 #(
    parameter WIDTH = 32
)(
    input  logic [WIDTH-1:0] in0,
    input  logic [WIDTH-1:0] in1,
    input  logic sel,
    output logic [WIDTH-1:0] out
);

assign out = sel ? in1 : in0;

endmodule

//=============================================================================
// 4-Input Multiplexer  
//=============================================================================
module mux4 #(
    parameter WIDTH = 32
)(
    input  logic [WIDTH-1:0] in0,
    input  logic [WIDTH-1:0] in1,
    input  logic [WIDTH-1:0] in2,
    input  logic [WIDTH-1:0] in3,
    input  logic [1:0] sel,
    output logic [WIDTH-1:0] out
);

always_comb begin
    case (sel)
        2'b00: out = in0;
        2'b01: out = in1;
        2'b10: out = in2;
        2'b11: out = in3;
        default: out = in0;
    endcase
end

endmodule

//=============================================================================
// Arithmetic Logic Unit
//=============================================================================
module alu #(
    parameter WIDTH = 32
)(
    input  logic [WIDTH-1:0] a,
    input  logic [WIDTH-1:0] b,
    input  logic [3:0] alu_control,
    output logic [WIDTH-1:0] result,
    output logic zero,
    output logic overflow,
    output logic negative
);

// ALU operation codes
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

logic [WIDTH-1:0] add_result, sub_result;
logic add_overflow, sub_overflow;

assign add_result = a + b;
assign sub_result = a - b;
assign add_overflow = (a[WIDTH-1] == b[WIDTH-1]) && (add_result[WIDTH-1] != a[WIDTH-1]);
assign sub_overflow = (a[WIDTH-1] != b[WIDTH-1]) && (sub_result[WIDTH-1] != a[WIDTH-1]);

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
            result = a << b[4:0];
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

assign zero = (result == 32'h0);
assign negative = result[WIDTH-1];

endmodule

//=============================================================================
// Register File
//=============================================================================
module register_file #(
    parameter WIDTH = 32,
    parameter DEPTH = 32
)(
    input  logic clk,
    input  logic reset,
    input  logic [4:0] read_addr1,
    input  logic [4:0] read_addr2,
    output logic [WIDTH-1:0] read_data1,
    output logic [WIDTH-1:0] read_data2,
    input  logic write_enable,
    input  logic [4:0] write_addr,
    input  logic [WIDTH-1:0] write_data
);

logic [WIDTH-1:0] registers [0:DEPTH-1];

assign read_data1 = (read_addr1 == 5'b0) ? 32'h0 : registers[read_addr1];
assign read_data2 = (read_addr2 == 5'b0) ? 32'h0 : registers[read_addr2];

always_ff @(posedge clk) begin
    if (reset) begin
        for (int i = 0; i < DEPTH; i++) begin
            registers[i] <= 32'h0;
        end
    end else if (write_enable && write_addr != 5'b0) begin
        registers[write_addr] <= write_data;
    end
end

endmodule

//=============================================================================
// Immediate Generator
//=============================================================================
module immediate_generator (
    input  logic [31:0] instruction,
    output logic [31:0] immediate
);

logic [6:0] opcode;
assign opcode = instruction[6:0];

localparam [6:0] OP_I_TYPE    = 7'b0010011;
localparam [6:0] OP_LOAD      = 7'b0000011;
localparam [6:0] OP_STORE     = 7'b0100011;
localparam [6:0] OP_BRANCH    = 7'b1100011;
localparam [6:0] OP_LUI       = 7'b0110111;
localparam [6:0] OP_AUIPC     = 7'b0010111;
localparam [6:0] OP_JAL       = 7'b1101111;
localparam [6:0] OP_JALR      = 7'b1100111;

always_comb begin
    case (opcode)
        OP_I_TYPE, OP_LOAD, OP_JALR: begin
            immediate = {{20{instruction[31]}}, instruction[31:20]};
        end
        OP_STORE: begin
            immediate = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
        end
        OP_BRANCH: begin
            immediate = {{19{instruction[31]}}, instruction[31], instruction[7], 
                        instruction[30:25], instruction[11:8], 1'b0};
        end
        OP_LUI, OP_AUIPC: begin
            immediate = {instruction[31:12], 12'b0};
        end
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

//=============================================================================
// Control Unit
//=============================================================================
module control_unit (
    input  logic [6:0] opcode,
    input  logic [2:0] funct3,
    input  logic [6:0] funct7,
    output logic reg_write,
    output logic mem_read,
    output logic mem_write,
    output logic branch,
    output logic jump,
    output logic [1:0] alu_src,
    output logic [3:0] alu_control,
    output logic [1:0] reg_src
);

localparam [6:0] OP_R_TYPE    = 7'b0110011;
localparam [6:0] OP_I_TYPE    = 7'b0010011;
localparam [6:0] OP_LOAD      = 7'b0000011;
localparam [6:0] OP_STORE     = 7'b0100011;
localparam [6:0] OP_BRANCH    = 7'b1100011;
localparam [6:0] OP_LUI       = 7'b0110111;
localparam [6:0] OP_AUIPC     = 7'b0010111;
localparam [6:0] OP_JAL       = 7'b1101111;
localparam [6:0] OP_JALR      = 7'b1100111;

localparam [1:0] ALU_SRC_REG  = 2'b00;
localparam [1:0] ALU_SRC_IMM  = 2'b01;
localparam [1:0] ALU_SRC_PC   = 2'b10;

localparam [1:0] REG_SRC_ALU  = 2'b00;
localparam [1:0] REG_SRC_MEM  = 2'b01;
localparam [1:0] REG_SRC_PC4  = 2'b10;

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
            case (funct3)
                3'b000: alu_control = (funct7[5]) ? ALU_SUB : ALU_ADD;
                3'b001: alu_control = ALU_SLL;
                3'b010: alu_control = ALU_SLT;
                3'b011: alu_control = ALU_SLTU;
                3'b100: alu_control = ALU_XOR;
                3'b101: alu_control = (funct7[5]) ? ALU_SRA : ALU_SRL;
                3'b110: alu_control = ALU_OR;
                3'b111: alu_control = ALU_AND;
                default: alu_control = ALU_ADD;
            endcase
        end
        OP_I_TYPE: begin
            reg_write = 1'b1;
            alu_src = ALU_SRC_IMM;
            reg_src = REG_SRC_ALU;
            case (funct3)
                3'b000: alu_control = ALU_ADD;
                3'b001: alu_control = ALU_SLL;
                3'b010: alu_control = ALU_SLT;
                3'b011: alu_control = ALU_SLTU;
                3'b100: alu_control = ALU_XOR;
                3'b101: alu_control = (funct7[5]) ? ALU_SRA : ALU_SRL;
                3'b110: alu_control = ALU_OR;
                3'b111: alu_control = ALU_AND;
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
                3'b000: alu_control = ALU_SUB;
                3'b001: alu_control = ALU_SUB;
                3'b100: alu_control = ALU_SLT;
                3'b101: alu_control = ALU_SLT;
                3'b110: alu_control = ALU_SLTU;
                3'b111: alu_control = ALU_SLTU;
                default: alu_control = ALU_SUB;
            endcase
        end
        OP_LUI: begin
            reg_write = 1'b1;
            alu_src = ALU_SRC_IMM;
            alu_control = ALU_ADD;
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
        end
    endcase
end

endmodule

//=============================================================================
// Branch Unit
//=============================================================================
module branch_unit (
    input  logic [31:0] rs1_data,
    input  logic [31:0] rs2_data,
    input  logic [2:0] funct3,
    input  logic branch,
    input  logic jump,
    output logic take_branch
);

logic eq, lt, ltu;

assign eq  = (rs1_data == rs2_data);
assign lt  = ($signed(rs1_data) < $signed(rs2_data));
assign ltu = (rs1_data < rs2_data);

always_comb begin
    if (jump) begin
        take_branch = 1'b1;
    end else if (branch) begin
        case (funct3)
            3'b000: take_branch = eq;
            3'b001: take_branch = ~eq;
            3'b100: take_branch = lt;
            3'b101: take_branch = ~lt;
            3'b110: take_branch = ltu;
            3'b111: take_branch = ~ltu;
            default: take_branch = 1'b0;
        endcase
    end else begin
        take_branch = 1'b0;
    end
end

endmodule

//=============================================================================
// Program Counter
//=============================================================================
module program_counter #(
    parameter WIDTH = 32,
    parameter RESET_ADDR = 32'h0000_0000
)(
    input  logic clk,
    input  logic reset,
    input  logic stall,
    input  logic take_branch,
    input  logic [WIDTH-1:0] branch_target,
    output logic [WIDTH-1:0] pc,
    output logic [WIDTH-1:0] pc_plus4
);

logic [WIDTH-1:0] next_pc;

assign pc_plus4 = pc + 32'd4;

mux2 #(.WIDTH(WIDTH)) pc_mux (
    .in0(pc_plus4),
    .in1(branch_target),
    .sel(take_branch),
    .out(next_pc)
);

always_ff @(posedge clk) begin
    if (reset) begin
        pc <= RESET_ADDR;
    end else if (!stall) begin
        pc <= next_pc;
    end
end

endmodule

//=============================================================================
// Instruction Memory
//=============================================================================
module instruction_memory #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter MEM_SIZE = 1024
)(
    input  logic [ADDR_WIDTH-1:0] address,
    output logic [DATA_WIDTH-1:0] instruction
);

logic [DATA_WIDTH-1:0] memory [0:MEM_SIZE-1];
logic [ADDR_WIDTH-3:0] word_addr;
assign word_addr = address[ADDR_WIDTH-1:2];

always_comb begin
    if (word_addr < MEM_SIZE) begin
        instruction = memory[word_addr];
    end else begin
        instruction = 32'h0000_0013;
    end
end

initial begin
    for (int i = 0; i < MEM_SIZE; i++) begin
        memory[i] = 32'h0000_0013;
    end
    
    memory[0] = 32'h00500093;   // ADDI x1, x0, 5      (x1 = 5)
    memory[1] = 32'h00300113;   // ADDI x2, x0, 3      (x2 = 3)
    memory[2] = 32'h002081b3;   // ADD  x3, x1, x2     (x3 = 8)
    memory[3] = 32'h40208233;   // SUB  x4, x1, x2     (x4 = 2)
    memory[4] = 32'h0020f2b3;   // AND  x5, x1, x2     (x5 = 1)
    memory[5] = 32'h0020e333;   // OR   x6, x1, x2     (x6 = 7)
    memory[6] = 32'h0020c3b3;   // XOR  x7, x1, x2     (x7 = 6)
    memory[7] = 32'h0020a433;   // SLT  x8, x1, x2     (x8 = 0)
    memory[8] = 32'h00000013;   // NOP
    memory[9] = 32'h00000013;   // NOP
end

endmodule

//=============================================================================
// Data Memory
//=============================================================================
module data_memory #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter MEM_SIZE = 1024
)(
    input  logic clk,
    input  logic reset,
    input  logic [ADDR_WIDTH-1:0] address,
    input  logic [DATA_WIDTH-1:0] write_data,
    input  logic [2:0] funct3,
    input  logic mem_read,
    input  logic mem_write,
    output logic [DATA_WIDTH-1:0] read_data
);

logic [7:0] memory [0:MEM_SIZE*4-1];
logic [ADDR_WIDTH-1:0] byte_addr;
assign byte_addr = address;

logic [31:0] word_data;
logic [15:0] halfword_data;
logic [7:0] byte_data;

always_comb begin
    if (mem_read && byte_addr < (MEM_SIZE * 4)) begin
        word_data = {memory[byte_addr+3], memory[byte_addr+2], 
                     memory[byte_addr+1], memory[byte_addr]};
        halfword_data = {memory[byte_addr+1], memory[byte_addr]};
        byte_data = memory[byte_addr];
        
        case (funct3)
            3'b000: read_data = {{24{byte_data[7]}}, byte_data};
            3'b001: read_data = {{16{halfword_data[15]}}, halfword_data};
            3'b010: read_data = word_data;
            3'b100: read_data = {24'b0, byte_data};
            3'b101: read_data = {16'b0, halfword_data};
            default: read_data = word_data;
        endcase
    end else begin
        read_data = 32'h0;
    end
end

always_ff @(posedge clk) begin
    if (reset) begin
        for (int i = 0; i < MEM_SIZE * 4; i++) begin
            memory[i] <= 8'h0;
        end
    end else if (mem_write && byte_addr < (MEM_SIZE * 4)) begin
        case (funct3)
            3'b000: begin
                memory[byte_addr] <= write_data[7:0];
            end
            3'b001: begin
                memory[byte_addr]   <= write_data[7:0];
                memory[byte_addr+1] <= write_data[15:8];
            end
            3'b010: begin
                memory[byte_addr]   <= write_data[7:0];
                memory[byte_addr+1] <= write_data[15:8];
                memory[byte_addr+2] <= write_data[23:16];
                memory[byte_addr+3] <= write_data[31:24];
            end
            default: begin
                memory[byte_addr]   <= write_data[7:0];
                memory[byte_addr+1] <= write_data[15:8];
                memory[byte_addr+2] <= write_data[23:16];
                memory[byte_addr+3] <= write_data[31:24];
            end
        endcase
    end
end

endmodule

//=============================================================================
// TOP-LEVEL PROCESSOR MODULE
//=============================================================================
module processor_complete #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter RESET_ADDR = 32'h0000_0000
)(
    input  logic clk,
    input  logic reset,
    
    // Debug outputs
    output logic [ADDR_WIDTH-1:0] pc_out,
    output logic [DATA_WIDTH-1:0] instruction_out,
    output logic [DATA_WIDTH-1:0] alu_result_out,
    output logic [DATA_WIDTH-1:0] reg_data1_out,
    output logic [DATA_WIDTH-1:0] reg_data2_out
);

// Internal signals
logic [ADDR_WIDTH-1:0] pc, pc_plus4, branch_target;
logic [DATA_WIDTH-1:0] instruction;
logic [DATA_WIDTH-1:0] immediate;
logic [DATA_WIDTH-1:0] rs1_data, rs2_data, rd_data;
logic [DATA_WIDTH-1:0] alu_a, alu_b, alu_result;
logic [DATA_WIDTH-1:0] mem_read_data;
logic [3:0] alu_control;
logic [4:0] rs1_addr, rs2_addr, rd_addr;
logic [2:0] funct3;
logic [6:0] funct7, opcode;

// Control signals
logic reg_write, mem_read, mem_write, branch, jump;
logic [1:0] alu_src, reg_src;
logic take_branch;
logic alu_zero, alu_overflow, alu_negative;

// Instruction fields
assign opcode = instruction[6:0];
assign rd_addr = instruction[11:7];
assign funct3 = instruction[14:12];
assign rs1_addr = instruction[19:15];
assign rs2_addr = instruction[24:20];
assign funct7 = instruction[31:25];

// Debug outputs
assign pc_out = pc;
assign instruction_out = instruction;
assign alu_result_out = alu_result;
assign reg_data1_out = rs1_data;
assign reg_data2_out = rs2_data;

// Program Counter
program_counter #(
    .WIDTH(ADDR_WIDTH),
    .RESET_ADDR(RESET_ADDR)
) pc_inst (
    .clk(clk),
    .reset(reset),
    .stall(1'b0),
    .take_branch(take_branch),
    .branch_target(branch_target),
    .pc(pc),
    .pc_plus4(pc_plus4)
);

// Instruction Memory
instruction_memory #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
) imem_inst (
    .address(pc),
    .instruction(instruction)
);

// Register File
register_file #(
    .WIDTH(DATA_WIDTH),
    .DEPTH(32)
) regfile_inst (
    .clk(clk),
    .reset(reset),
    .read_addr1(rs1_addr),
    .read_addr2(rs2_addr),
    .read_data1(rs1_data),
    .read_data2(rs2_data),
    .write_enable(reg_write),
    .write_addr(rd_addr),
    .write_data(rd_data)
);

// Immediate Generator
immediate_generator imm_gen_inst (
    .instruction(instruction),
    .immediate(immediate)
);

// Control Unit
control_unit ctrl_inst (
    .opcode(opcode),
    .funct3(funct3),
    .funct7(funct7),
    .reg_write(reg_write),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .branch(branch),
    .jump(jump),
    .alu_src(alu_src),
    .alu_control(alu_control),
    .reg_src(reg_src)
);

// ALU Input Selection using MUX4
mux4 #(.WIDTH(DATA_WIDTH)) alu_a_mux (
    .in0(rs1_data),     // ALU_SRC_REG
    .in1(rs1_data),     // ALU_SRC_IMM (a = rs1)
    .in2(pc),           // ALU_SRC_PC
    .in3(32'h0),        // Unused
    .sel(alu_src),
    .out(alu_a)
);

mux4 #(.WIDTH(DATA_WIDTH)) alu_b_mux (
    .in0(rs2_data),     // ALU_SRC_REG
    .in1(immediate),    // ALU_SRC_IMM
    .in2(immediate),    // ALU_SRC_PC (b = immediate)
    .in3(32'h0),        // Unused
    .sel(alu_src),
    .out(alu_b)
);

// ALU
alu #(
    .WIDTH(DATA_WIDTH)
) alu_inst (
    .a(alu_a),
    .b(alu_b),
    .alu_control(alu_control),
    .result(alu_result),
    .zero(alu_zero),
    .overflow(alu_overflow),
    .negative(alu_negative)
);

// Branch Unit
branch_unit branch_inst (
    .rs1_data(rs1_data),
    .rs2_data(rs2_data),
    .funct3(funct3),
    .branch(branch),
    .jump(jump),
    .take_branch(take_branch)
);

// Branch Target Calculation using MUX2
logic [DATA_WIDTH-1:0] jalr_target, pc_imm_target;
assign jalr_target = (rs1_data + immediate) & ~32'h1;
assign pc_imm_target = pc + immediate;

mux2 #(.WIDTH(DATA_WIDTH)) branch_target_mux (
    .in0(pc_imm_target),    // JAL, branches
    .in1(jalr_target),      // JALR
    .sel(opcode == 7'b1100111), // JALR opcode
    .out(branch_target)
);

// Data Memory
data_memory #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
) dmem_inst (
    .clk(clk),
    .reset(reset),
    .address(alu_result),
    .write_data(rs2_data),
    .funct3(funct3),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .read_data(mem_read_data)
);

// Register Write Data Selection using MUX4
mux4 #(.WIDTH(DATA_WIDTH)) reg_data_mux (
    .in0(alu_result),       // REG_SRC_ALU
    .in1(mem_read_data),    // REG_SRC_MEM
    .in2(pc_plus4),         // REG_SRC_PC4
    .in3(32'h0),            // Unused
    .sel(reg_src),
    .out(rd_data)
);

endmodule
