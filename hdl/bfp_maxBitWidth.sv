
module bfp_maxBitWidth
  #
  (
   parameter FFT_BFPDW = 5
   )
  (
   input wire        rst,
   input wire        clk,

   input wire        clr,
   
   input wire        bw_act,
   input wire [FFT_BFPDW-1:0]  bw,

   output wire [FFT_BFPDW-1:0] max_bw
   );

   reg [FFT_BFPDW-1:0]         max_bw_f;
   assign max_bw = max_bw_f;

   
   always @ ( posedge clk ) begin
      if ( rst ) begin
         max_bw_f <= 'h0;
      end else if ( clr ) begin
         max_bw_f <= 'h0;
      end else if ( bw_act ) begin
         if ( max_bw_f < bw ) begin
            max_bw_f <= bw;
         end
      end
   end // always @ ( posedge clk )
   
endmodule // bfp_bitWidthDetector


