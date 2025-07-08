// Data memory (L1D cache at MEM stage) for processor
// Author : Praveen Saravanan

`timescale 1ns/1ps

module data_memory #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter MEM_SIZE = 1024        // Number of 32-bit words
)(
    input  logic clk,
    input  logic reset,
    input  logic [ADDR_WIDTH-1:0] address,
    input  logic [DATA_WIDTH-1:0] write_data,
    input  logic [2:0] funct3,          // For determining operation size
    input  logic mem_read,
    input  logic mem_write,
    output logic [DATA_WIDTH-1:0] read_data
);

// Memory array (byte-addressable but stored as words)
logic [7:0] memory [0:MEM_SIZE*4-1];

// Word-aligned address
logic [ADDR_WIDTH-1:0] byte_addr;
assign byte_addr = address;

// Internal signals for different access sizes
logic [31:0] word_data;
logic [15:0] halfword_data;
logic [7:0] byte_data;

// Read operation
always_comb begin
    if (mem_read && byte_addr < (MEM_SIZE * 4)) begin
        // Read word from memory (little-endian)
        word_data = {memory[byte_addr+3], memory[byte_addr+2], 
                     memory[byte_addr+1], memory[byte_addr]};
        halfword_data = {memory[byte_addr+1], memory[byte_addr]};
        byte_data = memory[byte_addr];
        
        case (funct3)
            3'b000: read_data = {{24{byte_data[7]}}, byte_data};        // LB (sign-extended byte)
            3'b001: read_data = {{16{halfword_data[15]}}, halfword_data}; // LH (sign-extended halfword)
            3'b010: read_data = word_data;                              // LW (word)
            3'b100: read_data = {24'b0, byte_data};                     // LBU (unsigned byte)
            3'b101: read_data = {16'b0, halfword_data};                 // LHU (unsigned halfword)
            default: read_data = word_data;
        endcase
    end else begin
        read_data = 32'h0;
    end
end

// Write operation
always_ff @(posedge clk) begin
    if (reset) begin
        // Initialize memory to zero
        for (int i = 0; i < MEM_SIZE * 4; i++) begin
            memory[i] <= 8'h0;
        end
    end else if (mem_write && byte_addr < (MEM_SIZE * 4)) begin
        case (funct3)
            3'b000: begin  // SB (store byte)
                memory[byte_addr] <= write_data[7:0];
            end
            3'b001: begin  // SH (store halfword)
                memory[byte_addr]   <= write_data[7:0];
                memory[byte_addr+1] <= write_data[15:8];
            end
            3'b010: begin  // SW (store word)
                memory[byte_addr]   <= write_data[7:0];
                memory[byte_addr+1] <= write_data[15:8];
                memory[byte_addr+2] <= write_data[23:16];
                memory[byte_addr+3] <= write_data[31:24];
            end
            default: begin
                // Default to word store
                memory[byte_addr]   <= write_data[7:0];
                memory[byte_addr+1] <= write_data[15:8];
                memory[byte_addr+2] <= write_data[23:16];
                memory[byte_addr+3] <= write_data[31:24];
            end
        endcase
    end
end

// Debug: Monitor memory writes
`ifdef DEBUG
    always_ff @(posedge clk) begin
        if (mem_write && byte_addr < (MEM_SIZE * 4)) begin
            $display("DataMem: Writing 0x%08h to address 0x%08h at time %0t", 
                     write_data, byte_addr, $time);
        end
    end
`endif

endmodule
