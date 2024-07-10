module register_with_sync_reset #(parameter integer BITWIDTH = 2) (
  input clk,
  input rst,
  input wire [BITWIDTH-1:0] d,
  output wire [BITWIDTH-1:0] q
  );

  genvar i;
  generate
    for (i = 0; i < BITWIDTH; i++) begin : gen_register
      dff_with_sync_reset dff_i (
        .clk(clk),
        .rst(rst),
        .d(d[i]),
        .q(q[i])
        );
    end
  endgenerate
endmodule
