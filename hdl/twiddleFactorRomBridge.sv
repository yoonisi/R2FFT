
module twiddleFactorRomBridge
  #(
    parameter FFT_N = 10,
    parameter FFT_DW = 16
    )
  (
   input wire                   clk,
   input wire                   rst,
   input wire                   tact_rom,
   input wire [FFT_N-1-1:0]     ta_rom,

   input wire                   evenOdd,
   input wire                   ifft,
   
   output reg signed [FFT_DW:0] tdr_rom_real,
   output reg signed [FFT_DW:0] tdr_rom_imag,

   // twiddle factor rom interface
   output wire                  twact,
   output wire [FFT_N-1-2:0]    twa,
   input wire [FFT_DW-1:0]    twdr_cos
   );


   // pipeline stage 1
   reg                      tact_1;
   reg                      ta_msb_1;
   wire [FFT_N-1-2:0]       cosAddr = ta_rom[FFT_N-1-2:0];
   reg                      evenOdd_1;
   // pipeline stage 2
   reg [FFT_N-1-2:0] 	    sinAddr;
   reg                      tact_2;
   reg                      ta_msb_2;
   reg                      evenOdd_2;

   // pipeline stage 3
   reg                      ta_msb_3;

   always @ ( posedge clk ) begin
      if ( rst ) begin
         tact_1 <= 0;
         ta_msb_1 <= 0;
         sinAddr <= 0;
         evenOdd_1 <= 0;
         
         tact_2 <= 0;
         ta_msb_2 <= 0;
         evenOdd_2 <= 0;

         ta_msb_3 <= 0;
      end else begin
         
         tact_1 <= tact_rom;
         ta_msb_1 <= ta_rom[FFT_N-1-1];
         sinAddr <= {1'b1,{(FFT_N-1-1){1'b0}}} - ta_rom[FFT_N-1-2:0];
         evenOdd_1 <= evenOdd;
         
         tact_2 <= tact_1;
         ta_msb_2 <= ta_msb_1;
         evenOdd_2 <= evenOdd_1;

         ta_msb_3 <= ta_msb_2;
      end
   end // always @ ( posedge clk )

   wire cosRomAddrPhase = tact_rom && (evenOdd == 1'b0);
   wire cosRomDataPhase = tact_1   && (evenOdd_1 == 1'b0);
   wire sinRomAddrPhase = cosRomDataPhase;
   wire sinRomDataPhase = tact_2   && (evenOdd_2 == 1'b0);

   assign twact = cosRomAddrPhase || sinRomAddrPhase;
   assign twa   = sinRomAddrPhase ? sinAddr : cosAddr;

   reg 	sin0;
   always @ ( posedge clk ) begin
      sin0 = ( sinAddr == 0 ) ? 1'b1 : 1'b0;
   end
   
   wire signed [FFT_DW:0] cosReadData = {1'b0, twdr_cos};
   wire signed [FFT_DW:0] sinReadData = sin0 ? 0 : {1'b0, twdr_cos};

   reg signed [FFT_DW:0]  cosReadData_1;
   reg signed [FFT_DW:0]  cosReadData_2;
   always @ ( posedge clk ) begin
      if ( cosRomDataPhase ) begin
         cosReadData_1 <= cosReadData;
      end
      cosReadData_2 <= cosReadData_1;
   end

   reg signed [FFT_DW:0] sinReadData_2;
   always @ ( posedge clk ) begin
      if ( sinRomDataPhase ) begin
         sinReadData_2 <= sinReadData;
      end
   end

   always_comb begin
      if ( ta_msb_3 == 1'b0 ) begin
         tdr_rom_real = cosReadData_2;
         tdr_rom_imag = ifft ? sinReadData_2 : -sinReadData_2;
      end else begin
         tdr_rom_real = -sinReadData_2;
         tdr_rom_imag = ifft ? cosReadData_2 : -cosReadData_2;
      end
   end
   
endmodule // twiddleFactorRom

