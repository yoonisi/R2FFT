
/* 
 Configurable Radix-2 FFT Processor
 with Block Floating-Point
 **/

module R2FFT
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
    input wire 			    autorun,
    input wire 			    run,
    input wire 			    fin,
    input wire 			    ifft,
    
    // status
    output wire 		    done,
    output wire [2:0] 		    status,
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
    output wire 		    ract_ram0,
    output wire [FFT_N-1-1:0] 	    ra_ram0,
    input wire [FFT_DW*2-1:0] 	    rdr_ram0,
   
    output wire 		    wact_ram0,
    output wire [FFT_N-1-1:0] 	    wa_ram0,
    output wire [FFT_DW*2-1:0] 	    wdw_ram0,
   
    // block ram1
    output wire 		    ract_ram1,
    output wire [FFT_N-1-1:0] 	    ra_ram1,
    input wire [FFT_DW*2-1:0] 	    rdr_ram1,

    output wire 		    wact_ram1,
    output wire [FFT_N-1-1:0] 	    wa_ram1,
    output wire [FFT_DW*2-1:0] 	    wdw_ram1
   
    );

   localparam FFT_BFPDW = $clog2( FFT_DW ) + 1;
   
   // fft status
   typedef enum logic [2:0] {
                             ST_IDLE = 3'd0,
                             ST_INPUT_STREAM = 3'd1,
                             ST_FULL_BUFFER = 3'd2,
                             ST_RUN_FFT = 3'd3,
                             ST_DONE = 3'd4
                             } status_t;
   
   status_t status_f;
   status_t status_n;
   
   assign done = status_f[2];
   assign status = status_f;
   
   ////////////////////////////////
   // Main State Machine
   ///////////////////////////////
   
   wire      fin_fft;
   wire      streamBufferFull;
   
   always_comb begin
      case ( status_f )
        ST_IDLE:
          begin
             status_n = ST_INPUT_STREAM;
          end
        
        ST_INPUT_STREAM:
          begin
             if ( streamBufferFull && sact_istream ) begin
                if ( autorun ) begin
                   status_n = ST_RUN_FFT;
                end else begin
                   status_n = ST_FULL_BUFFER;
                end
             end else begin
                status_n = ST_INPUT_STREAM;
             end
          end // case: ST_INPUT_STREAM

        ST_FULL_BUFFER:
          begin
             if ( run ) begin
                status_n = ST_RUN_FFT;
             end else begin
                status_n = ST_FULL_BUFFER;
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
             if ( fin ) begin
                status_n = ST_INPUT_STREAM;
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
   
   localparam MODE_INPUT_STREAM = 0;
   localparam MODE_RUN_FFT = 1;
   localparam MODE_DMA = 2;
   localparam MODE_DISABLE = 3;
   
   reg [1:0] ramAccessMode;
   always_comb begin
      case ( status_f )
        ST_INPUT_STREAM: ramAccessMode = MODE_INPUT_STREAM;
        ST_RUN_FFT:      ramAccessMode = MODE_RUN_FFT;
        ST_DONE:         ramAccessMode = MODE_DMA;
        default:         ramAccessMode = MODE_DISABLE;
      endcase
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
      .clr( status_f != ST_INPUT_STREAM ),
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
   bfp_maxBitWidth
     #(
       .FFT_BFPDW(FFT_BFPDW)
       )
     ubfp_maxBitWidthIstream
     (
      .rst( rst ),
      .clk( clk ),

      .clr( (status_f == ST_IDLE) ||
	    (status_f == ST_DONE) ),
      .bw_act( sact_istream && (status_f == ST_INPUT_STREAM) ),
      .bw( istreamBw ),
      .max_bw( istreamMaxBw )
      
      );
   
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
      .bw_init( istreamMaxBw ),
      
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

   reg         dmaa_lsb;
   always @ ( posedge clk ) begin
      dmaa_lsb <= dmaa[0];
   end

   wire [FFT_DW*2-1:0] rdr_dma0;
   readBusMux 
     #(
       .FFT_N(FFT_N),
       .FFT_DW(FFT_DW),
       .MODE_INPUT_STREAM(MODE_INPUT_STREAM),
       .MODE_RUN_FFT(MODE_RUN_FFT),
       .MODE_DMA(MODE_DMA),
       .MODE_DISABLE(MODE_DISABLE)
       )
     readBusMuxEven
     (
      .mode( ramAccessMode ),
      
      .ract_fft( ract_fft0 ),
      .ra_fft( ra_fft0 ),
      .rdr_fft( rdr_fft0 ),
      
      .ract_dma( dmaact && (dmaa[0] == 1'b0) ),
      .ra_dma( dmaa[FFT_N-1:1] ),
      .rdr_dma( rdr_dma0 ),

      .ract_ram( ract_ram0 ),
      .ra_ram( ra_ram0 ),
      .rdr_ram( rdr_ram0 )
      );

   wire [FFT_DW*2-1:0] rdr_dma1;
   readBusMux 
     #(
       .FFT_N(FFT_N),
       .FFT_DW(FFT_DW),
       .MODE_INPUT_STREAM(MODE_INPUT_STREAM),
       .MODE_RUN_FFT(MODE_RUN_FFT),
       .MODE_DMA(MODE_DMA),
       .MODE_DISABLE(MODE_DISABLE)
       )
   readBusMuxOdd
     (
      .mode( ramAccessMode ),

      .ract_fft( ract_fft1 ),
      .ra_fft( ra_fft1 ),
      .rdr_fft( rdr_fft1 ),

      .ract_dma( dmaact && (dmaa[0] == 1'b1) ),
      .ra_dma( dmaa[FFT_N-1:1] ),
      .rdr_dma( rdr_dma1 ),

      .ract_ram( ract_ram1 ),
      .ra_ram( ra_ram1 ),
      .rdr_ram( rdr_ram1 )
      );

   assign { dmadr_imag, dmadr_real } = (dmaa_lsb == 1'b0) ? rdr_dma0 : rdr_dma1;
   
   writeBusMux 
     #(
       .FFT_N(FFT_N),
       .FFT_DW(FFT_DW),
       .MODE_INPUT_STREAM(MODE_INPUT_STREAM),
       .MODE_RUN_FFT(MODE_RUN_FFT),
       .MODE_DMA(MODE_DMA),
       .MODE_DISABLE(MODE_DISABLE)
       )
   writeBusMuxEven
     (
      .mode( ramAccessMode ),

      .wact_fft( wact_fft0 ),
      .wa_fft( wa_fft0 ),
      .wdw_fft( wdw_fft0 ),

      .wact_istream( sact_istream && (istreamAddr[0] == 1'b0) ),
      .wa_istream( istreamAddr[FFT_N-1:1] ),
      .wdw_istream( { sdw_istream_imag, sdw_istream_real } ),

      .wact_ram( wact_ram0 ),
      .wa_ram( wa_ram0 ),
      .wdw_ram( wdw_ram0 )      
      );

   writeBusMux 
     #(
       .FFT_N(FFT_N),
       .FFT_DW(FFT_DW),
       .MODE_INPUT_STREAM(MODE_INPUT_STREAM),
       .MODE_RUN_FFT(MODE_RUN_FFT),
       .MODE_DMA(MODE_DMA),
       .MODE_DISABLE(MODE_DISABLE)
       )
     writeBusMuxOdd
     (
      .mode ( ramAccessMode ),

      .wact_fft( wact_fft1 ),
      .wa_fft( wa_fft1 ),
      .wdw_fft( wdw_fft1 ),

      .wact_istream( sact_istream && (istreamAddr[0] == 1'b1) ),
      .wa_istream( istreamAddr[FFT_N-1:1] ),
      .wdw_istream( { sdw_istream_imag, sdw_istream_real } ),

      .wact_ram( wact_ram1 ),
      .wa_ram( wa_ram1 ),
      .wdw_ram( wdw_ram1 )
      
      );
   
endmodule // R2FFT
