
module bitReverseCounter
  #(
    parameter BIT_WIDTH = 10
    )
  (
   input wire                  rst,
   input wire                  clk,
   input wire                  clr,

   input wire                  inc,
   output wire [BIT_WIDTH-1:0] iter,
   output wire [BIT_WIDTH-1:0] count,
   output wire                 countFull
   
   );

   reg [BIT_WIDTH-1:0]         ptr_f;
   assign count = ptr_f;

   always @ ( posedge clk ) begin
      if ( rst ) begin
         ptr_f <= {BIT_WIDTH{1'b0}};
      end else if ( clr ) begin
         ptr_f <= {BIT_WIDTH{1'b0}};
      end else if ( inc ) begin
         ptr_f <= ptr_f + 1;
      end
   end

   genvar i;
   generate
      for ( i = 0; i < BIT_WIDTH; i = i + 1 ) begin : BITREV_BLOCK
         assign iter[i] = ptr_f[BIT_WIDTH-1-i];
      end
   endgenerate

   assign countFull = &ptr_f;
   
endmodule // bitReverseIndexer

