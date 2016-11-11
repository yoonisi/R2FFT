
module butterflyCore
  #(
    parameter FFT_N = 10,
    parameter FFT_DW = 16,
    parameter FFT_BFPDW = 5,
    parameter PL_DEPTH = 0
    )
  (
   input wire                 clk,
   input wire                 rst,

   input wire                 clr_bfp,
   input wire [FFT_BFPDW-1:0] ibfp,
//   output wire [FFT_BFPDW-1:0] obfp,
   output wire [FFT_BFPDW-1:0] bw_ramwrite,
   
   
   input wire                 iact,
   output wire                oact,

   input wire [1:0]           ictrl,
   output wire [1:0]          octrl,

   input wire [FFT_N-1-1:0]   iMemAddr,
   
   input wire [FFT_DW*2-1:0]  iEvenData,
   input wire [FFT_DW*2-1:0]  iOddData,

   output wire [FFT_N-1-1:0]  oMemAddr,
   output wire [FFT_DW*2-1:0] oEvenData,
   output wire [FFT_DW*2-1:0] oOddData,

   input wire [FFT_DW:0]      twiddle_real,
   input wire [FFT_DW:0]      twiddle_imag
   
   );
   

   wire [FFT_DW*2-1:0]                  iEvenDataBfp;
   wire [FFT_DW*2-1:0]                  iOddDataBfp;
   
   bfp_Shifter 
     #(
       .FFT_DW(FFT_DW),
       .FFT_BFPDW(FFT_BFPDW)
       )
     ushifter0
     ( 
       .operand( iEvenData[FFT_DW*2-1:FFT_DW*2/2] ), 
       .bfp_operand( iEvenDataBfp[FFT_DW*2-1:FFT_DW*2/2] ),
       .bw( ibfp )
       );
   
   bfp_Shifter
     #(
       .FFT_DW(FFT_DW),
       .FFT_BFPDW(FFT_BFPDW)
       )
     ushifter1
     (
      .operand( iEvenData[FFT_DW*2/2-1:0] ),
      .bfp_operand( iEvenDataBfp[FFT_DW*2/2-1:0] ),
      .bw( ibfp )
      );
   
   bfp_Shifter 
     #(
       .FFT_DW(FFT_DW),
       .FFT_BFPDW(FFT_BFPDW)
       )
   ushifter2
     (
      .operand( iOddData[FFT_DW*2-1:FFT_DW*2/2] ),
      .bfp_operand( iOddDataBfp[FFT_DW*2-1:FFT_DW*2/2] ),
      .bw( ibfp )
      );
   
   bfp_Shifter 
     #(
       .FFT_DW(FFT_DW),
       .FFT_BFPDW(FFT_BFPDW)
       )
   ushifter3
     (
      .operand( iOddData[FFT_DW*2/2-1:0] ),
      .bfp_operand( iOddDataBfp[FFT_DW*2/2-1:0] ),
      .bw( ibfp )
      );

   wire                         iact_calc;
   wire [1:0]                   ictrl_calc;

   wire                         oact_calc;
   wire [1:0]                   octrl_calc;
   
   wire [FFT_N-1-1:0]                  iMemAddrCalc;
   wire [FFT_N-1-1:0]                  oMemAddrCalc;

   wire [FFT_DW-1:0]                   opa_real;
   wire [FFT_DW-1:0]                   opa_imag;
   wire [FFT_DW-1:0]                   opb_real;
   wire [FFT_DW-1:0]                   opb_imag;
   
   ramPipelineBridge 
     #(
       .FFT_N(FFT_N),
       .FFT_DW(FFT_DW)
       )
     inputStagePipeline
     (
      .clk( clk ),
      .rst( rst ),
      
      .iact( iact ),
      .oact( iact_calc ),
      
      .ictrl( ictrl ),
      .octrl( ictrl_calc ),


      .iMemAddr( iMemAddr ),
      .iEvenData( iEvenDataBfp ),
      .iOddData( iOddDataBfp ),

      .oMemAddr( iMemAddrCalc ),
      .oEvenData( { opa_imag, opa_real } ),
      .oOddData(  { opb_imag, opb_real } )
      
      );

   wire [FFT_DW-1:0]                   dst_opa_real;
   wire [FFT_DW-1:0]                   dst_opa_imag;
   wire [FFT_DW-1:0]                   dst_opb_real;
   wire [FFT_DW-1:0]                   dst_opb_imag;

   radix2Butterfly
     #(
       .FFT_DW(FFT_DW),
       .FFT_N(FFT_N),
       .PL_DEPTH(PL_DEPTH)
       )
     uradix2bt
     (
      .clk( clk ),
      .rst( rst ),
      .iact(  iact_calc ),
      .ictrl( ictrl_calc ),

      .oact( oact_calc ),
      .octrl( octrl_calc ),

      .iMemAddr( iMemAddrCalc ),
      .oMemAddr( oMemAddrCalc ),
      
      .opa_real( opa_real ),
      .opa_imag( opa_imag ),
      .opb_real( opb_real ),
      .opb_imag( opb_imag ),
      
      .twiddle_real( twiddle_real ),
      .twiddle_imag( twiddle_imag ),
      
      .dst_opa_real( dst_opa_real ),
      .dst_opa_imag( dst_opa_imag ),
      .dst_opb_real( dst_opb_real ),
      .dst_opb_imag( dst_opb_imag )
      );

   
   ramPipelineBridge 
     #(
       .FFT_N(FFT_N),
       .FFT_DW(FFT_DW)
       )
   outputStagePipeline
     (
      .clk( clk ),
      .rst( rst ),

      .iact( oact_calc ),
      .oact( oact ),

      .ictrl( octrl_calc ),
      .octrl( octrl ),

      .iMemAddr( oMemAddrCalc ),
      .iEvenData( { dst_opa_imag, dst_opa_real } ),
      .iOddData( { dst_opb_imag, dst_opb_real } ),

      .oMemAddr( oMemAddr ),
      .oEvenData( oEvenData ),
      .oOddData( oOddData )      
      
      );

   bfp_bitWidthDetector 
     #(
       .FFT_BFPDW(FFT_BFPDW),
       .FFT_DW(FFT_DW)
       )
     ubfp_bitWidth
     (
      .operand0( oEvenData[FFT_DW*2-1:FFT_DW*2/2] ),
      .operand1( oEvenData[FFT_DW*2/2-1:0] ),
      .operand2( oOddData[FFT_DW*2-1:FFT_DW*2/2] ),
      .operand3( oOddData[FFT_DW*2/2-1:0] ),
      .bw( bw_ramwrite )
      );
   

endmodule // butterflyUnit


