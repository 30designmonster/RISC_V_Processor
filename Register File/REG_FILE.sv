// 32-register file with dual read ports and single write port
// Author : Praveen Saravanan

`timescale 1ns/1ps

module register_file #(
    parameter WIDTH = 32,
    parameter DEPTH = 32
)(
    input  logic clk,
    input  logic reset,
    
    // Read ports
    input  logic [4:0] read_addr1,         // rs1 address
    input  logic [4:0] read_addr2,         // rs2 address
    output logic [WIDTH-1:0] read_data1,   // rs1 data
    output logic [WIDTH-1:0] read_data2,   // rs2 data
    
    // Write port  
    input  logic write_enable,             // rd write enable
    input  logic [4:0] write_addr,         // rd address
    input  logic [WIDTH-1:0] write_data    // rd data
);

// Register array (x0 to x31)
logic [WIDTH-1:0] registers [0:DEPTH-1];

// Read operations (combinational)
// x0 is always 0 in RISC-V
assign read_data1 = (read_addr1 == 5'b0) ? 32'h0 : registers[read_addr1];
assign read_data2 = (read_addr2 == 5'b0) ? 32'h0 : registers[read_addr2];

// Write operation (synchronous)
always_ff @(posedge clk) begin
    if (reset) begin
        // Initialize all registers to 0
        for (int i = 0; i < DEPTH; i++) begin
            registers[i] <= 32'h0;
        end
    end else if (write_enable && write_addr != 5'b0) begin
        // x0 cannot be written (always 0)
        registers[write_addr] <= write_data;
    end
end

// Debug: Allow inspection of register contents
`ifdef DEBUG
    always_ff @(posedge clk) begin
        if (write_enable && write_addr != 5'b0) begin
            $display("RegFile: Writing 0x%08h to register x%0d at time %0t", 
                     write_data, write_addr, $time);
        end
    end
`endif

endmodule
