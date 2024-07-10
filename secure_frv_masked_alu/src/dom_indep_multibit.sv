// Implementation of a wrapper for the dom_indep one-bit-and gadget.
// This implementation parameterizes the number of bits for,
// which the dom-indep one-bit-and should be implemented.
module dom_indep_multibit #(
    parameter integer D = 1,
    parameter integer BIT_WIDTH = 1,
    parameter integer N = D + 1,
    parameter integer L = ((D + 1) * D) / 2
) (
    input clk,
    input [N-1:0] port_a [BIT_WIDTH],
    input [N-1:0] port_b [BIT_WIDTH],
    input [L-1:0] port_r [BIT_WIDTH],
    output[N-1:0] port_c [BIT_WIDTH]
);

  genvar i;
  generate
    for (i = 0; i < BIT_WIDTH; i = i + 1) begin : gen_dom_indep_multbit
      dom_indep #(
          .D(D)
      ) dom_mul (
          .clk(clk),
          .port_a(port_a[i]),
          .port_b(port_b[i]),
          .port_r(port_r[i]),
          .port_c(port_c[i])
      );
    end
  endgenerate

endmodule
