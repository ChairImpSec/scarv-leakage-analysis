module secure_frv_masked_and_reduced_randomness #(
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

reg   [N-1:0] t0 ;
reg   [N-1:0] t1 ;

always @(posedge g_clk) begin
  if(clk_en) begin
    t1 <= by ^ z0;
    t0 <= (ax & z0) ^ z1;
  end
end

assign qx = ((t1 ^ ay) & ax) ^ t0;


reg   [N-1:0] t2;
reg   [N-1:0] t3;

always @(posedge g_clk) begin
  if(clk_en) begin
    t3 <= ay ^ z0;
    t2 <= (bx & z0) ^ z1;
  end
end

assign qy = ((t3 ^ by) & bx) ^ t2 ;

endmodule
