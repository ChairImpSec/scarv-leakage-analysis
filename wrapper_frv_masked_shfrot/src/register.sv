
module register #(
    parameter integer N = 2  // shares
) (
    input wire clk,
    input wire [N-1:0] d,
    output wire [N-1:0] q
);
  genvar i;
  generate
    for (i = 0; i < N; i = i + 1) begin : gen_register
      dff dff_i (
          .clk(clk),
          .d  (d[i]),
          .q  (q[i])
      );
    end
  endgenerate
endmodule
