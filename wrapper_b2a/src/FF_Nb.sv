//
// Single flip flop used by masked ALU modules etc.
// NOTE: extracted from secure_frv_masked_alu
//
//
module FF_Nb #(
    parameter integer Nb  = 1,
    parameter integer EDG = 1
) (
    input wire g_resetn,
    g_clk,
    input wire ena,
    input wire [Nb-1:0] din,
    output reg [Nb-1:0] dout
);

  generate
    if (EDG == 1) begin : gen_posedge_ff
      always @(posedge g_clk) begin
        if (!g_resetn) dout <= {Nb{1'b0}};
        else if (ena) dout <= din;
      end
    end else begin : gen_negedge_ff
      always @(negedge g_clk) begin
        if (!g_resetn) dout <= {Nb{1'b0}};
        else if (ena) dout <= din;
      end
    end
  endgenerate

endmodule
