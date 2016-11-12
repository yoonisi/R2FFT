
/* 
 Configurable Radix-2 FFT Processor
 with Block Floating-Point
 **/

module R2FFT_tribuf
  #(
    parameter FFT_LENGTH = 1024, // FFT Frame Length, 2^N
    parameter FFT_DW = 16,       // Data Bitwidth
    parameter PL_DEPTH = 3,      // Pipeline Stage Depth Configuration (0 - 3)
    parameter FFT_N = $clog2( FFT_LENGTH ) // Don't override this
    )
   (
    // system
    input wire 			    clk,
    input wire 			    rst,

    // control
    input wire 			    run,
    input wire 			    ifft,
    
    // status
    output wire 		    done,
    output wire [2:0] 		    status,
    output wire 		    input_buffer_status,
    output wire signed [7:0] 	    bfpexp,

    // input stream
    input wire 			    sact_istream,
    input wire signed [FFT_DW-1:0]  sdw_istream_real,
    input wire signed [FFT_DW-1:0]  sdw_istream_imag,

    // output / DMA bus
    input wire 			    dmaact,
    input wire [FFT_N-1:0] 	    dmaa,
    output wire signed [FFT_DW-1:0] dmadr_real,
    output wire signed [FFT_DW-1:0] dmadr_imag,
    
    // twiddle factor rom
    output wire 		    twact,
    output wire [FFT_N-1-2:0] 	    twa,
    input wire [FFT_DW-1:0] 	    twdr_cos,
    
    // block ram0
    // bank0
    output wire 		    ract_ram0_bank0,
    output wire [FFT_N-1-1:0] 	    ra_ram0_bank0,
    input wire [FFT_DW*2-1:0] 	    rdr_ram0_bank0,
    // bank1
    output wire 		    wact_ram0_bank1,
    output wire [FFT_N-1-1:0] 	    wa_ram0_bank1,
    output wire [FFT_DW*2-1:0] 	    wdw_ram0_bank1,
    // bank2
    output wire 		    ract_ram0_bank2,
    output wire [FFT_N-1-1:0] 	    ra_ram0_bank2,
    input wire [FFT_DW*2-1:0] 	    rdr_ram0_bank2,
    // bank0
    output wire 		    wact_ram0_bank0,
    output wire [FFT_N-1-1:0] 	    wa_ram0_bank0,
    output wire [FFT_DW*2-1:0] 	    wdw_ram0_bank0,
    // bank1
    output wire 		    ract_ram0_bank1,
    output wire [FFT_N-1-1:0] 	    ra_ram0_bank1,
    input wire [FFT_DW*2-1:0] 	    rdr_ram0_bank1,
    // bank2
    output wire 		    wact_ram0_bank2,
    output wire [FFT_N-1-1:0] 	    wa_ram0_bank2,
    output wire [FFT_DW*2-1:0] 	    wdw_ram0_bank2,
   
    // block ram1
    // bank0
    output wire 		    ract_ram1_bank0,
    output wire [FFT_N-1-1:0] 	    ra_ram1_bank0,
    input wire [FFT_DW*2-1:0] 	    rdr_ram1_bank0,
    // bank1
    output wire 		    wact_ram1_bank1,
    output wire [FFT_N-1-1:0] 	    wa_ram1_bank1,
    output wire [FFT_DW*2-1:0] 	    wdw_ram1_bank1,
    // bank2
    output wire 		    ract_ram1_bank2,
    output wire [FFT_N-1-1:0] 	    ra_ram1_bank2,
    input wire [FFT_DW*2-1:0] 	    rdr_ram1_bank2,
    // bank0
    output wire 		    wact_ram1_bank0,
    output wire [FFT_N-1-1:0] 	    wa_ram1_bank0,
    output wire [FFT_DW*2-1:0] 	    wdw_ram1_bank0,
    // bank1
    output wire 		    ract_ram1_bank1,
    output wire [FFT_N-1-1:0] 	    ra_ram1_bank1,
    input wire [FFT_DW*2-1:0] 	    rdr_ram1_bank1,
    // bank2
    output wire 		    wact_ram1_bank2,
    output wire [FFT_N-1-1:0] 	    wa_ram1_bank2,
    output wire [FFT_DW*2-1:0] 	    wdw_ram1_bank2
   
    );

   localparam FFT_BFPDW = $clog2( FFT_DW ) + 1;
   
   // fft status
   typedef enum logic [2:0] {
                             ST_IDLE = 3'd0,
                             ST_RUN_FFT = 3'd3,
                             ST_DONE = 3'd4
                             } status_t;
   
   status_t status_f;
   status_t status_n;
   
   assign done = status_f[2];
   assign status = status_f;

   ////////////////////////////////////
   // triple buffer rotation control
   ////////////////////////////////////
   typedef enum logic [1:0] {
			     PHASE_0,
			     PHASE_1,
			     PHASE_2
			     } tribuf_status_t;
   tribuf_status_t tribuf_status;
   always @ ( posedge clk ) begin
      if ( rst ) begin
	 tribuf_status <= PHASE_0;
      end else if ( run ) begin
	 case ( tribuf_status )
	   PHASE_0: tribuf_status <= PHASE_1;
	   PHASE_1: tribuf_status <= PHASE_2;
	   PHASE_2: tribuf_status <= PHASE_0;
	 endcase // case ( tribuf_status )	 
      end
   end
   
   
   ///////////////////////////////
   // Input Buffer State Machine
   ///////////////////////////////
   wire 	streamBufferFull;
   typedef enum logic [1:0] {
			     IBUF_IDLE = 2'h0,
			     IBUF_INPUT_STREAM = 2'h1,
			     IBUF_FULL_BUFFER = 2'h2
			     } ibuf_status_t;
   ibuf_status_t ibuf_status_f;
   ibuf_status_t ibuf_status_n;
   always @ ( posedge clk ) begin
      if ( rst ) begin
	 ibuf_status_f <= IBUF_IDLE;
      end else begin
	 ibuf_status_f <= ibuf_status_n;
      end
   end

   always_comb begin
      case ( ibuf_status_f )
	IBUF_IDLE:           ibuf_status_n = IBUF_INPUT_STREAM;
	IBUF_INPUT_STREAM:
	  begin
	     if ( streamBufferFull ) begin
		ibuf_status_n = IBUF_FULL_BUFFER;
	     end
	  end
	IBUF_FULL_BUFFER:
	  begin
	     if ( run ) begin
		ibuf_status_n = IBUF_INPUT_STREAM;
	     end else begin
		ibuf_status_n = IBUF_FULL_BUFFER;
	     end
	  end
	default: ibuf_status_n = IBUF_IDLE;
      endcase // case ( ibuf_state_f )
   end
   
   
   ///////////////////////////////
   // Main State Machine
   ///////////////////////////////
   
   wire      fin_fft;
   
   always_comb begin
      case ( status_f )
        ST_IDLE:
          begin
	     if ( run ) begin
		status_n = ST_RUN_FFT;
	     end else begin
		status_n = ST_IDLE;
	     end
          end

        ST_RUN_FFT:
          begin
             if ( fin_fft ) begin
                status_n = ST_DONE;
             end else begin
                status_n = ST_RUN_FFT;
             end
          end

        ST_DONE:
          begin
             if ( run ) begin
                status_n = ST_RUN_FFT;
             end else begin
                status_n = ST_DONE;
             end
          end
        
        default:
          begin
             status_n = ST_IDLE;
          end
        
      endcase
   end

   always @ ( posedge clk ) begin
      if ( rst ) begin
         status_f <= ST_IDLE;
      end else begin
         status_f <= status_n;
      end
   end
   
   wire [FFT_N-1:0] istreamAddr;
   
   // input data iterator
   bitReverseCounter
     #(
       .BIT_WIDTH( FFT_N )
       )
     ubitReverseCounter
     (
      .rst( rst ),
      .clk( clk ),
      .clr( ibuf_status_f != IBUF_INPUT_STREAM ),
      .inc( sact_istream ),
      .iter( istreamAddr ),
      .count(),
      .countFull( streamBufferFull )
      );

   wire [FFT_BFPDW-1:0]  istreamBw;
   bfp_bitWidthDetector
     #(
       .FFT_BFPDW(FFT_BFPDW),
       .FFT_DW(FFT_DW)
       )
     uistreamBitWidthDetector
     (
      .operand0(sdw_istream_real),
      .operand1(sdw_istream_imag),
      .operand2({FFT_DW{1'b0}}),
      .operand3({FFT_DW{1'b0}}),
      .bw(istreamBw)
      );

   wire [FFT_BFPDW-1:0]  istreamMaxBw;
   reg [FFT_BFPDW-1:0] 	 istreamMaxBwFftUnit;
   bfp_maxBitWidth
     #(
       .FFT_BFPDW(FFT_BFPDW)
       )
     ubfp_maxBitWidthIstream
     (
      .rst( rst ),
      .clk( clk ),

      .clr( (ibuf_status_f == IBUF_IDLE) ||
	    run ),
      .bw_act( sact_istream && (ibuf_status_f == IBUF_INPUT_STREAM) ),
      .bw( istreamBw ),
      .max_bw( istreamMaxBw )
      
      );

   always @ ( posedge clk ) begin
      if ( rst ) begin
	 istreamMaxBwFftUnit <= 0;
      end else if ( run ) begin
	 istreamMaxBwFftUnit <= istreamMaxBw; // to next stage
      end
   end
   
   ///////////////////////
   // fft sub sequencer
   ///////////////////////
   wire        run_fft = ( status_f == ST_RUN_FFT );

   localparam MAX_FFT_STAGE = (FFT_N-1);

   typedef enum {
                 SB_IDLE,
                 SB_SETUP,
                 SB_RUN,
                 SB_WAIT_PIPELINE,
                 SB_NEXT_STAGE,
                 SB_DONE
                } sub_state_t;
   
   sub_state_t  sb_state_f;
   sub_state_t  sb_state_n;
       
   assign fin_fft = ( sb_state_f == SB_DONE );

   localparam STAGE_COUNT_BW = $clog2( FFT_N );
   
   reg [STAGE_COUNT_BW-1:0] fftStageCount;
   wire        fftStageCountFull = (fftStageCount == MAX_FFT_STAGE);
   
   wire [FFT_BFPDW-1:0]  currentBfpBw;
   wire [FFT_BFPDW-1:0]  nextBfpBw;
   wire        iteratorDone;
   wire        oactFftUnit;

   bfp_bitWidthAcc 
     #(
       .FFT_BFPDW( FFT_BFPDW ),
       .FFT_DW( FFT_DW )
       )
     ubfpacc
     (
      
      .clk( clk ),
      .rst( rst ),
      
      .init( sb_state_f == SB_SETUP ),
      .bw_init( istreamMaxBwFftUnit ),
      
      .update( (sb_state_f == SB_NEXT_STAGE) && !fftStageCountFull ),
      .bw_new( nextBfpBw ),
      
      .bfp_bw( currentBfpBw ),
      .bfp_exponent( bfpexp )
      
      );
   
   always_comb begin
      if ( !run_fft ) begin
         sb_state_n = SB_IDLE;
      end else begin
         case ( sb_state_f )
           SB_IDLE:  sb_state_n = SB_SETUP;
           SB_SETUP: sb_state_n = SB_RUN;

           SB_RUN:
             begin
                if ( iteratorDone ) begin
                   sb_state_n = SB_WAIT_PIPELINE;
                end else begin
                   sb_state_n = SB_RUN;
                end
             end

           SB_WAIT_PIPELINE:
             begin
                if ( oactFftUnit ) begin
                   sb_state_n = SB_WAIT_PIPELINE;
                end else begin
                   sb_state_n = SB_NEXT_STAGE;
                end
             end

           SB_NEXT_STAGE:
             begin
                if ( fftStageCountFull ) begin
                   sb_state_n = SB_DONE;
                end else begin
                   sb_state_n = SB_RUN;
                end
             end

           SB_DONE:
             begin
                sb_state_n = SB_DONE;
             end

           default: sb_state_n = SB_IDLE;
           
         endcase // case ( sb_state_f )
      end
   end

   always @ ( posedge clk ) begin
      if ( rst ) begin
         sb_state_f <= SB_IDLE;
      end else begin
         sb_state_f <= sb_state_n;
      end
   end

   always @ ( posedge clk ) begin
      if ( rst ) begin
         fftStageCount <= 0;
      end else begin
         case ( sb_state_f )
           SB_IDLE,SB_SETUP: fftStageCount <= 0;
           SB_NEXT_STAGE:    fftStageCount <= fftStageCount + 1;
         endcase // case ( sb_state_f )
      end
   end
      
   wire iactFftUnit;
   wire [1:0] ictrlFftUnit;
   wire       iEvenOdd;
   wire [FFT_N-1-1:0] MemAddr;
   wire [FFT_N-1-1:0] twiddleFactorAddr;
   
   fftAddressGenerator
     #(
       .FFT_N(FFT_N),
       .STAGE_COUNT_BW(STAGE_COUNT_BW)
       )
     ufftAddressGenerator
     (
      .clk( clk ),
      .rst( rst ),
      .stageCount( fftStageCount ),
      .run( sb_state_f == SB_RUN ),
      .done( iteratorDone ),

      .act( iactFftUnit ),
      .ctrl( ictrlFftUnit ),
      .evenOdd( iEvenOdd ),
      .MemAddr( MemAddr ),
      .twiddleFactorAddr( twiddleFactorAddr )
      
      );

   // block ram0
   wire       ract_fft0;
   wire [FFT_N-1-1:0] ra_fft0;
   wire [FFT_DW*2-1:0] rdr_fft0;
   
   wire        wact_fft0;
   wire [FFT_N-1-1:0]  wa_fft0;
   wire [FFT_DW*2-1:0] wdw_fft0;
   
   // block ram1
   wire        ract_fft1;
   wire [FFT_N-1-1:0]  ra_fft1;
   wire [FFT_DW*2-1:0] rdr_fft1;

   wire        wact_fft1;
   wire [FFT_N-1-1:0]  wa_fft1;
   wire [FFT_DW*2-1:0] wdw_fft1;
   
   butterflyUnit 
     #(
       .FFT_N(FFT_N),
       .FFT_DW(FFT_DW),
       .FFT_BFPDW(FFT_BFPDW),
       .PL_DEPTH(PL_DEPTH)
       )
   ubutterflyUnit
     (
      
      .clk( clk ),
      .rst( rst ),
      
      .clr_bfp( sb_state_f == SB_NEXT_STAGE ),
      
      .ibfp( currentBfpBw ),
      .obfp( nextBfpBw ),
      
      .iact( iactFftUnit ),
      .oact( oactFftUnit ),
      
      .ictrl( ictrlFftUnit ),
      .octrl( ),
      
      .MemAddr( MemAddr ),
      .twiddleFactorAddr( twiddleFactorAddr ),

      .evenOdd( iEvenOdd ),
      .ifft( ifft ),

      .twact( twact ),
      .twa( twa ),
      .twdr_cos( twdr_cos ),
      
      .ract_ram0( ract_fft0 ),
      .ra_ram0( ra_fft0 ),
      .rdr_ram0( rdr_fft0 ),
      
      .wact_ram0( wact_fft0 ),
      .wa_ram0( wa_fft0 ),
      .wdw_ram0( wdw_fft0 ),
      
      .ract_ram1( ract_fft1 ),
      .ra_ram1( ra_fft1 ),
      .rdr_ram1( rdr_fft1 ),
      
      .wact_ram1( wact_fft1 ),
      .wa_ram1( wa_fft1 ),
      .wdw_ram1( wdw_fft1 )
      
      );


   //////////////////////////
   // memory bus mux
   //////////////////////////
   localparam MODE_INPUT_STREAM = 0;
   localparam MODE_RUN_FFT = 1;
   localparam MODE_DMA = 2;
   localparam MODE_DISABLE = 3;
   
   reg         dmaa_lsb;
   always @ ( posedge clk ) begin
      dmaa_lsb <= dmaa[0];
   end

   wire [FFT_DW*2-1:0] rdr_dma0;

   readBusMux_tribuf
     #(
       .FFT_N(FFT_N),
       .FFT_DW(FFT_DW),
       .PHASE_0(PHASE_0),
       .PHASE_1(PHASE_1),
       .PHASE_2(PHASE_2),
       .MODE_INPUT_STREAM(MODE_INPUT_STREAM),
       .MODE_RUN_FFT(MODE_RUN_FFT),
       .MODE_DMA(MODE_DMA),
       .MODE_DISABLE(MODE_DISABLE)
       )
   readBusMuxEven
     (
      .tribuf_status(tribuf_status),
      .ract_fft(ract_fft0),
      .ra_fft(ra_fft0),
      .rdr_fft(rdr_fft0),
      
      .ract_dma(dmaact && (dmaa[0] == 1'b0)),
      .ra_dma(dmaa[FFT_N-1:1]),
      .rdr_dma(rdr_dma0),

      .ract_ram_bank0(ract_ram0_bank0),
      .ra_ram_bank0(ra_ram0_bank0),
      .rdr_ram_bank0(rdr_ram0_bank0),
      
      .ract_ram_bank1(ract_ram0_bank1),
      .ra_ram_bank1(ra_ram0_bank1),
      .rdr_ram_bank1(rdr_ram0_bank1),
      
      .ract_ram_bank2(ract_ram0_bank2),
      .ra_ram_bank2(ra_ram0_bank2),
      .rdr_ram_bank2(rdr_ram0_bank2)
      
      );
   
   
   wire [FFT_DW*2-1:0] rdr_dma1;
   readBusMux_tribuf
     #(
       .FFT_N(FFT_N),
       .FFT_DW(FFT_DW),
       .PHASE_0(PHASE_0),
       .PHASE_1(PHASE_1),
       .PHASE_2(PHASE_2),
       .MODE_INPUT_STREAM(MODE_INPUT_STREAM),
       .MODE_RUN_FFT(MODE_RUN_FFT),
       .MODE_DMA(MODE_DMA),
       .MODE_DISABLE(MODE_DISABLE)
       )
   readBusMuxOdd
     (
      .tribuf_status(tribuf_status),
      .ract_fft(ract_fft1),
      .ra_fft(ra_fft1),
      .rdr_fft(rdr_fft1),
      
      .ract_dma(dmaact && (dmaa[0] == 1'b1)),
      .ra_dma(dmaa[FFT_N-1:1]),
      .rdr_dma(rdr_dma1),

      .ract_ram_bank0(ract_ram1_bank0),
      .ra_ram_bank0(ra_ram1_bank0),
      .rdr_ram_bank0(rdr_ram1_bank0),
      
      .ract_ram_bank1(ract_ram1_bank1),
      .ra_ram_bank1(ra_ram1_bank1),
      .rdr_ram_bank1(rdr_ram1_bank1),
      
      .ract_ram_bank2(ract_ram1_bank2),
      .ra_ram_bank2(ra_ram1_bank2),
      .rdr_ram_bank2(rdr_ram1_bank2)
      
      );

   assign { dmadr_imag, dmadr_real } = (dmaa_lsb == 1'b0) ? rdr_dma0 : rdr_dma1;
   
   // write bus mux

   writeBusMux_tribuf
     #(
       .FFT_N(FFT_N),
       .FFT_DW(FFT_DW),
       .PHASE_0(PHASE_0),
       .PHASE_1(PHASE_1),
       .PHASE_2(PHASE_2),
       .MODE_INPUT_STREAM(MODE_INPUT_STREAM),
       .MODE_RUN_FFT(MODE_RUN_FFT),
       .MODE_DMA(MODE_DMA),
       .MODE_DISABLE(MODE_DISABLE)
       )
   writeBusMuxEven
     (
      .tribuf_status(tribuf_status),
      .wact_fft(wact_fft0),
      .wa_fft(wa_fft0),
      .wdw_fft(wdw_fft0),

      .wact_istream( sact_istream && (istreamAddr[0] == 1'b0) ),
      .wa_istream(istreamAddr[FFT_N-1:1]),
      .wdw_istream( { sdw_istream_imag, sdw_istream_real } ),

      .wact_ram_bank0( wact_ram0_bank0 ),
      .wa_ram_bank0( wa_ram0_bank0 ),
      .wdw_ram_bank0( wdw_ram0_bank0 ),
      
      .wact_ram_bank1( wact_ram0_bank1 ),
      .wa_ram_bank1( wa_ram0_bank1 ),
      .wdw_ram_bank1( wdw_ram0_bank1 ),
      
      .wact_ram_bank2( wact_ram0_bank2 ),
      .wa_ram_bank2( wa_ram0_bank2 ),
      .wdw_ram_bank2( wdw_ram0_bank2 )
      
      );
   

   writeBusMux_tribuf
     #(
       .FFT_N(FFT_N),
       .FFT_DW(FFT_DW),
       .PHASE_0(PHASE_0),
       .PHASE_1(PHASE_1),
       .PHASE_2(PHASE_2),
       .MODE_INPUT_STREAM(MODE_INPUT_STREAM),
       .MODE_RUN_FFT(MODE_RUN_FFT),
       .MODE_DMA(MODE_DMA),
       .MODE_DISABLE(MODE_DISABLE)
       )
   writeBusMuxOdd
     (
      .tribuf_status(tribuf_status),
      .wact_fft(wact_fft1),
      .wa_fft(wa_fft1),
      .wdw_fft(wdw_fft1),

      .wact_istream( sact_istream && (istreamAddr[0] == 1'b1) ),
      .wa_istream(istreamAddr[FFT_N-1:1]),
      .wdw_istream( { sdw_istream_imag, sdw_istream_real } ),

      .wact_ram_bank0( wact_ram1_bank0 ),
      .wa_ram_bank0( wa_ram1_bank0 ),
      .wdw_ram_bank0( wdw_ram1_bank0 ),
      
      .wact_ram_bank1( wact_ram1_bank1 ),
      .wa_ram_bank1( wa_ram1_bank1 ),
      .wdw_ram_bank1( wdw_ram1_bank1 ),
      
      .wact_ram_bank2( wact_ram1_bank2 ),
      .wa_ram_bank2( wa_ram1_bank2 ),
      .wdw_ram_bank2( wdw_ram1_bank2 )
      
      );
   
endmodule // R2FFT
