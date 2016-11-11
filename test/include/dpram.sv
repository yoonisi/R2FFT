
// dual port block sram
//   1 read port / 1 write port

module dpram
  #(
    parameter ADDR_WIDTH = 9,
    parameter DATA_WIDTH = 32
    )
   (
    input wire 			 clk,

    // read
    input wire 			 ract,
    input wire [ADDR_WIDTH-1:0]  ra,
    output wire [DATA_WIDTH-1:0] rdr,

    // wire
    input wire 			 wact,
    input wire [ADDR_WIDTH-1:0]  wa,
    input wire [DATA_WIDTH-1:0]  wdw
    
    );

   reg [DATA_WIDTH-1:0] 	 mem [2**ADDR_WIDTH];

   reg [DATA_WIDTH-1:0] 	 rd;
   assign rdr = rd;
   always @ ( posedge clk ) begin
      if ( ract ) begin
	 rd <= mem[ra];
      end
   end

   always @ ( posedge clk ) begin
      if ( wact ) begin
	 mem[wa] <= wdw;
      end
   end
   

endmodule // dpram

