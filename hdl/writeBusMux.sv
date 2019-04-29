
module writeBusMux
  #(
    parameter FFT_N = 10,
    parameter FFT_DW = 16,
    
    parameter MODE_INPUT_STREAM = 0,
    parameter MODE_RUN_FFT = 1,
    parameter MODE_DMA = 2,
    parameter MODE_DISABLE = 3
    )
  (
   input wire [1:0]            mode,

   // fft unit
   input wire                  wact_fft,
   input wire [FFT_N-1-1:0] wa_fft,
   input wire [FFT_DW*2-1:0] wdw_fft,

   // input stream
   input wire                  wact_istream,
   input wire [FFT_N-1-1:0] wa_istream,
   input wire [FFT_DW*2-1:0] wdw_istream,

   // memory bus
   output reg                  wact_ram,
   output reg [FFT_N-1-1:0] wa_ram,
   output reg [FFT_DW*2-1:0] wdw_ram
   
   );

   always_comb begin
      case ( mode )
        MODE_INPUT_STREAM:
          begin
             wact_ram = wact_istream;
             wa_ram = wa_istream;
             wdw_ram = wdw_istream;
          end

        MODE_RUN_FFT:
          begin
             wact_ram = wact_fft;
             wa_ram = wa_fft;
             wdw_ram = wdw_fft;
          end
          
        default:
          begin
             wact_ram = 1'b0;
             wa_ram = {FFT_N-1{1'b0}};
             wdw_ram = {FFT_DW*2{1'b0}};
          end
        
      endcase
   end
   
   

endmodule // ramWriteBusMux

