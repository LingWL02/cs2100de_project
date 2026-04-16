`timescale 1ns / 1ps

module PipelineReg
#(
    parameter WIDTH = 32,
)
(
    input wire clk,
    input wire rst,
    input wire stall,
    input wire flush,
    input wire [WIDTH-1:0] in_data,
    output reg [WIDTH-1:0] out_data
);

    always @(posedge clk)
    begin
        if (rst | flush)
            out_data <= '0;

        else if (~stall)
            out_data <= in_data;
    end

endmodule
