// Implementation of the dom-indep one-bit-and gadget with a
// parametizied probing security order D.
// The implementation follows Figure 3 of https://eprint.iacr.org/2016/486.pdf
module dom_indep #(
    parameter integer D = 2,
    // Number of shares N
    parameter integer N = D + 1,
    // Number of random bits
    parameter integer L = ((D + 1) * D) / 2
) (
    input clk,
    input rst,
    input [N-1:0] port_a,
    input [N-1:0] port_b,
    input [L-1:0] port_r,
    output [N-1:0] port_c
);


  wire [N-1:0] partial_products[N];
  wire [N-1:0] partial_products_delayed[N];

  genvar i, j;
  for (i = 0; i < N; i = i + 1) begin : gen_sym_partial_product
    assign partial_products[i][i] = (port_a[i] & port_b[i]);
    for (j = i + 1; j < N; j = j + 1) begin : gen_asym_partial_product
      assign partial_products[i][j] = (port_a[i] & port_b[j]) ^ port_r[i+(j*(j-1)/2)];
      assign partial_products[j][i] = (port_a[j] & port_b[i]) ^ port_r[i+(j*(j-1)/2)];
    end
  end

  for (i = 0; i < N; i = i + 1) begin : gen_delayed_partial_product
    register_with_sync_reset #(
        .BITWIDTH(N)
    ) delay_partial_products (
        .clk(clk),
        .rst(rst),
        .d  (partial_products[i]),
        .q  (partial_products_delayed[i])
    );
  end

  for (i = 0; i < N; i = i + 1) begin : gen_result_by_recombining
    assign port_c[i] = ^(partial_products_delayed[i]);
  end
endmodule
