
module twrom
  #(
    parameter FFT_LENGTH = 1024,
    parameter FFT_DW = 16,
    parameter FFT_N = $clog2( FFT_LENGTH )
    )(

      input wire 	       clk,
      input wire 	       twact,
      input wire [FFT_N-1-2:0] twa,
      output wire [FFT_DW-1:0] twdr_cos
      
      );

   reg [FFT_N-1-2:0] 		 addr;
   always @ ( posedge clk ) begin
      if ( twact ) begin
	 addr <= twa;
      end
   end
   
   real mPi = 3.1415926535897932384626433832795029;
   reg [FFT_DW-1:0] cosValue;
   assign twdr_cos = cosValue;
   always_comb begin
      cosValue = (
		  $cos( 2.0 * mPi * addr / FFT_LENGTH) *
		  {1'b1,{FFT_DW-1{1'b0}}}
		  );
   end

endmodule // twrom


