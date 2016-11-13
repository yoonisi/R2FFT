
`timescale 1ns/1ps

`include "../include/dpram.sv"
`include "../include/twrom.sv"

module testbench;

   localparam FFT_LENGTH = 1024;
   localparam FFT_DW = 16;
   localparam PL_DEPTH = 2;
   localparam FFT_N = $clog2( FFT_LENGTH );   

`include "../include/header_tribuf.sv"
`include "../include/simtask.sv"



endmodule // testbench
