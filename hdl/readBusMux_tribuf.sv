
module readBusMux_tribuf
  #(
    parameter FFT_N = 10,
    parameter FFT_DW = 16,

    parameter PHASE_0 = 0,
    parameter PHASE_1 = 1,
    parameter PHASE_2 = 2,
    
    parameter MODE_INPUT_STREAM = 0,
    parameter MODE_RUN_FFT = 1,
    parameter MODE_DMA = 2,
    parameter MODE_DISABLE = 3
    )
   (
    input wire [1:0] 	       tribuf_status,

    // fft units
    input wire 		       ract_fft,
    input wire [FFT_N-1-1:0]   ra_fft,
    output wire [FFT_DW*2-1:0] rdr_fft,

    // DMA
    input wire 		       ract_dma,
    input wire [FFT_N-1-1:0]   ra_dma,
    output wire [FFT_DW*2-1:0] rdr_dma,

    // memory bus
    output reg 		       ract_ram_bank0,
    output reg [FFT_N-1-1:0]   ra_ram_bank0,
    input wire [FFT_DW*2-1:0]  rdr_ram_bank0,
    
    output reg 		       ract_ram_bank1,
    output reg [FFT_N-1-1:0]   ra_ram_bank1,
    input wire [FFT_DW*2-1:0]  rdr_ram_bank1,
    
    output reg 		       ract_ram_bank2,
    output reg [FFT_N-1-1:0]   ra_ram_bank2,
    input wire [FFT_DW*2-1:0]  rdr_ram_bank2
    
    );

   // decode ram bank phase

   // ram0
   reg [1:0] bank0_mode;
   always_comb begin
      case ( tribuf_status )
	PHASE_0:  bank0_mode = MODE_INPUT_STREAM;
	PHASE_1:  bank0_mode = MODE_RUN_FFT;
	PHASE_2:  bank0_mode = MODE_DMA;
	default:  bank0_mode = MODE_DISABLE;
      endcase // case ( tribuf_status )
   end

   reg [1:0] bank1_mode;
   always_comb begin
      case ( tribuf_status )
	PHASE_0:  bank1_mode = MODE_RUN_FFT;
	PHASE_1:  bank1_mode = MODE_DMA;
	PHASE_2:  bank1_mode = MODE_INPUT_STREAM;
	default:  bank1_mode = MODE_DISABLE;
      endcase
   end

   reg [1:0] bank2_mode;
   always_comb begin
      case ( tribuf_status )
	PHASE_0:  bank2_mode = MODE_DMA;
	PHASE_1:  bank2_mode = MODE_INPUT_STREAM;
	PHASE_2:  bank2_mode = MODE_RUN_FFT;
	default:  bank2_mode = MODE_DISABLE;
      endcase
   end

   // bank0 ////////////////////////////////
   wire [FFT_DW*2-1:0] rdr_fft_bank0;
   wire [FFT_DW*2-1:0] rdr_dma_bank0;
   readBusMux 
     #(
       .FFT_N(FFT_N),
       .FFT_DW(FFT_DW),
       .MODE_INPUT_STREAM(MODE_INPUT_STREAM),
       .MODE_RUN_FFT(MODE_RUN_FFT),
       .MODE_DMA(MODE_DMA),
       .MODE_DISABLE(MODE_DISABLE)
       )
     bank0Mux
     (
      .mode(bank0_mode),

      .ract_fft(ract_fft),
      .ra_fft(ra_fft),
      .rdr_fft(rdr_fft_bank0),

      .ract_dma(ract_dma),
      .ra_dma(ra_dma),
      .rdr_dma(rdr_dma_bank0),

      .ract_ram(ract_ram_bank0),
      .ra_ram(ra_ram_bank0),
      .rdr_ram(rdr_ram_bank0)
      
      );

   // bank1 ////////////////////////////////
   wire [FFT_DW*2-1:0] rdr_fft_bank1;
   wire [FFT_DW*2-1:0] rdr_dma_bank1;
   readBusMux 
     #(
       .FFT_N(FFT_N),
       .FFT_DW(FFT_DW),
       .MODE_INPUT_STREAM(MODE_INPUT_STREAM),
       .MODE_RUN_FFT(MODE_RUN_FFT),
       .MODE_DMA(MODE_DMA),
       .MODE_DISABLE(MODE_DISABLE)
       )
     bank1Mux
     (
      .mode(bank1_mode),

      .ract_fft(ract_fft),
      .ra_fft(ra_fft),
      .rdr_fft(rdr_fft_bank1),

      .ract_dma(ract_dma),
      .ra_dma(ra_dma),
      .rdr_dma(rdr_dma_bank1),

      .ract_ram(ract_ram_bank1),
      .ra_ram(ra_ram_bank1),
      .rdr_ram(rdr_ram_bank1)
      
      );

   // bank2 ////////////////////////////////
   wire [FFT_DW*2-1:0] rdr_fft_bank2;
   wire [FFT_DW*2-1:0] rdr_dma_bank2;
   readBusMux 
     #(
       .FFT_N(FFT_N),
       .FFT_DW(FFT_DW),
       .MODE_INPUT_STREAM(MODE_INPUT_STREAM),
       .MODE_RUN_FFT(MODE_RUN_FFT),
       .MODE_DMA(MODE_DMA),
       .MODE_DISABLE(MODE_DISABLE)
       )
     bank2Mux
     (
      .mode(bank2_mode),

      .ract_fft(ract_fft),
      .ra_fft(ra_fft),
      .rdr_fft(rdr_fft_bank2),

      .ract_dma(ract_dma),
      .ra_dma(ra_dma),
      .rdr_dma(rdr_dma_bank2),

      .ract_ram(ract_ram_bank2),
      .ra_ram(ra_ram_bank2),
      .rdr_ram(rdr_ram_bank2)
      
      );

   ////////////////////////////////////
   assign rdr_fft = ((bank0_mode == MODE_RUN_FFT) ? rdr_fft_bank0 : {FFT_DW*2{1'b0}} )|
		    ((bank1_mode == MODE_RUN_FFT) ? rdr_fft_bank1 : {FFT_DW*2{1'b0}} )|
		    ((bank2_mode == MODE_RUN_FFT) ? rdr_fft_bank2 : {FFT_DW*2{1'b0}} );

   ////////////////////////////////////
   assign rdr_dma = ((bank0_mode == MODE_DMA) ? rdr_dma_bank0 : {FFT_DW*2{1'b0}} )|
		    ((bank1_mode == MODE_DMA) ? rdr_dma_bank1 : {FFT_DW*2{1'b0}} )|
		    ((bank2_mode == MODE_DMA) ? rdr_dma_bank2 : {FFT_DW*2{1'b0}} );
   
endmodule // ramReadbusMux

