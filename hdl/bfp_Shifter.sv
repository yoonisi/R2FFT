
module bfp_Shifter
  #(
    parameter FFT_DW = 16,
    parameter FFT_BFPDW =5
    )
  (
   input wire [FFT_DW-1:0]  operand,
   output wire [FFT_DW-1:0] bfp_operand, //shift to [0.5,1.0) or [-1.0,-0.5]
   input wire [FFT_BFPDW-1:0]  bw
   );

   reg [FFT_DW-1:0]            bfp_operand_r;
   assign bfp_operand = bfp_operand_r;

   always_comb begin
      if ( (bw == FFT_DW) ||    // -1.0 only
           (bw == FFT_DW-1 ) || // [1.0 - 0.5)
           (bw == 0 ) ) begin
         bfp_operand_r = operand;
      end else begin
         bfp_operand_r = operand << ((FFT_DW-1)-bw);
      end
   end
   
endmodule // bfp_Shifter

