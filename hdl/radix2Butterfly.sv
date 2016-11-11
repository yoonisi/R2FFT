
module radix2Butterfly
  #(
    parameter FFT_DW = 16,
    parameter FFT_N = 10,
    parameter PL_DEPTH = 3
    )
  (
   input wire                     clk,
   input wire                     rst,
   
   input wire                     iact,
   input wire [1:0]               ictrl,

   output reg                     oact,
   output reg [1:0]               octrl,

   input wire [FFT_N-1-1:0]       iMemAddr,
   output reg [FFT_N-1-1:0]       oMemAddr,
   
   // input
   input wire signed [FFT_DW-1:0] opa_real, // [-1,1)
   input wire signed [FFT_DW-1:0] opa_imag, // [-1,1)
   input wire signed [FFT_DW-1:0] opb_real, // [-1,1)
   input wire signed [FFT_DW-1:0] opb_imag, // [-1,1)
   // twiddle factor
   input wire signed [FFT_DW:0]   twiddle_real, // [-1,1]
   input wire signed [FFT_DW:0]   twiddle_imag, // [-1,1]
   // output
   output reg signed [FFT_DW-1:0] dst_opa_real, // [-1,1)
   output reg signed [FFT_DW-1:0] dst_opa_imag, // [-1,1)
   output reg signed [FFT_DW-1:0] dst_opb_real, // [-1,1)
   output reg signed [FFT_DW-1:0] dst_opb_imag  // [-1,1)
   );

