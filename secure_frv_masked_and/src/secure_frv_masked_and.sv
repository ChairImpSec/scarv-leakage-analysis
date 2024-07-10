module secure_frv_masked_and #(
// this does not work for D > 1
parameter integer BIT_WIDTH=2
)(
input  wire          g_clk  ,
input  wire          clk_en ,           // Clock/register enble.
input  wire [BIT_WIDTH-1:0]  z0     ,   // Fresh randomness
input  wire [BIT_WIDTH-1:0]  z1     ,   // Fresh randomness
input  wire [BIT_WIDTH-1:0]  z2     ,   // Fresh randomness required for dom
input  wire [BIT_WIDTH-1:0]  ax, ay ,   // Domain A Input shares: rs1 s0, rs2 s0
input  wire [BIT_WIDTH-1:0]  bx, by ,   // Domain B Input shares: rs1 s1, rs2 s1
output wire [BIT_WIDTH-1:0]  qx, qy     // Result shares
);

parameter integer D = 1;
parameter integer N = D+1;
parameter integer L = ((D+1)*D)/2;

wire clk = clk_en & g_clk;

wire [N-1:0] port_a_in[BIT_WIDTH];
wire [N-1:0] port_b_in[BIT_WIDTH];

wire [N-1:0] r1 [BIT_WIDTH];
wire [L-1:0] r2 [BIT_WIDTH];

wire [N-1:0] c  [BIT_WIDTH];

genvar i;
generate
for (i = 0; i < BIT_WIDTH; i = i + 1) begin : gen_portmapping
    assign port_a_in[i][0] = ax[i];
    assign port_a_in[i][1] = bx[i];
    assign port_b_in[i][0] = ay[i];
    assign port_b_in[i][1] = by[i];
    assign r1[i] = {z0[i], z1[i]};
    assign r2[i] = z2[i];
    assign qx[i] = c[i][0];
    assign qy[i] = c[i][1];
end
endgenerate

dom_dep_multibit #(.D(D), .BIT_WIDTH(BIT_WIDTH)) dom_dep_multibit(
    .clk(clk),
    .port_a(port_a_in),
    .port_b(port_b_in),
    .port_r1(r1), // requires BIT_WIDTH * 2 bits randomness (|z0| + |z1| = 2*BIT_WIDTH)
    .port_r2(r2), // requires BIT_WIDTH bits randomness
    .port_c(c)
);

endmodule
