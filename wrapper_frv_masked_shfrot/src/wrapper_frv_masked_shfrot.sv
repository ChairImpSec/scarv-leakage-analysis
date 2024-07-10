module wrapper_frv_masked_shfrot #(
    parameter integer BIT_WIDTH = 32
) (
    input                 clk,
    input                 srli,   // Shift  right
    input                 slli,   // Shift  left
    input                 rori,   // Rotate right
    input                 ena,
    input [          4:0] shamt,  // Shift amount
    input [BIT_WIDTH-1:0] s0,     // Input share 0
    input [BIT_WIDTH-1:0] s1,     // Input share 1
    input [BIT_WIDTH-1:0] rp0,    // random padding 0

    output[BIT_WIDTH-1:0] r0,     // output share0
    output[BIT_WIDTH-1:0] r1,     // output share1
    output ready
);

  wire [BIT_WIDTH-1:0] shfrot_s0_out;
  wire [BIT_WIDTH-1:0] shfrot_s1_out;

  reg ctr_ready;
  initial ctr_ready = 0;
  always @(posedge clk) begin
    if (ready) ctr_ready <= 1'b0;
    else if (ena) ctr_ready <= 1'b1;
    else ctr_ready <= 1'b0;
  end
  assign ready = ctr_ready;

  frv_masked_shfrot shfrot_s0 (
      .shamt(shamt),
      .s(s0),
      .rp(rp0),
      .srli(srli),
      .slli(slli),
      .rori(rori),
      .r(shfrot_s0_out)
  );

  frv_masked_shfrot shfrot_s1 (
      .shamt(shamt),
      .s(s1),
      .rp(rp0),
      .srli(srli),
      .slli(slli),
      .rori(rori),
      .r(shfrot_s1_out)
  );

  register_with_sync_reset #(
      .BITWIDTH(BIT_WIDTH)
  ) sync_shift0 (
      .clk(clk),
      .rst(!ena),
      .d  (shfrot_s0_out),
      .q  (r0)
  );

  register_with_sync_reset #(
      .BITWIDTH(BIT_WIDTH)
  ) sync_shift1 (
      .clk(clk),
      .rst(!ena),
      .d  (shfrot_s1_out),
      .q  (r1)
  );

endmodule
