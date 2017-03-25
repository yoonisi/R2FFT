
module r2fft_tribuf_impl
  #(
    parameter FFT_LENGTH = 1024, // FFT Frame Length, 2^N
    parameter FFT_DW = 16,       // Data Bitwidth
    parameter PL_DEPTH = 3,      // Pipeline Stage Depth Configuration (0 - 3)
    parameter FFT_N = $clog2( FFT_LENGTH ) // Don't override this
    )
  (

   input wire 			   clk,
   input wire 			   rst_i,
   input wire 			   run_i,
   input wire 			   ifft_i,

   output wire 			   done_o,
   output wire [2:0] 		   status_o,
   output wire [1:0] 		   input_buffer_status_o,
   output wire signed [7:0] 	   bfpexp_o,

   // input stream
   input wire 			   sact_istream_i,
   input wire signed [FFT_DW-1:0]  sdw_istream_real_i,
   input wire signed [FFT_DW-1:0]  sdw_istream_imag_i,

    // output / DMA bus
   input wire 			   dmaact_i,
   input wire [FFT_N-1:0] 	   dmaa_i,
   output wire signed [FFT_DW-1:0] dmadr_real_o,
   output wire signed [FFT_DW-1:0] dmadr_imag_o
   
   );


   reg 				   rst; 
   reg 				   run;
   reg 				   ifft;
   
   always @ ( posedge clk ) begin
      rst <= rst_i;
      run <= run_i;
      ifft <= ifft_i;
   end

   wire done;
   wire [2:0] status;
   wire [1:0] input_buffer_status;
   wire signed [7:0] bfpexp;
   
   always @ ( posedge clk ) begin
      done_o <= done;
      status_o <= status;
      input_buffer_status_o <= input_buffer_status;
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
   wire 			   twact;
   wire [FFT_N-1-2:0] twa;
   wire [FFT_DW-1:0] 		   twdr_cos;
    
   // block ram0
   // bank0
   wire 			   ract_ram0_bank0;
   wire [FFT_N-1-1:0] 		   ra_ram0_bank0;
   wire [FFT_DW*2-1:0] 		   rdr_ram0_bank0;
   // bank1
   wire 			   wact_ram0_bank1;
   wire [FFT_N-1-1:0] 		   wa_ram0_bank1;
   wire [FFT_DW*2-1:0] 		   wdw_ram0_bank1;
   // bank2
   wire 			   ract_ram0_bank2;
   wire [FFT_N-1-1:0] 		   ra_ram0_bank2;
   wire [FFT_DW*2-1:0] 		   rdr_ram0_bank2;
   // bank0
   wire 			   wact_ram0_bank0;
   wire [FFT_N-1-1:0] 		   wa_ram0_bank0;
   wire [FFT_DW*2-1:0] 		   wdw_ram0_bank0;
   // bank1
   wire 			   ract_ram0_bank1;
   wire [FFT_N-1-1:0] 		   ra_ram0_bank1;
   wire [FFT_DW*2-1:0] 		   rdr_ram0_bank1;
   // bank2
   wire 			   wact_ram0_bank2;
   wire [FFT_N-1-1:0] 		   wa_ram0_bank2;
   wire [FFT_DW*2-1:0] 		   wdw_ram0_bank2;
   
   // block ram1
   // bank0
   wire 			   ract_ram1_bank0;
   wire [FFT_N-1-1:0] 		   ra_ram1_bank0;
   wire [FFT_DW*2-1:0] 		   rdr_ram1_bank0;
   // bank1
   wire 			   wact_ram1_bank1;
   wire [FFT_N-1-1:0] 		   wa_ram1_bank1;
   wire [FFT_DW*2-1:0] 		   wdw_ram1_bank1;
   // bank2
   wire 			   ract_ram1_bank2;
   wire [FFT_N-1-1:0] 		   ra_ram1_bank2;
   wire [FFT_DW*2-1:0] 		   rdr_ram1_bank2;
   // bank0
   wire 			   wact_ram1_bank0;
   wire [FFT_N-1-1:0] 		   wa_ram1_bank0;
   wire [FFT_DW*2-1:0] 		   wdw_ram1_bank0;
    // bank1
   wire 			   ract_ram1_bank1;
   wire [FFT_N-1-1:0] 		   ra_ram1_bank1;
   wire [FFT_DW*2-1:0] 		   rdr_ram1_bank1;
   // bank2
   wire 			   wact_ram1_bank2;
   wire [FFT_N-1-1:0] 		   wa_ram1_bank2;
   wire [FFT_DW*2-1:0] 		   wdw_ram1_bank2; 

   //
   R2FFT_tribuf
     #(
       .FFT_LENGTH(FFT_LENGTH),
       .FFT_DW(FFT_DW),
       .PL_DEPTH(PL_DEPTH)
       )
   uR2FFT_tribuf
     (
      .clk( clk ),
      .rst( rst ),

      .run( run ),
      .ifft( ifft ),

      .done( done ),
      .status( status ),
      .input_buffer_status( input_buffer_status ),
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

      ////////////////////////////////////
      .ract_ram0_bank0( ract_ram0_bank0 ),
      .ra_ram0_bank0( ra_ram0_bank0 ),
      .rdr_ram0_bank0( rdr_ram0_bank0 ),

      .wact_ram0_bank0( wact_ram0_bank0 ),
      .wa_ram0_bank0( wa_ram0_bank0 ),
      .wdw_ram0_bank0( wdw_ram0_bank0 ),

      .ract_ram1_bank0( ract_ram1_bank0 ),
      .ra_ram1_bank0( ra_ram1_bank0 ),
      .rdr_ram1_bank0( rdr_ram1_bank0 ),

      .wact_ram1_bank0( wact_ram1_bank0 ),
      .wa_ram1_bank0( wa_ram1_bank0 ),
      .wdw_ram1_bank0( wdw_ram1_bank0 ),      
      
      /////////////////////////////////////
      .ract_ram0_bank1( ract_ram0_bank1 ),
      .ra_ram0_bank1( ra_ram0_bank1 ),
      .rdr_ram0_bank1( rdr_ram0_bank1 ),

      .wact_ram0_bank1( wact_ram0_bank1 ),
      .wa_ram0_bank1( wa_ram0_bank1 ),
      .wdw_ram0_bank1( wdw_ram0_bank1 ),

      .ract_ram1_bank1( ract_ram1_bank1 ),
      .ra_ram1_bank1( ra_ram1_bank1 ),
      .rdr_ram1_bank1( rdr_ram1_bank1 ),

      .wact_ram1_bank1( wact_ram1_bank1 ),
      .wa_ram1_bank1( wa_ram1_bank1 ),
      .wdw_ram1_bank1( wdw_ram1_bank1 ),      

      /////////////////////////////////////
      .ract_ram0_bank2( ract_ram0_bank2 ),
      .ra_ram0_bank2( ra_ram0_bank2 ),
      .rdr_ram0_bank2( rdr_ram0_bank2 ),

      .wact_ram0_bank2( wact_ram0_bank2 ),
      .wa_ram0_bank2( wa_ram0_bank2 ),
      .wdw_ram0_bank2( wdw_ram0_bank2 ),

      .ract_ram1_bank2( ract_ram1_bank2 ),
      .ra_ram1_bank2( ra_ram1_bank2 ),
      .rdr_ram1_bank2( rdr_ram1_bank2 ),

      .wact_ram1_bank2( wact_ram1_bank2 ),
      .wa_ram1_bank2( wa_ram1_bank2 ),
      .wdw_ram1_bank2( wdw_ram1_bank2 )
      
      );

   /////////////////////////////////////////

   twrom utwrom
     (
      .address( twa ),
      .clock( clk ),
      .q( twdr_cos )
      );

   /////////////////////////////////////

   dpram ram0bank0
     (
      .clock( clk ),
      .data( wdw_ram0_bank0 ),
      .rdaddress( ra_ram0_bank0 ),
      .wraddress( wa_ram0_bank0 ),
      .wren( wact_ram0_bank0 ),
      .q( rdr_ram0_bank0 )
      );
   //////////////////

   dpram ram1bank0
     (
      .clock( clk ),
      .data( wdw_ram1_bank0 ),
      .rdaddress( ra_ram1_bank0 ),
      .wraddress( wa_ram1_bank0 ),
      .wren( wact_ram1_bank0 ),
      .q( rdr_ram1_bank0 )
      );
   //////////////////

   dpram ram0bank1
     (
      .clock( clk ),
      .data( wdw_ram0_bank1 ),
      .rdaddress( ra_ram0_bank1 ),
      .wraddress( wa_ram0_bank1 ),
      .wren( wact_ram0_bank1 ),
      .q( rdr_ram0_bank1 )
      );
   //////////////////

   dpram ram1bank1
     (
      .clock( clk ),
      .data( wdw_ram1_bank1 ),
      .rdaddress( ra_ram1_bank1 ),
      .wraddress( wa_ram1_bank1 ),
      .wren( wact_ram1_bank1 ),
      .q( rdr_ram1_bank1 )
      );
   //////////////////

   dpram ram0bank2
     (
      .clock( clk ),
      .data( wdw_ram0_bank2 ),
      .rdaddress( ra_ram0_bank2 ),
      .wraddress( wa_ram0_bank2 ),
      .wren( wact_ram0_bank2 ),
      .q( rdr_ram0_bank2 )
      );
   //////////////////

   dpram ram1bank2
     (
      .clock( clk ),
      .data( wdw_ram1_bank2 ),
      .rdaddress( ra_ram1_bank2 ),
      .wraddress( wa_ram1_bank2 ),
      .wren( wact_ram1_bank2 ),
      .q( rdr_ram1_bank2 )
      );
   //////////////////



   
endmodule // r2fft_tribuf_impl


