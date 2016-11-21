
module r2fft_impl
  #(
    parameter FFT_LENGTH = 1024, // FFT Frame Length, 2^N
    parameter FFT_DW = 16,       // Data Bitwidth
    parameter PL_DEPTH = 3,      // Pipeline Stage Depth Configuration (0 - 3)
    parameter FFT_N = $clog2( FFT_LENGTH ) // Don't override this
    )
  (

   // system
   input wire 			  clk,
   input wire 			  rst_i,

    // control
   input wire 			  autorun_i,
   input wire 			  run_i,
   input wire 			  fin_i,
   input wire 			  ifft_i,
    
    // status
   output reg 			  done_o,
   output reg [2:0] 		  status_o,
   output reg signed [7:0] 	  bfpexp_o,

    // input stream
   input wire 			  sact_istream_i,
   input wire signed [FFT_DW-1:0] sdw_istream_real_i,
   input wire signed [FFT_DW-1:0] sdw_istream_imag_i,

    // output / DMA bus
   input wire 			  dmaact_i,
   input wire [FFT_N-1:0] 	  dmaa_i,
   output reg signed [FFT_DW-1:0] dmadr_real_o,
   output reg signed [FFT_DW-1:0] dmadr_imag_o
   
   );

   reg 				   rst;
 
   reg 				   autorun;
   reg 				   run;
   reg 				   fin;
   reg 				   ifft;

   always @ ( posedge clk ) begin
      rst <= rst_i;
      autorun <= autorun_i;
      run <= run_i;
      fin <= fin_i;
      ifft <= ifft_i;
   end
   
   // status
   wire 			   done;
   wire [2:0] 			   status;
   wire signed [7:0] 		   bfpexp;

   always @ ( posedge clk ) begin
      done_o <= done;
      status_o <= status;
      bfpexp_o <= bfpexp;
   end

   // input stream
   reg 			   sact_istream;
   reg signed [FFT_DW-1:0] sdw_istream_real;
   reg signed [FFT_DW-1:0] sdw_istream_imag;

    // output / DMA bus
   reg 			   dmaact;
   reg [FFT_N-1:0] 	   dmaa;
   wire signed [FFT_DW-1:0] dmadr_real;
   wire signed [FFT_DW-1:0] dmadr_imag;

   always @ ( posedge clk ) begin
      sact_istream <= sact_istream_i;
      sdw_istream_real <= sdw_istream_real_i;
      sdw_istream_imag <= sdw_istream_imag_i;
      dmaact <= dmaact_i;
      dmaa <= dmaa_i;
   end

   always @ ( posedge clk ) begin
      dmadr_real_o <= dmadr_real;
      dmadr_imag_o <= dmadr_imag;
   end
   
   // twiddle factor rom
   reg 			   twact;
   reg [FFT_N-1-2:0] 	   twa;
   reg [FFT_DW-1:0] 	   twdr_cos;
   
   // block ram0
   reg 			   ract_ram0;
   reg [FFT_N-1-1:0] 	   ra_ram0;
   wire [FFT_DW*2-1:0] 	   rdr_ram0;
   
   reg 			   wact_ram0;
   reg [FFT_N-1-1:0] 	   wa_ram0;
   reg [FFT_DW*2-1:0] 	   wdw_ram0;
   
   // block ram1
   reg 			   ract_ram1;
   reg [FFT_N-1-1:0] 	   ra_ram1;
   wire [FFT_DW*2-1:0] 	   rdr_ram1;
   
   reg 			   wact_ram1;
   reg [FFT_N-1-1:0] 	   wa_ram1;
   reg [FFT_DW*2-1:0] 	   wdw_ram1;
      

   R2FFT
     #(
       .FFT_LENGTH(FFT_LENGTH),
       .FFT_DW(FFT_DW),
       .PL_DEPTH(PL_DEPTH)
       )
   uR2FFT
     (
      .clk( clk ),
      .rst( rst ),
      
      .autorun( autorun ),
      .run( run ),
      .fin( fin ),
      .ifft( ifft ),
      
      .done( done ),
      .status( status ),
      .bfpexp( bfpexp ),

      .sact_istream( sact_istream ),
      .sdw_istream_real( sdw_istream_real ),
      .sdw_istream_imag( sdw_istream_imag ),

      .dmaact( dmaact ),
      .dmaa( dmaa ),
      .dmadr_real( dmadr_real ),
      .dmadr_imag( dmadr_imag ),

      .twact( twact ),
      .twa( twa ),
      .twdr_cos( twdr_cos ),

      .ract_ram0( ract_ram0 ),
      .ra_ram0( ra_ram0 ),
      .rdr_ram0( rdr_ram0 ),

      .wact_ram0( wact_ram0 ),
      .wa_ram0( wa_ram0 ),
      .wdw_ram0( wdw_ram0 ),

      .ract_ram1( ract_ram1 ),
      .ra_ram1( ra_ram1 ),
      .rdr_ram1( rdr_ram1 ),

      .wact_ram1( wact_ram1 ),
      .wa_ram1( wa_ram1 ),
      .wdw_ram1( wdw_ram1 )
      
      );

   twrom utwrom
     (
      .address( twa ),
      .clock( clk ),
      .q( twdr_cos )
      );

   dpram ram0
     (
      .clock( clk ),
      .data( wdw_ram0 ),
      .rdaddress( ra_ram0 ),
      .wraddress( wa_ram0 ),
      .q( rdr_ram0 )
      );

   dpram ram1
     (
      .clock( clk ),
      .data( wdw_ram1 ),
      .rdaddress( ra_ram1 ),
      .wraddress( wa_ram1 ),
      .q( rdr_ram1 )
      );
   
endmodule // r2fft_impl

