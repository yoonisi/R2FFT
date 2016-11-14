
`timescale 1ns/1ps

`include "../include/dpram.sv"
`include "../include/twrom.sv"

module testbench;

   localparam FFT_LENGTH = 1024;
   localparam FFT_DW = 16;
   localparam PL_DEPTH = 3;
   localparam FFT_N = $clog2( FFT_LENGTH );   

`include "../include/header_tribuf.sv"
`include "../include/simtask.sv"

   task automatic inputSineWave
     ( 
       input real ampl,
       input real freq );
      integer i;
      begin
	 for ( i = 0; i < FFT_LENGTH; i++ ) begin
	    inputData( ampl * $sin( 2.0 * M_PI * freq * i / FFT_LENGTH ), 0 );
	    wait_clk( 2 );
	 end
      end
   endtask // inputSinWave

   task triggerRunFft;
      begin
	 run_reg <= 1'b1;
	 wait_clk( 1 );
	 run_reg <= 1'b0;
	 
      end
   endtask

   task automatic waitFftProcess;
      begin
	 while ( !done ) begin
	    wait_clk( 1 );
	 end
      end
   endtask // runFftProcess

   task automatic outputFftResult;
      integer i;
      reg signed [7:0] fftBfpExp;
      begin
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
      
      end
   endtask // outputFftResult
   
   
   integer i;
   integer frameCount = 0;
   initial begin
      rst_reg <= 1'b1;
      wait_clk( 10 );
      rst_reg <= 1'b0;
      wait_clk( 10 );

      // stage 
      inputSineWave( 0.5, 50 * frameCount++ + 10);

      // 
      triggerRunFft();
      fork
	 begin
	    inputSineWave( 0.5, 50 * frameCount++ + 10 );
	 end
	 begin
	    waitFftProcess();
	 end
      join

      //
      for ( i = 0; i < 5; i++ ) begin
	 triggerRunFft();
	 fork
	    begin
	       inputSineWave(0.5, 50 * frameCount++ + 10 );
	    end
	    begin
	       waitFftProcess();
	    end
	    begin
	       outputFftResult();
	    end
	 join
      end
      
      $stop();
   end


endmodule // testbench
