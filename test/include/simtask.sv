
   
   real 		    clk_period = 10;
   real 		    clk_strobe = 9;
   event 		    strobe;
   
   always begin
      clk_reg = 1'b1;
      #(clk_period/2);
      clk_reg = 1'b0;
      #(clk_period/2);
   end

   task automatic wait_clk;
      input integer cnt;
      integer 	    i;
      begin
	 for ( i = 0; i < cnt; i++ ) begin
	    @ ( posedge clk );
	    #1;
	 end
      end
   endtask
   
   always @ ( posedge clk ) begin
      #(clk_strobe);
      ->strobe;
   end


   function signed [FFT_DW-1:0] ToSignedInt;
      input real inputValue;
      reg [FFT_DW-1:0] fullScale;
      real 	       scaledInput;
      real 	       fullScaleDouble;
      begin
	 if ( inputValue >= 1.0 ) begin
	    inputValue = 1.0;
	 end else if ( inputValue <= -1.0 ) begin
	    inputValue = -1.0;
	 end
	 fullScale = {1'b1,{FFT_DW-1{1'b0}}};
	 fullScaleDouble = fullScale;
	 scaledInput = $floor(inputValue * fullScaleDouble);
	 
	 if ( scaledInput >= fullScaleDouble ) begin
	    ToSignedInt = {1'b0,{FFT_DW-1{1'b1}}};
      end else begin
	    ToSignedInt = scaledInput;
	 end
      end
   endfunction //

   task automatic inputData;
      input real inputReal;
      input real inputImag;
      begin
	 sact_istream_reg <= 1'b1;
	 sdw_istream_real_reg <= ToSignedInt( inputReal );
	 sdw_istream_imag_reg <= ToSignedInt( inputImag );
	 wait_clk(1);
	 sact_istream_reg <= 1'b0;
      end
   endtask //

   event strobeOutputData;
   task automatic dumpFromDmaBus (
				  input integer waitCount = 0
				  );
      integer i;
      begin
	 for ( i = 0; i < FFT_LENGTH; i++ ) begin
	    dmaact_reg <= 1'b1;
	    dmaa_reg <= i;
	    wait_clk(1);
	    dmaact_reg <= 1'b0;
	    wait_clk( waitCount );
	    -> strobeOutputData;
	 end
	 dmaact_reg <= 1'b0;
	 wait_clk(1);
      end
   endtask //

   integer fftbin;
   always @ ( posedge clk ) begin
      fftbin <= dmaa_reg;
   end

   reg signed [FFT_DW-1:0] resultReal[0:FFT_LENGTH-1];
   reg signed [FFT_DW-1:0] resultImag[0:FFT_LENGTH-1];
   
   always @ ( strobeOutputData ) begin
      @ ( strobe );
      resultReal[fftbin] = dmadr_real;
      resultImag[fftbin] = dmadr_imag;
   end


