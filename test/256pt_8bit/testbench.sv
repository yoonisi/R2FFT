
`timescale 1ns/1ps

`include "../include/dpram.sv"
`include "../include/twrom.sv"

module testbench;

   localparam FFT_LENGTH = 256;
   localparam FFT_DW = 8;
   localparam PL_DEPTH = 0;
   localparam FFT_N = $clog2( FFT_LENGTH );   

`include "../include/header.sv"
`include "../include/simtask.sv"

   
   integer i;
   integer inputReal;
   integer inputImag;
   integer fftBfpExp;
   initial begin
      rst_reg = 1;
      autorun_reg = 1;
      fin_reg = 0;
      run_reg = 0;
      ifft_reg = 0;
      wait_clk( 10 );
      rst_reg = 0;
      wait_clk( 10 );

      $display(",input data");
      $display(",real part, imag part,");

      for ( i = 0; i < FFT_LENGTH; i++ ) begin
	 sact_istream_reg <= 1'b1;
	 inputReal = ToSignedInt(
				 $sin ( 2.0 * M_PI * 8 *  i / FFT_LENGTH )
				 );
	 inputImag = 0;
	 $display(",%d,%d,", inputReal, inputImag );
	 sdw_istream_real_reg <= inputReal;
	 sdw_istream_imag_reg <= inputImag;
	 wait_clk( 1 );
      end // for ( i = 0; i < FFT_LENGTH; i++ )
      sact_istream_reg <= 1'b0;

      while ( !done ) begin
	 wait_clk( 1 );
      end

      fftBfpExp = bfpexp;
      dumpFromDmaBus();

      $display("");
      $display(",FFT Result");
      $display(",real part, imag part, ampl" );
      for ( i = 0; i < FFT_LENGTH; i++ ) begin
	 $display( ",%f,%f,%f", 
		   resultReal[i] * (2.0**(fftBfpExp)), 
		   resultImag[i] * (2.0**(fftBfpExp)),
		   $sqrt(
			 1.0 * resultReal[i] * resultReal[i] + 
			 1.0 * resultImag[i] * resultImag[i]
			 ) 
		   * (2.0**(fftBfpExp))
		   );
      end
      
      $stop();
   end
   
   
   
   
   
endmodule // testbench



