
module butterflyUnit
  #(
    parameter FFT_N = 10,
    parameter FFT_DW = 16,
    parameter FFT_BFPDW = 5,
    parameter PL_DEPTH = 0
    )
  (
   input wire                  clk,
   input wire                  rst,

   input wire                  clr_bfp,
   input wire [FFT_BFPDW-1:0]  ibfp,
   output wire [FFT_BFPDW-1:0] obfp,
   
   input wire                  iact,
   output reg                  oact,

   input wire [1:0]            ictrl,
   output reg [1:0]            octrl,

   // from FFT Index generator
   input wire [FFT_N-1-1:0]    MemAddr,
   input wire [FFT_N-1-1:0]    twiddleFactorAddr,

   input wire                  evenOdd,
   input wire                  ifft,

   // twiddle rom
   output wire                 twact,
   output wire [FFT_N-1-2:0]   twa,
   input wire [FFT_DW-1:0]   twdr_cos,
   
   // block ram0 32-bit x 512 words
   output wire                 ract_ram0,
   output wire [FFT_N-1-1:0]   ra_ram0,
   input wire [FFT_DW*2-1:0]   rdr_ram0,
   
   output reg                  wact_ram0,
   output reg [FFT_N-1-1:0]    wa_ram0,
   output reg [FFT_DW*2-1:0]   wdw_ram0,
   
   // block ram1 32-bit x 512 words
   output wire                 ract_ram1,
   output wire [FFT_N-1-1:0]   ra_ram1,
   input wire [FFT_DW*2-1:0]   rdr_ram1,
   
   output reg                  wact_ram1,
   output reg [FFT_N-1-1:0]    wa_ram1,
   output reg [FFT_DW*2-1:0]   wdw_ram1
   
   );

   wire [FFT_DW:0]    tdr_rom_real;
   wire [FFT_DW:0]    tdr_rom_imag;

   // Twiddle Factor ROM Access
   twiddleFactorRomBridge 
     #(
       .FFT_N(FFT_N),
       .FFT_DW(FFT_DW)
       )
     utwiddleFactorRomBridge
     (
      .clk( clk ),
      .rst( rst ),

      .tact_rom( iact ),
      .evenOdd( evenOdd ),
      .ifft( ifft ),
      
      .ta_rom( twiddleFactorAddr ),
      .tdr_rom_real( tdr_rom_real ),
      .tdr_rom_imag( tdr_rom_imag ),

      // rom port
      .twact( twact ),
      .twa( twa ),
      .twdr_cos( twdr_cos )
      
      );
   
     
   // SRAM Read Access
   assign ract_ram0 = iact;
   assign ra_ram0 = MemAddr;

   assign ract_ram1 = iact;
   assign ra_ram1 = MemAddr;

   wire [FFT_DW*2-1:0]       iEvenData = rdr_ram0;
   wire [FFT_DW*2-1:0]       iOddData = rdr_ram1;
   
   reg                         act;
   reg [1:0]                   ctrl;
   reg [FFT_N-1-1:0]        iMemAddr;

   always @ ( posedge clk ) begin
      if ( rst ) begin
         act <= 1'b0;
         ctrl <= 2'h0;
      end else begin
         act <= iact;
         ctrl <= ictrl;
      end
   end // always @ ( posedge clk )

   always @ ( posedge clk ) begin
         iMemAddr <= MemAddr;
   end
   
   // twiddle factor rom access
   reg [FFT_DW:0]                   twiddle_real;
   reg [FFT_DW:0]                   twiddle_imag;

   always_comb begin
      twiddle_real = tdr_rom_real;
      twiddle_imag = tdr_rom_imag;
   end

   wire [FFT_N-1-1:0] oMemAddr;
   wire [FFT_DW*2-1:0] oEvenData;
   wire [FFT_DW*2-1:0] oOddData;

   wire                oactCore;
   wire [1:0]          octrlCore;
   
   wire [FFT_BFPDW-1:0] bw_ramwrite;
   
   butterflyCore 
     #(
       .FFT_N(FFT_N),
       .FFT_DW(FFT_DW),
       .FFT_BFPDW(FFT_BFPDW),
       .PL_DEPTH(PL_DEPTH)
       )
   ubutterflyCore
     (
      .clk( clk ),
      .rst( rst ),
      .clr_bfp( clr_bfp ),
      .bw_ramwrite( bw_ramwrite ),
      
      .ibfp( ibfp ),
      
      .iact( act ),
      .ictrl( ctrl ),

      .oact( oactCore ),
      .octrl( octrlCore ),
      
      .iMemAddr( iMemAddr ),
      .iEvenData( iEvenData ),
      .iOddData( iOddData ),
      
      .oMemAddr( oMemAddr ),
      .oEvenData( oEvenData ),
      .oOddData( oOddData ),
      
      .twiddle_real( twiddle_real ),
      .twiddle_imag( twiddle_imag )
      );

   reg [FFT_BFPDW-1:0]  bw_ramwrite_dly;


   generate if ( PL_DEPTH >= 3 ) begin
   
      always @ ( posedge clk ) begin
         oact <= rst ? 1'b0 : oactCore;
         octrl <= octrlCore;
         
         wact_ram0 <= oactCore;
         wa_ram0 <= oMemAddr;
         wdw_ram0 <= oEvenData;
         
         wact_ram1 <= oactCore;
         wa_ram1 <= oMemAddr;
         wdw_ram1 <= oOddData;
         
         bw_ramwrite_dly <= bw_ramwrite;
      end // always @ ( posedge clk )

   end else begin

      always_comb begin
         oact = oactCore;
         octrl = octrlCore;   
         wact_ram0 = oactCore;
         wa_ram0 = oMemAddr;
         wdw_ram0 = oEvenData;
         
         wact_ram1 = oactCore;
         wa_ram1 = oMemAddr;
         wdw_ram1 = oOddData;
         
         bw_ramwrite_dly = bw_ramwrite;
      end // always @ ( posedge clk )
      
   end endgenerate // else: !if( PL_DEPTH >= 3 )
   

   bfp_maxBitWidth 
     #(
       .FFT_BFPDW(FFT_BFPDW)
       )
     ubfp_maxBitWidth
     (
      .clk( clk ),
      .rst( rst ),
      
      .clr( clr_bfp ),
      .bw_act( oact ),
      .bw( bw_ramwrite_dly ),
      .max_bw( obfp )
      );
   
   
endmodule // butterflyUnit


