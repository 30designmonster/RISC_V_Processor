// Simple adder for PC calculations
// Author: Praveen Saravanan

`timescale 1ns/1ps

module adder #(
    parameter WIDTH = 32
)(
    input  logic [WIDTH-1:0] a,
    input  logic [WIDTH-1:0] b,
    output logic [WIDTH-1:0] sum
);

assign sum = a + b;

endmodule
