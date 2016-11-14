   real M_PI = 3.1415926535897932384626433832795029;

   reg clk_reg = 1'b0;
   wire clk = clk_reg;

   reg 	rst_reg = 1'b1;
   wire rst = rst_reg;

   reg 	run_reg = 1'b0;
   wire run = run_reg;
   
   reg 	ifft_reg = 1'b0;
   wire ifft = ifft_reg;

   reg 	done_reg = 1'bZ;
   wire done = done_reg;
   
   reg [2:0] status_reg = 3'bZZZ;
   wire [2:0] status = status_reg;

   reg [1:0] input_buffer_status_reg = 2'bZZ;
   wire [1:0] input_buffer_status = input_buffer_status_reg;

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
   wire 		    ract_ram0_bank0;
   wire [FFT_N-1-1:0] 	    ra_ram0_bank0;
   wire [FFT_DW*2-1:0] 	    rdr_ram0_bank0;
   
   wire 		    wact_ram0_bank0;
   wire [FFT_N-1-1:0] 	    wa_ram0_bank0;
   wire [FFT_DW*2-1:0] 	    wdw_ram0_bank0;
   
   wire 		    ract_ram0_bank1;
   wire [FFT_N-1-1:0] 	    ra_ram0_bank1;
   wire [FFT_DW*2-1:0] 	    rdr_ram0_bank1;
   
   wire 		    wact_ram0_bank1;
   wire [FFT_N-1-1:0] 	    wa_ram0_bank1;
   wire [FFT_DW*2-1:0] 	    wdw_ram0_bank1;
   
   wire 		    ract_ram0_bank2;
   wire [FFT_N-1-1:0] 	    ra_ram0_bank2;
   wire [FFT_DW*2-1:0] 	    rdr_ram0_bank2;
   
   wire 		    wact_ram0_bank2;
   wire [FFT_N-1-1:0] 	    wa_ram0_bank2;
   wire [FFT_DW*2-1:0] 	    wdw_ram0_bank2;
   
   // block ram1
   wire 		    ract_ram1_bank0;
   wire [FFT_N-1-1:0] 	    ra_ram1_bank0;
   wire [FFT_DW*2-1:0] 	    rdr_ram1_bank0;
   
   wire 		    wact_ram1_bank0;
   wire [FFT_N-1-1:0] 	    wa_ram1_bank0;
   wire [FFT_DW*2-1:0] 	    wdw_ram1_bank0;
   
   wire 		    ract_ram1_bank1;
   wire [FFT_N-1-1:0] 	    ra_ram1_bank1;
   wire [FFT_DW*2-1:0] 	    rdr_ram1_bank1;
   
   wire 		    wact_ram1_bank1;
   wire [FFT_N-1-1:0] 	    wa_ram1_bank1;
   wire [FFT_DW*2-1:0] 	    wdw_ram1_bank1;
   
   wire 		    ract_ram1_bank2;
   wire [FFT_N-1-1:0] 	    ra_ram1_bank2;
   wire [FFT_DW*2-1:0] 	    rdr_ram1_bank2;
   
   wire 		    wact_ram1_bank2;
   wire [FFT_N-1-1:0] 	    wa_ram1_bank2;
   wire [FFT_DW*2-1:0] 	    wdw_ram1_bank2;
   

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
   ramEven_bank0
     (
      .clk( clk ),
      
      .ract( ract_ram0_bank0 ),
      .ra( ra_ram0_bank0 ),
      .rdr( rdr_ram0_bank0 ),

      .wact( wact_ram0_bank0 ),
      .wa( wa_ram0_bank0 ),
      .wdw( wdw_ram0_bank0 )
      
      );
   

   dpram
     #(
       .ADDR_WIDTH(FFT_N-1),
       .DATA_WIDTH(FFT_DW*2)
       )
   ramOdd_bank0
     (
      .clk( clk ),
      
      .ract( ract_ram1_bank0 ),
      .ra( ra_ram1_bank0 ),
      .rdr( rdr_ram1_bank0 ),

      .wact( wact_ram1_bank0 ),
      .wa( wa_ram1_bank0 ),
      .wdw( wdw_ram1_bank0 )
      
      );

   dpram
     #(
       .ADDR_WIDTH(FFT_N-1),
       .DATA_WIDTH(FFT_DW*2)
       )
   ramEven_bank1
     (
      .clk( clk ),
      
      .ract( ract_ram0_bank1 ),
      .ra( ra_ram0_bank1 ),
      .rdr( rdr_ram0_bank1 ),

      .wact( wact_ram0_bank1 ),
      .wa( wa_ram0_bank1 ),
      .wdw( wdw_ram0_bank1 )
      
      );
   

   dpram
     #(
       .ADDR_WIDTH(FFT_N-1),
       .DATA_WIDTH(FFT_DW*2)
       )
   ramOdd_bank1
     (
      .clk( clk ),
      
      .ract( ract_ram1_bank1 ),
      .ra( ra_ram1_bank1 ),
      .rdr( rdr_ram1_bank1 ),

      .wact( wact_ram1_bank1 ),
      .wa( wa_ram1_bank1 ),
      .wdw( wdw_ram1_bank1 )
      
      );

   dpram
     #(
       .ADDR_WIDTH(FFT_N-1),
       .DATA_WIDTH(FFT_DW*2)
       )
   ramEven_bank2
     (
      .clk( clk ),
      
      .ract( ract_ram0_bank2 ),
      .ra( ra_ram0_bank2 ),
      .rdr( rdr_ram0_bank2 ),

      .wact( wact_ram0_bank2 ),
      .wa( wa_ram0_bank2 ),
      .wdw( wdw_ram0_bank2 )
      
      );
   

   dpram
     #(
       .ADDR_WIDTH(FFT_N-1),
       .DATA_WIDTH(FFT_DW*2)
       )
   ramOdd_bank2
     (
      .clk( clk ),
      
      .ract( ract_ram1_bank2 ),
      .ra( ra_ram1_bank2 ),
      .rdr( rdr_ram1_bank2 ),

      .wact( wact_ram1_bank2 ),
      .wa( wa_ram1_bank2 ),
      .wdw( wdw_ram1_bank2 )
      
      );


