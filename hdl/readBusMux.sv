
module readBusMux
  #(
    parameter FFT_N = 10,
    parameter FFT_DW = 16,
    
    parameter MODE_INPUT_STREAM = 0,
    parameter MODE_RUN_FFT = 1,
    parameter MODE_DMA = 2,
    parameter MODE_DISABLE = 3
    )
   (
    input wire [1:0]             mode,

    // fft units
    input wire                   ract_fft,
    input wire [FFT_N-1-1:0]  ra_fft,
    output wire [FFT_DW*2-1:0] rdr_fft,

    // DMA
    input wire                   ract_dma,
    input wire [FFT_N-1-1:0]  ra_dma,
    output wire [FFT_DW*2-1:0] rdr_dma,

    // memory bus
    output reg                   ract_ram,
    output reg [FFT_N-1-1:0]  ra_ram,
    input wire [FFT_DW*2-1:0]  rdr_ram
    
    );

   assign rdr_fft = rdr_ram;
   assign rdr_dma = rdr_ram;
   
   always_comb begin
      case ( mode )
        MODE_RUN_FFT:
          begin
             ract_ram = ract_fft;
             ra_ram = ra_fft;
          end
        MODE_DMA:
          begin
             ract_ram = ract_dma;
             ra_ram = ra_dma;
          end
        default:
          begin
             ract_ram = 1'b0;
             ra_ram = {FFT_N-1{1'b0}};
          end
      endcase
   end 

   
   
endmodule // ramReadbusMux

