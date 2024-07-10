module frv_masked_and #(
parameter integer N=1
)(
input  wire          g_clk  ,
input  wire          clk_en ,   // Clock/register enble.
input  wire [N-1:0]  z0     ,   // Fresh randomness
input  wire [N-1:0]  z1     ,   // Fresh randomness
input  wire [N-1:0]  ax, ay ,   // Domain A Input shares: rs1 s0, rs2 s0
input  wire [N-1:0]  bx, by ,   // Domain B Input shares: rs1 s1, rs2 s1
output wire [N-1:0]  qx, qy     // Result shares
);

wire [N-1:0] t0 = ax & z0;
reg  [N-1:0] t1 ;

always @(posedge g_clk) if(clk_en) t1 <= by ^ z0;

assign qx = ((t1 ^ ay) & ax) ^ t0 ^ z1;


wire [N-1:0] t2 = bx & z0;
reg  [N-1:0] t3 ;

always @(posedge g_clk) if(clk_en) t3 <= ay ^ z0;

assign qy = ((t3 ^ by) & bx) ^ t2 ^ z1;

endmodule
