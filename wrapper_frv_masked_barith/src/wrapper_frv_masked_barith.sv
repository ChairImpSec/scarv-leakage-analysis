
module wrapper_frv_masked_barith #(
    parameter integer BIT_WIDTH = 32
) (
    input  wire                 g_clk,
    input  wire                 g_resetn,
    input  wire                 flush,     // Flush the masked ALU.
    input  wire                 valid,     // Inputs valid
    input  wire                 op_add,
    input  wire                 op_sub,
    input  wire [BIT_WIDTH-1:0] z0,        // Fresh randomness -> prng0
    input  wire [BIT_WIDTH-1:0] z1,        // Fresh randomness -> prng1
    input  wire [BIT_WIDTH-1:0] z2,        // Fresh randomness -> n_prng0
    input  wire [BIT_WIDTH-1:0] z3,        // Fresh randomness -> n_prng1
    input  wire [BIT_WIDTH-1:0] z4,        // Fresh randomness additional dom_dep randomness
    input  wire [BIT_WIDTH-1:0] z5,        // Fresh randomness additional xor randomness
    input  wire [BIT_WIDTH-1:0] rs1_s0,
    input  wire [BIT_WIDTH-1:0] rs1_s1,
    input  wire [BIT_WIDTH-1:0] rs2_s0,
    input  wire [BIT_WIDTH-1:0] rs2_s1,
    output wire [BIT_WIDTH-1:0] rd_s0,
    output wire [BIT_WIDTH-1:0] rd_s1,
    output wire        ready                // Outputs ready
);

  parameter integer MASKING_ISE_DOM = 1;
  parameter integer ENABLE_BARITH   = 1;

  parameter integer D = 1;
  parameter integer N = D + 1;

  wire op_b_not = 0;
  wire op_b_xor = 0;
  wire op_b_and = 0;
  wire op_b_ior = 0;
  wire op_shr   = 0;
  wire op_b_add = op_add;
  wire op_b_sub = op_sub;
  wire op_a2b   = 0;
  wire op_b2a   = 0;
  wire op_msk   = 0;
  wire op_amsk  = 0;
  wire op_f_mul = 0;
  wire op_f_sqr = 0;
  wire op_f_aff = 0;

  wire addsub_ena;
  //
  // Operand Setup
  // ------------------------------------------------------------


  wire nrs2_opt = (op_b_ior || op_b_sub);

  wire [XL:0] op_a0, op_a1, op_b0, op_b1;

  assign op_a0 = rs1_s0;
  assign op_a1 = op_b_ior ? ~rs1_s1 : op_b2a ? rs1_s1 : op_a2b ? {XLEN{1'b0}} : rs1_s1;

  assign op_b0 = {XLEN{!(op_b2a || op_a2b)}} & rs2_s0;

  // NOTE: op_b2a = 0 => b2a_b1 is not used => thus we can map it to zero,
  // to avoid to include parts of the conversion logic in this part here,
  // which is not part of the barith unit.

  wire [XL:0] b2a_b1 = {XLEN{1'b0}};

  assign op_b1 = nrs2_opt ? ~rs2_s1 : op_b2a ? b2a_b1 : op_a2b ? ~rs1_s1 : rs2_s1;

  //
  // Bitwise Operations.
  // ------------------------------------------------------------

  wire [XL:0] mxor0, mxor1;
  wire [XL:0] mand0, mand1;
  wire [XL:0] mior0, mior1;
  wire [XL:0] mnot0, mnot1;

  // Control unit for Boolean masked calculations
  wire dologic = !flush && (op_b_xor || op_b_and || op_b_ior || op_b_not); // 0
  wire op_b_addsub = !flush && (op_b_add || op_b_sub || op_b2a || op_a2b); // 1

  reg  ctrl_do_arith;


  assign addsub_ena = valid && op_b_addsub; // = valid

  always @(posedge g_clk) begin
      if(!g_resetn || (valid && ready)) begin
          ctrl_do_arith   <= 1'b0;
      end else if(valid) begin
          ctrl_do_arith   <= dologic || op_b_addsub;
      end
  end

  wire mlogic_ena = valid && (dologic || op_b_addsub) && !ctrl_do_arith;
  wire mlogic_rdy;

  // BOOL XOR; BOOL AND: Boolean masked logic executes BoolXor; BoolAnd;
  secure_frv_masked_bitwise #(
      .MASKING_ISE_DOM(MASKING_ISE_DOM)
  ) msklogic_ins (
      .g_resetn(g_resetn),
      .g_clk(g_clk),
      .ena(mlogic_ena),
      .i_remask0(z0),
      .i_remask1(z1),
      .i_remask2(z4),// NOTE: this could be broken! it depends on how the randomness is created
      .i_remask3(z5),// NOTE: this could be broken! it depends on how the randomness is created
      .i_a0(op_a0),
      .i_a1(op_a1),
      .i_b0(op_b0),
      .i_b1(op_b1),
      .o_xor0(mxor0),
      .o_xor1(mxor1),
      .o_and0(mand0),
      .o_and1(mand1),
      .o_ior0(mior0),
      .o_ior1(mior1),
      .o_not0(mnot0),
      .o_not1(mnot1),
      .rdy(mlogic_rdy)
  );



  //
  // Arithmetic Operations.
  // ------------------------------------------------------------

  // A2B PRE: reuse the boolean masked add/sub to execute arithmetic masking to Boolean masking instruction
  // expected:rs0 - rs1 = rd0 ^ rd1
  // BoolSub: (a0 ^ a1) - (b0 ^ b1) = s0 ^ s1  st. s = a-b
  //=>
  // a0 = rs0;  a1= 0;      b0 = prng; b1= rs1 ^ prng
  //rd0 = s0;              rd1 = s1

  wire madd_rdy;
  wire [XL:0] madd0, madd1;


  // SUB OPT: execute the operations at line 5 & 6 in the BoolSub algorithm.
  wire        sub = op_b_sub || op_a2b;
  wire        u_0 = mand0[0] ^ (mxor0[0] && sub); // FIXME: here we might get leakage!
  wire        u_1 = mand1[0] ^ (mxor1[0] && sub); // FIXME: here we might get leakage!
  wire [XL:0] s_mand0 = {mand0[XL:1], u_0};
  wire [XL:0] s_mand1 = {mand1[XL:1], u_1};



  reg ctrl_do_addsub;

  always @(posedge g_clk) begin
    if (!g_resetn || (valid && madd_rdy)) begin
      ctrl_do_addsub <= 1'b0;
    end else if (addsub_ena && (op_b_addsub && !op_b2a)) begin
      ctrl_do_addsub <= 1'b1;
    end else if (addsub_ena && (op_b_addsub && op_b2a && mlogic_rdy)) begin
      ctrl_do_addsub <= 1'b1;
    end
  end

  generate
    if (ENABLE_BARITH) begin : gen_masked_barith_enabled

      // BOOL ADD/SUB ITERATION and BOOL ADD/SUB POST
      secure_frv_masked_barith #(
          .MASKING_ISE_DOM(MASKING_ISE_DOM)
      ) mskaddsub_ins (
          .g_resetn(g_resetn),
          .g_clk   (g_clk),
          .flush   (flush),
          .ena     (ctrl_do_addsub),
          .sub     (sub),
          .i_gs0   (z2),
          .i_gs1   (z3),
          .mxor0   (mxor0),
          .mxor1   (mxor1),
          .mand0   (s_mand0),
          .mand1   (s_mand1),
          .o_s0    (madd0),
          .o_s1    (madd1),
          .rdy     (madd_rdy)
      );

    end else begin : gen_masked_barith_disabled

      assign madd0    = 32'b0;
      assign madd1    = 32'b0;
      assign madd_rdy = addsub_ena;

    end
  endgenerate

  //
  // OUTPUT MUX: gather and multiplexing results
  // ------------------------------------------------------------
  //

  // NOTE: mshr0/mshr1 can be zeroed,
  // since it is used for shift modules which are not part of this investigations
  wire [XL:0] mshr0 = {XLEN{1'b0}};
  wire [XL:0] mshr1 = {XLEN{1'b0}};

  // NOTE: mb2a0/mb2a1 can be zeroed,
  // since it is used for for boolean to arithmetic masking which is disabled for this
  // investigation
  wire [XL:0] mb2a0 = {XLEN{1'b0}};
  wire [XL:0] mb2a1 = {XLEN{1'b0}};

  // NOTE: the following blocks are zerod, since coresponding opcode is never 1.

  wire [XL:0] rmask0 = {XLEN{1'b0}};
  wire [XL:0] amsk0 = {XLEN{1'b0}};
  wire [XL:0] mfmul0 = {XLEN{1'b0}};
  wire [XL:0] mfaff0 = {XLEN{1'b0}};

  wire [XL:0] rmask1 = {XLEN{1'b0}};
  wire [XL:0] amsk1 = {XLEN{1'b0}};
  wire [XL:0] mfmul1 = {XLEN{1'b0}};
  wire [XL:0] mfaff1 = {XLEN{1'b0}};

  wire shr_rdy = 1'b0;
  wire msk_rdy = 1'b0;
  wire amsk_rdy= 1'b0;
  wire mskfield_rdy = 1'b0;

  //
  // Here we introduce some leakage too, since probing rd_s0
  // directly reveals via the xor information about z1, rs2_s0 and rs1_s0.
  // Furthermore, the output of the adder contains information
  // about the other shares.
  // Therefore, it might be possible to reconstruct the shared bit(s)
  //

  assign rd_s0 =
                {XLEN{op_b_not}} &  mnot0 |
                {XLEN{op_b_xor}} &  mxor0 |
                {XLEN{op_b_and}} &  mand0 |
                {XLEN{op_b_ior}} &  mior0 |
                {XLEN{op_shr  }} &  mshr0 |
                {XLEN{op_b_add}} &  madd0 |
                {XLEN{op_b_sub}} &  madd0 |
                {XLEN{op_a2b  }} &  madd0 |
                {XLEN{op_b2a  }} &  mb2a0 |
                {XLEN{op_msk  }} &  rmask0|
                {XLEN{op_amsk }} &  amsk0 |
                {XLEN{op_f_mul}} &  mfmul0|
                {XLEN{op_f_sqr}} &  mfmul0|
                {XLEN{op_f_aff}} &  mfaff0;

  assign rd_s1 =
                {XLEN{op_b_not}} &  mnot1 |
                {XLEN{op_b_xor}} &  mxor1 |
                {XLEN{op_b_and}} &  mand1 |
                {XLEN{op_b_ior}} &  mior1 |
                {XLEN{op_shr  }} &  mshr1 |
                {XLEN{op_b_add}} &  madd1 |
                {XLEN{op_b_sub}} &  madd1 |
                {XLEN{op_a2b  }} &  madd1 |
                {XLEN{op_b2a  }} &  mb2a1 |
                {XLEN{op_msk  }} &  rmask1|
                {XLEN{op_amsk }} &  amsk1 |
                {XLEN{op_f_mul}} &  mfmul1|
                {XLEN{op_f_sqr}} &  mfmul1|
                {XLEN{op_f_aff}} &  mfaff1;

  assign ready =
               (dologic && mlogic_rdy) ||
               // madd_rdy || shr_rdy || msk_rdy ||
               ((op_b_sub || op_b_add) && madd_rdy) || shr_rdy || msk_rdy ||
               amsk_rdy || mskfield_rdy;

endmodule
