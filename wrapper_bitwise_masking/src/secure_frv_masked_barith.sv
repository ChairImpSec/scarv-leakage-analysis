
//
// Binary masked arithmetic add/sub
//
module secure_frv_masked_barith (
    input  wire        g_resetn,
    input  wire        g_clk,
    input  wire        flush,
    input  wire        ena,
    input  wire        sub,       // active to perform a-b
    input  wire [31:0] i_gs0,
    input  wire [31:0] i_gs1,
    input  wire [31:0] mxor0,
    input  wire [31:0] mxor1,
    input  wire [31:0] mand0,
    input  wire [31:0] mand1,
    output wire [31:0] o_s0,
    output wire [31:0] o_s1,
    output wire        rdy
);

  // Masking ISE - Use a DOM Implementation (1) or not (0)
  parameter logic MASKING_ISE_DOM = 1'b1;
  // NOTE: all registers/operations which somehow use the DELAY variable are changed
  // to allow verification with prolead which is not able to simulate on negative edges.
  parameter integer DELAY = 6;

  wire [31:0] p0, p1;
  wire [31:0] g0, g1;

  wire [31:0] p0_i, p1_i;
  wire [31:0] g0_i, g1_i;

  reg [DELAY-1:0] seq_cnt = 6'b000000;
  reg toggel;
  always @(posedge g_clk) begin
    if (!g_resetn) begin
      toggel  <= 0;
      seq_cnt <= 1;
    end else if (flush) begin
      toggel  <= 0;
      seq_cnt <= 1;
    end else if (rdy) begin
      toggel  <= 0;
      seq_cnt <= 1;
    end
    else if (ena) begin
      if (toggel) begin
        seq_cnt <= seq_cnt << 1;
      end
      toggel <= ~toggel;
    end
    else begin
      seq_cnt <= 1;
    end
  end

  wire ini = ena && seq_cnt[0];

  assign p0_i = ({32{ini}} & mxor0) | ({32{!ini}} & p0);
  assign p1_i = ({32{ini}} & mxor1) | ({32{!ini}} & p1);
  assign g0_i = ({32{ini}} & mand0) | ({32{!ini}} & g0);
  assign g1_i = ({32{ini}} & mand1) | ({32{!ini}} & g1);

  frv_masked_barith_seq_process #(
      .MASKING_ISE_DOM(MASKING_ISE_DOM),
      .DELAY(DELAY)
  ) seqproc_ins (
      .g_resetn(g_resetn),
      .g_clk   (g_clk),
      .ena     (ena),
      .i_gs0   (i_gs0),
      .i_gs1   (i_gs1),
      .seq     (seq_cnt),
      .i_pk0   (p0_i),
      .i_pk1   (p1_i),
      .i_gk0   (g0_i),
      .i_gk1   (g1_i),
      .o_pk0   (p0),
      .o_pk1   (p1),
      .o_gk0   (g0),
      .o_gk1   (g1)
  );

  wire [31:0] o_s0_gated = mxor0 ^ {g0[30:0], 1'b0};
  wire [31:0] o_s1_gated = mxor1 ^ {g1[30:0], sub};

  assign o_s0 = o_s0_gated;
  assign o_s1 = o_s1_gated;
  assign rdy  = seq_cnt[DELAY-1];

endmodule

//
// Sequential pocessing module for the binary masked arithmetic
//
module frv_masked_barith_seq_process #(
    parameter logic MASKING_ISE_DOM = 1'b0,
    parameter integer DELAY = 6
) (
    input wire             g_resetn,
    input wire             g_clk,
    input wire             ena,
    input wire [     31:0] i_gs0,
    input wire [     31:0] i_gs1,
    input wire [DELAY-1:0] seq,

    input  wire [31:0] i_pk0,
    input  wire [31:0] i_pk1,
    input  wire [31:0] i_gk0,
    input  wire [31:0] i_gk1,
    output wire [31:0] o_pk0,
    output wire [31:0] o_pk1,
    output wire [31:0] o_gk0,
    output wire [31:0] o_gk1
);

  // Masking ISE - Use a DOM Implementation (1) or not (0)

  reg [31:0] gkj0, gkj1;
  reg [31:0] pkj0, pkj1;

  always @(*) begin

    gkj0 =  {32{ seq[  0]}} & {i_gk0[30:0], 1'd0} |
            {32{ seq[  1]}} & {i_gk0[29:0], 2'd0} |
            {32{ seq[  2]}} & {i_gk0[27:0], 4'd0} |
            {32{ seq[  3]}} & {i_gk0[23:0], 8'd0} |
            {32{|seq[5:4]}} & {i_gk0[15:0],16'd0} ; // LEAKAGE

    gkj1 =  {32{ seq[  0]}} & {i_gk1[30:0], 1'd0} |
            {32{ seq[  1]}} & {i_gk1[29:0], 2'd0} |
            {32{ seq[  2]}} & {i_gk1[27:0], 4'd0} |
            {32{ seq[  3]}} & {i_gk1[23:0], 8'd0} |
            {32{|seq[5:4]}} & {i_gk1[15:0],16'd0} ; // LEAKAGE

    pkj0 =  {32{ seq[  0]}} & {i_pk0[30:0], 1'd0} |
            {32{ seq[  1]}} & {i_pk0[29:0], 2'd0} |
            {32{ seq[  2]}} & {i_pk0[27:0], 4'd0} |
            {32{|seq[5:3]}} & {i_pk0[23:0], 8'd0} ; // LEAKAGE

    pkj1 =  {32{ seq[  0]}} & {i_pk1[30:0], 1'd0} |
            {32{ seq[  1]}} & {i_pk1[29:0], 2'd0} |
            {32{ seq[  2]}} & {i_pk1[27:0], 4'd0} |
            {32{|seq[5:3]}} & {i_pk1[23:0], 8'd0} ; // LEAKAGE
  end

  generate
    if (MASKING_ISE_DOM == 1'b1) begin : gen_sni_dom_indep
      wire [31:0] i_tg0 = (gkj0 & i_pk0);
      wire [31:0] i_tg1 = i_gs0 ^ i_gk0 ^ (gkj0 & i_pk1);
      wire [31:0] i_tg2 = i_gs0 ^ i_gk1 ^ (gkj1 & i_pk0);
      wire [31:0] i_tg3 = (gkj1 & i_pk1);

      wire [31:0] tg0, tg1;
      wire [31:0] tg2, tg3;
      wire [31:0] tg0tg1, tg2tg3;
      FF_Nb #(
          .Nb(32)
      ) ff_tg0 (
          .g_resetn(g_resetn),
          .g_clk(g_clk),
          .ena(ena),
          .din(i_tg0),
          .dout(tg0)
      );
      FF_Nb #(
          .Nb(32)
      ) ff_tg1 (
          .g_resetn(g_resetn),
          .g_clk(g_clk),
          .ena(ena),
          .din(i_tg1),
          .dout(tg1)
      );
      FF_Nb #(
          .Nb(32)
      ) ff_tg2 (
          .g_resetn(g_resetn),
          .g_clk(g_clk),
          .ena(ena),
          .din(i_tg2),
          .dout(tg2)
      );
      FF_Nb #(
          .Nb(32)
      ) ff_tg3 (
          .g_resetn(g_resetn),
          .g_clk(g_clk),
          .ena(ena),
          .din(i_tg3),
          .dout(tg3)
      );


      // NOTE: We added a register stage here to prevent lekage!

      assign tg0tg1 = tg0 ^ tg1;
      assign tg2tg3 = tg2 ^ tg3;
      FF_Nb #(
          .Nb(32)
      ) ff_o_gk0 (
          .g_resetn(g_resetn),
          .g_clk(g_clk),
          .ena(ena),
          .din(tg0tg1),
          .dout(o_gk0)
      );

      FF_Nb #(
          .Nb(32)
      ) ff_o_gk1 (
          .g_resetn(g_resetn),
          .g_clk(g_clk),
          .ena(ena),
          .din(tg2tg3),
          .dout(o_gk1)
      );
      //assign o_gk0 = tg0 ^ tg1;
      //assign o_gk1 = tg2 ^ tg3;

      wire [31:0] i_tp0 = (i_pk0 & pkj0);
      wire [31:0] i_tp1 = i_gs1 ^ (i_pk0 & pkj1);
      wire [31:0] i_tp2 = i_gs1 ^ (i_pk1 & pkj0);
      wire [31:0] i_tp3 = (i_pk1 & pkj1);

      wire [31:0] tp0, tp1;
      wire [31:0] tp2, tp3;
      wire [31:0] tp0tp1, tp2tp3;

      FF_Nb #(
          .Nb(32)
      ) ff_tp0 (
          .g_resetn(g_resetn),
          .g_clk(g_clk),
          .ena(ena),
          .din(i_tp0),
          .dout(tp0)
      );
      FF_Nb #(
          .Nb(32)
      ) ff_tp1 (
          .g_resetn(g_resetn),
          .g_clk(g_clk),
          .ena(ena),
          .din(i_tp1),
          .dout(tp1)
      );
      FF_Nb #(
          .Nb(32)
      ) ff_tp2 (
          .g_resetn(g_resetn),
          .g_clk(g_clk),
          .ena(ena),
          .din(i_tp2),
          .dout(tp2)
      );
      FF_Nb #(
          .Nb(32)
      ) ff_tp3 (
          .g_resetn(g_resetn),
          .g_clk(g_clk),
          .ena(ena),
          .din(i_tp3),
          .dout(tp3)
      );


      assign tp0tp1 = tp0 ^ tp1;
      assign tp2tp3 = tp2 ^ tp3;

      // NOTE: We added a register stage here to prevent lekage!

      FF_Nb #(
          .Nb(32)
      ) ff_o_pk0 (
          .g_resetn(g_resetn),
          .g_clk(g_clk),
          .ena(ena),
          .din(tp0tp1),
          .dout(o_pk0)
      );

      FF_Nb #(
          .Nb(32)
      ) ff_o_pk1 (
          .g_resetn(g_resetn),
          .g_clk(g_clk),
          .ena(ena),
          .din(tp2tp3),
          .dout(o_pk1)
      );

    end else begin : gen_masking
      wire [31:0] pk0 = i_gs1 ^ (i_pk0 & pkj1) ^ (i_pk0 | ~pkj0);
      wire [31:0] pk1 = i_gs1 ^ (i_pk1 & pkj1) ^ (i_pk1 | ~pkj0);
      FF_Nb #(
          .Nb(32)
      ) ff_pk0 (
          .g_resetn(g_resetn),
          .g_clk(g_clk),
          .ena(ena),
          .din(pk0),
          .dout(o_pk0)
      );
      FF_Nb #(
          .Nb(32)
      ) ff_pk1 (
          .g_resetn(g_resetn),
          .g_clk(g_clk),
          .ena(ena),
          .din(pk1),
          .dout(o_pk1)
      );

      wire [31:0] gk0 = i_gk0 ^ (gkj0 & i_pk1) ^ (gkj0 | ~i_pk0);
      wire [31:0] gk1 = i_gk1 ^ (gkj1 & i_pk1) ^ (gkj1 | ~i_pk0);
      FF_Nb #(
          .Nb(32)
      ) ff_gk0 (
          .g_resetn(g_resetn),
          .g_clk(g_clk),
          .ena(ena),
          .din(gk0),
          .dout(o_gk0)
      );
      FF_Nb #(
          .Nb(32)
      ) ff_gk1 (
          .g_resetn(g_resetn),
          .g_clk(g_clk),
          .ena(ena),
          .din(gk1),
          .dout(o_gk1)
      );
    end
  endgenerate
endmodule


