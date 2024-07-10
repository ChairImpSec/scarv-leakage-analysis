
//
// module: frv_masked_and
//
//  Implements an BIT_WIDTH-bit masked ABIT_WIDTHD operation using Domain oriented masking
//  See figure 2 of https://eprint.iacr.org/2016/486.pdf
//
//  Note: Internal registers change on negative edge of g_clk when clk_en set.
//
//  Input variables are X and Y. Domains are A and B.
//
module frv_masked_and #(
    parameter integer BIT_WIDTH    = 32
) (
    input  wire                 g_clk,
    input  wire                 clk_en,  // Clock/register enble.
    input  wire [BIT_WIDTH-1:0] z0,      // Fresh randomness
    input  wire [BIT_WIDTH-1:0] z1,      // Fresh randomness
    input  wire [BIT_WIDTH-1:0] z2,      // Fresh randomness added, required for dom-dep
    //input  wire [BIT_WIDTH-1:0] z3,      // Fresh randomness added, required for masked xor
    input  wire [BIT_WIDTH-1:0] ax,      // Domain A Input share: rs1_s0
    input  wire [BIT_WIDTH-1:0] ay,      // Domain A Input share: rs2_s0
    input  wire [BIT_WIDTH-1:0] bx,      // Domain B Input share: rs1_s1
    input  wire [BIT_WIDTH-1:0] by,      // Domain B Input share: rs2_s1
    output wire [BIT_WIDTH-1:0] qx,      // Outpur shares rd_s0
    output wire [BIT_WIDTH-1:0] qy       // Outpur shares rd_s1
);


  parameter integer D = 1;  // security order
  parameter integer N = D + 1;  // number of shares
  parameter integer L = ((D + 1) * D) / 2;  // number of random bits of dom_indep (per masked bit)

  wire clk = clk_en & g_clk;

  // Map ports as required by submodules
  wire [N-1:0] a[BIT_WIDTH];
  wire [N-1:0] b[BIT_WIDTH];
  wire [N-1:0] r1[BIT_WIDTH];
  wire [L-1:0] r2[BIT_WIDTH];
  wire [N-1:0] c[BIT_WIDTH];

  genvar i;
  generate
    for (i = 0; i < BIT_WIDTH; i = i + 1) begin : gen_port_mapping
      assign a[i][0] = ax[i];
      assign a[i][1] = bx[i];
      assign b[i][0] = ay[i];
      assign b[i][1] = by[i];

      assign r1[i][0] = z0[i];
      assign r1[i][1] = z1[i];
      assign r2[i][0] = z2[i];

      assign qx[i] = c[i][0];
      assign qy[i] = c[i][1];

    end
  endgenerate


  // Secure and instantiaition
  dom_dep_multibit #(
      .D(D),
      .BIT_WIDTH(BIT_WIDTH)
  ) dom_dep_multibit (
      .clk(clk),
      .port_a(a),     // rs1_s0, rs1_s1
      .port_b(b),     // rs2_s0, rs2_s1
      .port_r1(r1),   // requires BIT_WIDTH * 2 bits randomness (|z0| + |z1| = 2*BIT_WIDTH) (dom-dep)
      .port_r2(r2),   // requires BIT_WIDTH bits randomness (dom-indep)
      .port_c(c)
  );


endmodule