`ifdef DEBUG_PRINT
   always @ ( negedge clk ) begin
      if ( PL_DEPTH == 0 ) begin
	 if ( iact ) begin
	    $display(",%04x,%04x,%04x,%04x,%04x,%04x,%04x,%04x,%05x,%05x",
		     opa_real,
		     opa_imag,
		     opb_real,
		     opb_imag,
		     dst_opa_real,
		     dst_opa_imag,
		     dst_opb_real,
		     dst_opb_imag,
		     twiddle_real,
		     twiddle_imag
		     );
	 end // if ( iact )
      end // if ( PL_DEPTH == 0 )
   end // always @ ( negedge clk )
`endif
   
   function [FFT_DW-1:0] AddAvg
     (
      input signed [FFT_DW-1:0] opa_,
      input signed [FFT_DW-1:0] opb_
      );
      reg signed [FFT_DW:0]   tmp;
      begin
         tmp = { opa_[FFT_DW-1], opa_[FFT_DW-1:0] } + { opb_[FFT_DW-1], opb_[FFT_DW-1:0] };
         AddAvg = tmp[FFT_DW:1];
      end
   endfunction //

   function [FFT_DW-1:0] SubAvg
     (
      input signed [FFT_DW-1:0] opa_,
      input signed [FFT_DW-1:0] opb_
      );
      reg signed [FFT_DW:0] tmp;
      begin
         tmp = { opa_[FFT_DW-1], opa_[FFT_DW-1:0] } - { opb_[FFT_DW-1], opb_[FFT_DW-1:0] };
         SubAvg = tmp[FFT_DW:1];
      end
   endfunction

   function [FFT_DW-1:0] LimitOperand
     (
      input [FFT_DW+3:0] value_
      );
      begin
         if ( (value_[FFT_DW] == 1'b0) && (value_[FFT_DW-1] == 1'b1) ) begin
            LimitOperand = {1'b0,{(FFT_DW-1){1'b1}}};
      end else if ( (value_[FFT_DW] == 1'b1) && (value_[FFT_DW-1] == 1'b0) ) begin
	 LimitOperand = {1'b1,{(FFT_DW-1){1'b0}}};
            end else begin
               LimitOperand = value_[FFT_DW-1:0];
            end
      end
   endfunction
   
   // Stage 1

   wire signed [FFT_DW-1:0] xbuf_real_stage1 = SubAvg ( opa_real, opb_real );
   wire signed [FFT_DW-1:0] xbuf_imag_stage1 = SubAvg ( opa_imag, opb_imag );
   wire signed [FFT_DW:0]   xbuf_real_p_imag_stage1 = xbuf_real_stage1 + xbuf_imag_stage1;
   wire signed [FFT_DW+1:0]   twiddle_real_p_imag_stage1 = twiddle_real + twiddle_imag;
   wire signed [FFT_DW+1:0]   twiddle_real_m_imag_stage1 = twiddle_real - twiddle_imag;

   reg signed [FFT_DW-1:0]   xbuf_real_stage2;
   reg signed [FFT_DW-1:0]   xbuf_imag_stage2;
   reg signed [FFT_DW:0]     xbuf_real_p_imag_stage2;
   reg signed [FFT_DW+1:0]   twiddle_real_p_imag_stage2;
   reg signed [FFT_DW+1:0]   twiddle_real_m_imag_stage2;
   reg signed [FFT_DW:0]     twiddle_real_stage2;

   generate if ( PL_DEPTH >= 1 ) begin

      always @ ( posedge clk ) begin
         xbuf_real_stage2 <= xbuf_real_stage1;
         xbuf_imag_stage2 <= xbuf_imag_stage1;
         xbuf_real_p_imag_stage2 <= xbuf_real_p_imag_stage1;
         twiddle_real_p_imag_stage2 <= twiddle_real_p_imag_stage1;
         twiddle_real_m_imag_stage2 <= twiddle_real_m_imag_stage1;
         twiddle_real_stage2 <= twiddle_real;
      end
      
   end else begin

      always_comb begin
         xbuf_real_stage2 = xbuf_real_stage1;
         xbuf_imag_stage2 = xbuf_imag_stage1;
         xbuf_real_p_imag_stage2 = xbuf_real_p_imag_stage1;
         twiddle_real_p_imag_stage2 = twiddle_real_p_imag_stage1;
         twiddle_real_m_imag_stage2 = twiddle_real_m_imag_stage1;
         twiddle_real_stage2 = twiddle_real;
      end
   
   end endgenerate // else: !if( PL_DEPTH >= 1 )
   
   // Stage 2

   wire signed [(FFT_DW+1+FFT_DW+1)-1:0] tmp_a = ( xbuf_real_p_imag_stage2 ) * twiddle_real_stage2;
   wire signed [(FFT_DW+2+FFT_DW)-1:0] tmp_r =   ( twiddle_real_p_imag_stage2 ) * xbuf_imag_stage2;
   wire signed [(FFT_DW+2+FFT_DW)-1:0] tmp_i =   ( twiddle_real_m_imag_stage2 ) * xbuf_real_stage2;

   reg signed [(FFT_DW+1+FFT_DW+1)-1:0] tmp_a_stage3;
   reg signed [(FFT_DW+2+FFT_DW)-1:0]   tmp_r_stage3;
   reg signed [(FFT_DW+2+FFT_DW)-1:0]   tmp_i_stage3;

   generate if ( PL_DEPTH >= 2 ) begin
      
      always @ ( posedge clk ) begin
         tmp_a_stage3 <= tmp_a;
         tmp_r_stage3 <= tmp_r;
         tmp_i_stage3 <= tmp_i;
      end
      
   end else begin

      always_comb begin
         tmp_a_stage3 = tmp_a;
         tmp_r_stage3 = tmp_r;
         tmp_i_stage3 = tmp_i;
      end
      
   end endgenerate
   
   // Stage 3
   
   wire signed [FFT_DW*2+2:0]   yr = ({tmp_a_stage3[FFT_DW*2+1],tmp_a_stage3} - {tmp_r_stage3[FFT_DW*2+1],tmp_r_stage3})
    + {2'b01,{FFT_DW-2{1'b0}}};
   wire signed [FFT_DW*2+2:0] 	yi = ({tmp_a_stage3[FFT_DW*2+1],tmp_a_stage3} - {tmp_i_stage3[FFT_DW*2+1],tmp_i_stage3})
    + {2'b01,{FFT_DW-2{1'b0}}};

   wire signed [FFT_DW+3:0] yr_truncated = yr[FFT_DW*2+2:FFT_DW-1];
   wire signed [FFT_DW+3:0] yi_truncated = yi[FFT_DW*2+2:FFT_DW-1];

   always_comb begin
      dst_opb_real = LimitOperand( yr_truncated );
      dst_opb_imag = LimitOperand( yi_truncated );
   end

   // OpA Pipeline

   reg signed [FFT_DW-1:0] dst_opa_real_stage2;
   reg signed [FFT_DW-1:0] dst_opa_imag_stage2;

   reg                     iact_stage2;
   reg [1:0]               ictrl_stage2;
   reg [FFT_N-1-1:0]       iMemAddr_stage2;
   
   generate if ( PL_DEPTH >= 1 ) begin

      always @ ( posedge clk ) begin
         dst_opa_real_stage2 <= AddAvg( opa_real, opb_real );
         dst_opa_imag_stage2 <= AddAvg( opa_imag, opb_imag );
      end

      always @ ( posedge clk ) begin
         iact_stage2 <= rst ? 1'b0 : iact;
         ictrl_stage2 <= ictrl;
         iMemAddr_stage2 <= iMemAddr;
      end
      
   end else begin
   
      always_comb begin
         dst_opa_real_stage2 = AddAvg( opa_real, opb_real );
         dst_opa_imag_stage2 = AddAvg( opa_imag, opb_imag ); 
      end

      always_comb begin
         iact_stage2 = iact;
         ictrl_stage2 = ictrl;
         iMemAddr_stage2 = iMemAddr;
      end


   end endgenerate // else: !if( PL_DEPTH >= 1 )
   
   generate if ( PL_DEPTH >= 2 ) begin
      
      always @ ( posedge clk ) begin
         dst_opa_real <= dst_opa_real_stage2;
         dst_opa_imag <= dst_opa_imag_stage2;
      end

      always @ (posedge clk) begin
         oact <= rst ? 1'b0 : iact_stage2;
         octrl <= ictrl_stage2;
         oMemAddr <= iMemAddr_stage2;
      end      
      
   end else begin

      always_comb begin
         dst_opa_real = dst_opa_real_stage2;
         dst_opa_imag = dst_opa_imag_stage2;
      end

      always_comb begin
         oact = iact_stage2;
         octrl = ictrl_stage2;
         oMemAddr = iMemAddr_stage2;
      end
      
   end endgenerate // else: !if( PL_DEPTH >= 2 )
   
endmodule // radix2Butterfly


