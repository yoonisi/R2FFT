   real M_PI = 3.1415926535897932384626433832795029;

   reg clk_reg = 1'b0;
   wire clk = clk_reg;

   reg 	rst_reg = 1'b1;
   wire rst = rst_reg;

   reg 	autorun_reg = 1'b0;
   wire autorun = autorun_reg;

   reg 	run_reg = 1'b0;
   wire run = run_reg;
   
   reg 	fin_reg = 1'b0;
   wire fin = fin_reg;

   reg 	ifft_reg = 1'b0;
   wire ifft = ifft_reg;

   reg 	done_reg = 1'bZ;
   wire done = done_reg;
   
   reg [2:0] status_reg = 3'bZZZ;
   wire [2:0] status = status_reg;

   reg signed [7:0] bfpexp_reg = 8'hZZ;
   wire signed [7:0] bfpexp = bfpexp_reg;

   reg 		     sact_istream_reg = 1'b0;
   wire 	     sact_istream = sact_istream_reg;

   reg signed [FFT_DW-1:0] sdw_istream_real_reg;
   wire signed [FFT_DW-1:0] sdw_istream_real = sdw_istream_real_reg;
   
   reg signed [FFT_DW-1:0]  sdw_istream_imag_reg;
   wire signed [FFT_DW-1:0] sdw_istream_imag = sdw_istream_imag_reg;

   reg 			    dmaact_reg = 1'b0;
   wire 		    dmaact = dmaact_reg;

   reg [FFT_N-1:0] 	    dmaa_reg = {FFT_N{1'b0}};
   wire [FFT_N-1:0] 	    dmaa = dmaa_reg;

   reg signed [FFT_DW-1:0]  dmadr_real_reg = {FFT_DW{1'bZ}};
   wire signed [FFT_DW-1:0] dmadr_real = dmadr_real_reg;

   reg signed [FFT_DW-1:0]  dmadr_imag_reg = {FFT_DW{1'bZ}};
   wire signed [FFT_DW-1:0] dmadr_imag = dmadr_imag_reg;

   // twiddle factor rom
   wire 		    twact;
   wire [FFT_N-1-2:0] 	    twa;
   wire [FFT_DW-1:0] 	    twdr_cos;
   
   // block ram0
   wire 		    ract_ram0;
   wire [FFT_N-1-1:0] 	    ra_ram0;
   wire [FFT_DW*2-1:0] 	    rdr_ram0;
   
   wire 		    wact_ram0;
   wire [FFT_N-1-1:0] 	    wa_ram0;
   wire [FFT_DW*2-1:0] 	    wdw_ram0;
   
   // block ram1
   wire 		    ract_ram1;
   wire [FFT_N-1-1:0] 	    ra_ram1;
   wire [FFT_DW*2-1:0] 	    rdr_ram1;
   
   wire 		    wact_ram1;
   wire [FFT_N-1-1:0] 	    wa_ram1;
   wire [FFT_DW*2-1:0] 	    wdw_ram1;
   
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

   twrom
     #(
       .FFT_LENGTH(FFT_LENGTH),
       .FFT_DW(FFT_DW)
       )
     utwrom
       (
	.clk( clk ),
	.twact( twact ),
	.twa( twa ),
	.twdr_cos( twdr_cos )
	);


   dpram
     #(
       .ADDR_WIDTH(FFT_N-1),
       .DATA_WIDTH(FFT_DW*2)
       )
   ram0
     (
      .clk( clk ),
      
      .ract( ract_ram0 ),
      .ra( ra_ram0 ),
      .rdr( rdr_ram0 ),

      .wact( wact_ram0 ),
      .wa( wa_ram0 ),
      .wdw( wdw_ram0 )
      
      );
   

   dpram
     #(
       .ADDR_WIDTH(FFT_N-1),
       .DATA_WIDTH(FFT_DW*2)
       )
   ram1
     (
      .clk( clk ),
      
      .ract( ract_ram1 ),
      .ra( ra_ram1 ),
      .rdr( rdr_ram1 ),

      .wact( wact_ram1 ),
      .wa( wa_ram1 ),
      .wdw( wdw_ram1 )
      
      );