//
// module: frv_masked_bitwise
//
//  Handles all bitwise operations inside the masked ALU. Individual results
//  are exposed so they can be re-used inside other functional units of the
//  masked ALU, namely the binary add/sub module.
//
module secure_frv_masked_bitwise #(
    parameter logic MASKING_ISE_DOM = 1'b1,
    parameter integer INSECURE_XOR  = 0,  // zero means INSECURE=FALSE -> Secure version is used
    parameter integer BIT_WIDTH     = 32
) (
    input  wire                 g_resetn, // TODO: remove this since it is not used?
    input  wire                 g_clk,
    input  wire                 ena,
    input  wire [BIT_WIDTH-1:0] i_remask0, //z0
    input  wire [BIT_WIDTH-1:0] i_remask1, //z1
    input  wire [BIT_WIDTH-1:0] i_remask2, //z4 //Fresh randomness, required for dom_dep_multibit
    input  wire [BIT_WIDTH-1:0] i_remask3, //z5 //Fresh randomness, required for masked xor
    input  wire [BIT_WIDTH-1:0] i_a0,
    input  wire [BIT_WIDTH-1:0] i_a1,
    input  wire [BIT_WIDTH-1:0] i_b0,
    input  wire [BIT_WIDTH-1:0] i_b1,
    output wire [BIT_WIDTH-1:0] o_xor0,
    output wire [BIT_WIDTH-1:0] o_xor1,
    output wire [BIT_WIDTH-1:0] o_and0,
    output wire [BIT_WIDTH-1:0] o_and1,
    output wire [BIT_WIDTH-1:0] o_ior0,
    output wire [BIT_WIDTH-1:0] o_ior1,
    output wire [BIT_WIDTH-1:0] o_not0,
    output wire [BIT_WIDTH-1:0] o_not1,
    output wire                 rdy
);

  // Masking ISE - Use a DOM Implementation (1) or not (0)

  //
  // AND
  // ------------------------------------------------------------

  generate
    if (MASKING_ISE_DOM == 1'b1) begin : gen_masking_DOM

      //
      // DOM Masked ABIT_WIDTHD
      frv_masked_and #(
          .BIT_WIDTH(BIT_WIDTH)
      ) i_dom_and (
          .g_clk (g_clk),
          .clk_en(ena),
          .z0    (i_remask0),
          .z1    (i_remask1),
          .z2    (i_remask2),
          .ax    (i_a0),
          .ay    (i_b0),
          .bx    (i_a1),
          .by    (i_b1),
          .qx    (o_and0),
          .qy    (o_and1)
      );

    end else begin : gen_no_masking

      //
      // Naieve masked AND

      assign o_and0 = i_remask0 ^ (i_a0 & i_b1) ^ (i_a0 | ~i_b0);
      assign o_and1 = i_remask0 ^ (i_a1 & i_b1) ^ (i_a1 | ~i_b0);

    end
  endgenerate

  //
  // XOR / IOR / NOT
  // ------------------------------------------------------------

  // XOR reference
  //
  // NOTE: in the glitch extended probing model it is pointless
  // to add or even reuse randomness without adding a register.
  // Reusing might actually violate security constrains,
  // since the plain randomness is learned which is used somewhere else.
  // Thus, if we need randomness here we have to add a additional register.
  // If this randomness is not required we can remove it.
  // Therefore, there is no point to use the reference case bellow.

  //assign o_xor0 = i_remask1 ^ i_a0 ^ i_b0;
  //assign o_xor1 = i_remask1 ^ i_a1 ^ i_b1;

  generate

    if (INSECURE_XOR == 0) begin : gen_secure_non_leaking_version
      // NOTE:  XOR with new randomness (i_remask3) and register (1.) -> SECURE
      wire [BIT_WIDTH-1:0] xor0, xor0_delayed;
      wire [BIT_WIDTH-1:0] xor1, xor1_delayed;

      assign xor0 = i_remask3 ^ i_a0 ^ i_b0;
      assign xor1 = i_remask3 ^ i_a1 ^ i_b1;

      register #(
          .N(BIT_WIDTH)
      ) delay_xor0 (
          .clk(g_clk),
          .d  (xor0),
          .q  (xor0_delayed)
      );
      register #(
          .N(BIT_WIDTH)
      ) delay_xor1 (
          .clk(g_clk),
          .d  (xor1),
          .q  (xor1_delayed)
      );

      assign o_xor0 = xor0_delayed;
      assign o_xor1 = xor1_delayed;
    end

    if (INSECURE_XOR == 2) begin : gen_leaking_by_exposing_one_share_of_two_bits
      // NOTE: XOR without any randomness (2.) -> LEAKING
      //
      assign o_xor0 = i_a0 ^ i_b0;
      assign o_xor1 = i_a1 ^ i_b1;
    end

    if (INSECURE_XOR == 3) begin : gen_leaking_by_exposing_xor_of_one_share_of_two_bits

      // NOTE: XOR without randomness, but with register (3.) ->

      wire [BIT_WIDTH-1:0] xor0, xor0_delayed;
      wire [BIT_WIDTH-1:0] xor1, xor1_delayed;

      assign xor0 = i_a0 ^ i_b0;
      assign xor1 = i_a1 ^ i_b1;

      register #(
          .N(BIT_WIDTH)
      ) delay_xor0 (
          .clk(g_clk),
          .d  (xor0),
          .q  (xor0_delayed)
      );
      register #(
          .N(BIT_WIDTH)
      ) delay_xor1 (
          .clk(g_clk),
          .d  (xor1),
          .q  (xor1_delayed)
      );

      assign o_xor0 = xor0_delayed;
      assign o_xor1 = xor1_delayed;
    end

    if (INSECURE_XOR == 4) begin : gen_leaking_reused_z0
      // NOTE: XOR with z0 reused and register added (4.)

      wire [BIT_WIDTH-1:0] xor0, xor0_delayed;
      wire [BIT_WIDTH-1:0] xor1, xor1_delayed;

      assign xor0 = i_remask0 ^ i_a0 ^ i_b0;
      assign xor1 = i_remask0 ^ i_a1 ^ i_b1;

      register #(
          .N(BIT_WIDTH)
      ) delay_xor0 (
          .clk(g_clk),
          .d  (xor0),
          .q  (xor0_delayed)
      );
      register #(
          .N(BIT_WIDTH)
      ) delay_xor1 (
          .clk(g_clk),
          .d  (xor1),
          .q  (xor1_delayed)
      );

      assign o_xor0 = xor0_delayed;
      assign o_xor1 = xor1_delayed;
    end

    if (INSECURE_XOR == 5) begin : gen_leaking_reused_z1
      // NOTE: XOR with z1 reused and register added (5.)
      wire [BIT_WIDTH-1:0] xor0, xor0_delayed;
      wire [BIT_WIDTH-1:0] xor1, xor1_delayed;

      assign xor0 = i_remask1 ^ i_a0 ^ i_b0;
      assign xor1 = i_remask1 ^ i_a1 ^ i_b1;

      register #(
          .N(BIT_WIDTH)
      ) delay_xor0 (
          .clk(g_clk),
          .d  (xor0),
          .q  (xor0_delayed)
      );
      register #(
          .N(BIT_WIDTH)
      ) delay_xor1 (
          .clk(g_clk),
          .d  (xor1),
          .q  (xor1_delayed)
      );

      assign o_xor0 = xor0_delayed;
      assign o_xor1 = xor1_delayed;
    end

    if (INSECURE_XOR == 8) begin : gen_leaking_reused_z4
      // NOTE: XOR with z4 reused and register added (8.)
      wire [BIT_WIDTH-1:0] xor0, xor0_delayed;
      wire [BIT_WIDTH-1:0] xor1, xor1_delayed;

      assign xor0 = i_remask2 ^ i_a0 ^ i_b0;
      assign xor1 = i_remask2 ^ i_a1 ^ i_b1;

      register #(
          .N(BIT_WIDTH)
      ) delay_xor0 (
          .clk(g_clk),
          .d  (xor0),
          .q  (xor0_delayed)
      );
      register #(
          .N(BIT_WIDTH)
      ) delay_xor1 (
          .clk(g_clk),
          .d  (xor1),
          .q  (xor1_delayed)
      );

      assign o_xor0 = xor0_delayed;
      assign o_xor1 = xor1_delayed;
    end
  endgenerate

  // IOR POST: reuse BOOL ABIT_WIDTHD to execute BoolIor
  assign o_ior0 = o_and0;
  assign o_ior1 = ~o_and1;

  assign o_not0 = i_a0;
  assign o_not1 = ~i_a1;

  // TODO: NOR is faster than and/or/xor if no double pumping is used.
  // Therefore, distinguish between both cases to safe one clock cycle?
//reg  [ 5:0] seq_cnt;
//always @(posedge g_clk)
 // if (!g_resetn)    seq_cnt <=6'd1;
  //else if (flush)   seq_cnt <=6'd1;
  //else if (rdy)     seq_cnt <=6'd1;
  //else if (ena)     seq_cnt <=seq_cnt << 1;

  parameter integer POS_EDG = 1;
  generate
  if (POS_EDG == 1) begin : gen_ready_signal_for_only_positive_clocks
    reg [1:0] ctr_ready;
    always @(posedge g_clk) begin
      //if (!g_resetn) ctr_ready <= 2'h1;
      if (rdy) ctr_ready  = 2'h1;
      else if (ena) ctr_ready  = ctr_ready << 1;
      else ctr_ready = 2'h1;
    end
    assign rdy = ctr_ready[1];
  end else begin : gen_ready_signal_for_double_pumped_clocks
    assign rdy = ena;
  end
  endgenerate

endmodule
