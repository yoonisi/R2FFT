
module bfp_bitWidthDetector
  #(
    parameter FFT_BFPDW = 5,
    parameter FFT_DW = 16
    )
  (
   input wire [FFT_DW-1:0] operand0,
   input wire [FFT_DW-1:0] operand1,
   input wire [FFT_DW-1:0] operand2,
   input wire [FFT_DW-1:0] operand3,
   output wire [FFT_BFPDW-1:0] bw
   );

   reg [FFT_BFPDW-1:0]         bw_r;
   assign bw = bw_r;

   function [FFT_DW-1:0] ToAbsValue;
      input [FFT_DW-1:0]   operand;
      begin
         ToAbsValue = (operand[FFT_DW-1] == 1'b1) ?
                           (0 - operand[FFT_DW-1:0]) :
                           (operand[FFT_DW-1:0]);
      end
   endfunction
   
   wire [FFT_DW-1:0] operand_abs = 
               ToAbsValue( operand0 ) |
               ToAbsValue( operand1 ) |
               ToAbsValue( operand2 ) |
               ToAbsValue( operand3 );

   integer           i;
   always_comb begin
      bw_r = 0;
      for ( i = (FFT_DW-1); i >= 0; i-- ) begin
         if ( operand_abs[i] ) begin
            bw_r = i + 1;
            break; // generate priority logic
         end
      end
   end
   
endmodule // bfp_bitWidth

