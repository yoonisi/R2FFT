
module writeBusMux_tribuf
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
   input wire [1:0] 	     tribuf_status,

   // fft unit
   input wire 		     wact_fft,
   input wire [FFT_N-1-1:0]  wa_fft,
   input wire [FFT_DW*2-1:0] wdw_fft,

   // input stream
   input wire 		     wact_istream,
   input wire [FFT_N-1-1:0]  wa_istream,
   input wire [FFT_DW*2-1:0] wdw_istream,

   // memory bus
   output reg 		     wact_ram_bank0,
   output reg [FFT_N-1-1:0]  wa_ram_bank0,
   output reg [FFT_DW*2-1:0] wdw_ram_bank0,
   
   output reg 		     wact_ram_bank1,
   output reg [FFT_N-1-1:0]  wa_ram_bank1,
   output reg [FFT_DW*2-1:0] wdw_ram_bank1,
   
   output reg 		     wact_ram_bank2,
   output reg [FFT_N-1-1:0]  wa_ram_bank2,
   output reg [FFT_DW*2-1:0] wdw_ram_bank2

   );

   // decode ram bank phase
   
   // ram0
   reg [1:0]  bank0_mode;
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

   // bank0 //////////////////
   writeBusMux
     #(
       .FFT_N(FFT_N),
       .FFT_DW(FFT_DW),
       .MODE_INPUT_STREAM(MODE_INPUT_STREAM),
       .MODE_RUN_FFT(MODE_RUN_FFT),
       .MODE_DMA(MODE_DMA),
       .MODE_DISABLE(MODE_DISABLE)
       )
   bank0mux
     (
      .mode(bank0_mode),
      .wact_fft(wact_fft),
      .wdw_fft(wdw_fft),
      .wact_istream(wact_istream),
      .wa_istream(wa_istream),
      .wdw_istream(wdw_istream),
      .wact_ram(wact_ram_bank0),
      .wa_ram(wa_ram0_bank0),
      .wdw_ram(wdw_ram0_bank0)
      );
   
   // bank1 //////////////////
   writeBusMux
     #(
       .FFT_N(FFT_N),
       .FFT_DW(FFT_DW),
       .MODE_INPUT_STREAM(MODE_INPUT_STREAM),
       .MODE_RUN_FFT(MODE_RUN_FFT),
       .MODE_DMA(MODE_DMA),
       .MODE_DISABLE(MODE_DISABLE)
       )
   bank1mux
     (
      .mode(bank1_mode),
      .wact_fft(wact_fft),
      .wdw_fft(wdw_fft),
      .wact_istream(wact_istream),
      .wa_istream(wa_istream),
      .wdw_istream(wdw_istream),
      .wact_ram(wact_ram_bank1),
      .wa_ram(wa_ram0_bank1),
      .wdw_ram(wdw_ram0_bank1)
      );

   // bank2 //////////////////
   writeBusMux
     #(
       .FFT_N(FFT_N),
       .FFT_DW(FFT_DW),
       .MODE_INPUT_STREAM(MODE_INPUT_STREAM),
       .MODE_RUN_FFT(MODE_RUN_FFT),
       .MODE_DMA(MODE_DMA),
       .MODE_DISABLE(MODE_DISABLE)
       )
   bank2mux
     (
      .mode(bank2_mode),
      .wact_fft(wact_fft),
      .wdw_fft(wdw_fft),
      .wact_istream(wact_istream),
      .wa_istream(wa_istream),
      .wdw_istream(wdw_istream),
      .wact_ram(wact_ram_bank2),
      .wa_ram(wa_ram0_bank2),
      .wdw_ram(wdw_ram0_bank2)
      );

endmodule // ramWriteBusMux

