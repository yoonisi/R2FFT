
`timescale 1ns/1ps

`include "../include/dpram.sv"
`include "../include/twrom.sv"

module testbench;

   localparam FFT_LENGTH = 1024;
   localparam FFT_DW = 16;
   localparam PL_DEPTH = 1;
   localparam FFT_N = $clog2( FFT_LENGTH );   

`include "../include/header.sv"
`include "../include/simtask.sv"

   
   integer i;
   integer inputReal;
   integer inputImag;
   integer fftBfpExp;
   integer ifftBfpExp;
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
				 0.5 * $sin( 2 * M_PI * 30 * i / FFT_LENGTH ) +
				 0.4 * $cos( 2 * M_PI * 17 * i / FFT_LENGTH )
				 );
	 inputImag = ToSignedInt(
				 0.4 * ( i % 200 ) / 200.0 -
				 0.5 * ( i % 128 ) / 128.0
				 );
	 $display(",%d,%d,", inputReal, inputImag );
	 sdw_istream_real_reg <= inputReal;
	 sdw_istream_imag_reg <= inputImag;
	 wait_clk( 1 );
      end
      sact_istream_reg <= 1'b0;

      // start FFT
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
		   $sqrt( 1.0 * resultReal[i] * resultReal[i] + 1.0 * resultImag[i] * resultImag[i] ) * (2.0**(fftBfpExp))
		   );
      end

      fin_reg <= 1'b1;
      wait_clk( 1 );
      fin_reg <= 1'b0;
      ifft_reg <= 1'b1; // begin IFFT

      wait_clk( 1 );

      for ( i = 0; i < FFT_LENGTH; i++ ) begin
	 sact_istream_reg <= 1'b1;
	 sdw_istream_real_reg <= resultReal[i];
	 sdw_istream_imag_reg <= resultImag[i];
	 wait_clk( 1 );
      end
      sact_istream_reg <= 1'b0;
      
      while ( !done ) begin
	 wait_clk( 1 );
      end

      ifftBfpExp = bfpexp;
      dumpFromDmaBus();

      $display("");
      $display(",IFFT Result");
      $display(",real part, imag part," );
      for ( i = 0; i < FFT_LENGTH; i++ ) begin
	 $display( ",%f,%f,",
		   // result as unity gain.
		   resultReal[i] * (2.0**fftBfpExp) * ((2.0**ifftBfpExp)/FFT_LENGTH),
		   resultImag[i] * (2.0**fftBfpExp) * ((2.0**ifftBfpExp)/FFT_LENGTH)
		   );
      end

      
      $stop();
   end
      
   
endmodule // testbench



