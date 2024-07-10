// Common core parameters and constants
//`include "frv_common.vh"
//

// Single flip flop used by masked ALU modules etc.
//

module FF_Nb #(
    parameter integer Nb  = 1,
    parameter logic   EDG = 1
) (
    input wire g_resetn,
    g_clk,
    input wire ena,
    input wire [Nb-1:0] din,
    output reg [Nb-1:0] dout
);

  generate
    if (EDG == 1'b1) begin : gen_posedge_ff
      always @(posedge g_clk) begin
        if (!g_resetn) dout <= {Nb{1'b0}};
        else if (ena) dout <= din;
      end
    end else begin : gen_negedge_ff
      always @(negedge g_clk) begin
        if (!g_resetn) dout <= {Nb{1'b0}};
        else if (ena) dout <= din;
      end
    end
  endgenerate

endmodule


//
// module frv_masked_alu
//
//  Responsible for performing masking operations.
//
module secure_frv_masked_alu (

    input wire g_clk,    // Global clock
    input wire g_resetn, // Synchronous, active low reset.

    input wire valid,  // Inputs valid
    input wire flush,  // Flush the masked ALU.

    input wire op_b2a,       // Binary to arithmetic mask covert
    input wire op_a2b,       // Arithmetic to binary mask convert
    input wire op_b_mask,    // Binary mask
    input wire op_b_remask,  // Binary remask
    input wire op_a_mask,    // Arithmetic mask
    input wire op_a_remask,  // Arithmetic remask
    input wire op_b_not,     // Binary masked not
    input wire op_b_and,     // Binary masked and
    input wire op_b_ior,     // Binary masked or
    input wire op_b_xor,     // Binary masked xor
    input wire op_b_add,     // Binary masked addition
    input wire op_b_sub,     // Binary masked subtraction
    input wire op_b_srli,    // Shift right, shamt in msk_rs2_s0
    input wire op_b_slli,    // Shift left, shamt in msk_rs2_s0
    input wire op_b_rori,    // Shift right, shamt in msk_rs2_s0
    input wire op_a_add,     // Masked arithmetic add
    input wire op_a_sub,     // Masked arithmetic subtract.
    input wire op_f_mul,     // Finite field multiply
    input wire op_f_aff,     // Affine transform
    input wire op_f_sqr,     // Squaring

    input wire prng_update,  // Force the PRNG to update.

    input wire [XL:0] rs1_s0,  // RS1 Share 0
    input wire [XL:0] rs1_s1,  // RS1 Share 1
    input wire [XL:0] rs2_s0,  // RS2 Share 0
    input wire [XL:0] rs2_s1,  // RS2 Share 1

    // NOTE: added random inputs
    input wire [XL:0] z0_in,
    input wire [XL:0] z1_in,
    input wire [XL:0] z2_in,
    input wire [XL:0] z3_in,
    input wire [XL:0] z4_in,
    input wire [XL:0] z5_in,

    output wire        ready,  // Outputs ready
    output wire [XL:0] rd_s0,  // Output share 0
    output wire [XL:0] rd_s1   // Output share 1

);
  //parameter integer ADD_ONLY = 0;

wire s_op_b2a     ;
wire s_op_a2b     ;
wire s_op_b_mask  ;
wire s_op_b_remask;
wire s_op_a_mask  ;
wire s_op_a_remask;
wire s_op_b_not   ;
wire s_op_b_and   ;
wire s_op_b_ior   ;
wire s_op_b_xor   ;
wire s_op_b_add   ;
wire s_op_b_sub   ;
wire s_op_b_srli  ;
wire s_op_b_slli  ;
wire s_op_b_rori  ;
wire s_op_a_add   ;
wire s_op_a_sub   ;
wire s_op_f_mul   ;
wire s_op_f_aff   ;
wire s_op_f_sqr   ;

/*
generate
  if (ADD_ONLY == 1) begin : gen_is_adder_secure
    assign s_op_b2a     = 0;       // Binary to arithmetic mask covert
    assign s_op_a2b     = 0;       // Arithmetic to binary mask convert
    assign s_op_b_mask  = 0;    // Binary mask
    assign s_op_b_remask= 0;  // Binary remask
    assign s_op_a_mask  = 0;    // Arithmetic mask
    assign s_op_a_remask= 0;  // Arithmetic remask
    assign s_op_b_not   = 0;     // Binary masked not
    assign s_op_b_and   = 0;     // Binary masked and
    assign s_op_b_ior   = 0;     // Binary masked or
    assign s_op_b_xor   = 0;     // Binary masked xor
    assign s_op_b_add   = op_b_add;     // Binary masked addition
    assign s_op_b_sub   = 0;     // Binary masked subtraction
    assign s_op_b_srli  = 0;    // Shift right, shamt in msk_rs2_s0
    assign s_op_b_slli  = 0;    // Shift left, shamt in msk_rs2_s0
    assign s_op_b_rori  = 0;    // Shift right, shamt in msk_rs2_s0
    assign s_op_a_add   = 0;     // Masked arithmetic add
    assign s_op_a_sub   = 0;     // Masked arithmetic subtract.
    assign s_op_f_mul   = 0;     // Finite field multiply
    assign s_op_f_aff   = 0;     // Affine transform
    assign s_op_f_sqr   = 0;     // Squaring
  end
  else begin : gen_full_alu
    */
    assign s_op_b2a     = op_b2a     ;       // Binary to arithmetic mask covert
    assign s_op_a2b     = op_a2b     ;       // Arithmetic to binary mask convert
    assign s_op_b_mask  = op_b_mask  ;    // Binary mask
    assign s_op_b_remask= op_b_remask;  // Binary remask
    assign s_op_a_mask  = op_a_mask  ;    // Arithmetic mask
    assign s_op_a_remask= op_a_remask;  // Arithmetic remask
    assign s_op_b_not   = op_b_not   ;     // Binary masked not
    assign s_op_b_and   = op_b_and   ;     // Binary masked and
    assign s_op_b_ior   = op_b_ior   ;     // Binary masked or
    assign s_op_b_xor   = op_b_xor   ;     // Binary masked xor
    assign s_op_b_add   = op_b_add   ;     // Binary masked addition
    assign s_op_b_sub   = op_b_sub   ;     // Binary masked subtraction
    assign s_op_b_srli  = op_b_srli  ;    // Shift right, shamt in msk_rs2_s0
    assign s_op_b_slli  = op_b_slli  ;    // Shift left, shamt in msk_rs2_s0
    assign s_op_b_rori  = op_b_rori  ;    // Shift right, shamt in msk_rs2_s0
    assign s_op_a_add   = op_a_add   ;     // Masked arithmetic add
    assign s_op_a_sub   = op_a_sub   ;     // Masked arithmetic subtract.
    assign s_op_f_mul   = op_f_mul   ;     // Finite field multiply
    assign s_op_f_aff   = op_f_aff   ;     // Affine transform
    assign s_op_f_sqr   = op_f_sqr   ;     // Squaring
    /*
  end
endgenerate
*/

  //parameter integer PROLEAD_SIM = 1;

  wire [XL:0] madd0, madd1;

  wire [XL:0] b2a_a0;
  wire [XL:0] b2a_b0;

  wire [XL:0] b2a_b1;
  //wire [XL:0] b2a_b1_lat;

  //
  // Masking ISE - Use a TRNG (1) or a PRNG (0)
  parameter logic MASKING_ISE_TRNG = 1'b0;

  // Masking ISE - Use a DOM Implementation (1) or not (0)
  parameter logic MASKING_ISE_DOM = 1'b1;

  // Enable finite-field instructions (or not).
  parameter logic ENABLE_FAFF = 0;
  parameter logic ENABLE_FMUL = 0;

  // Enable the binary masked add/sub instructions
  parameter logic ENABLE_BARITH = 1;

  // Enable the arithmetic masked instructions
  parameter logic ENABLE_ARITH = 0;

  //
  // PRNG LFSRs for new masks.
  // ------------------------------------------------------------

  wire [XL:0] prng0;
  wire [XL:0] n_prng0;
  wire [XL:0] prng1;
  wire [XL:0] n_prng1;
  wire [XL:0] prng2;
  wire [XL:0] n_prng2;

  // NOTE: the following signals are introduced to use the same
  // naming in sketch and here (in the actual implementation)
  //
  wire [XL:0] z0;
  wire [XL:0] z1;
  wire [XL:0] z2;
  wire [XL:0] z3;
  wire [XL:0] z4;
  wire [XL:0] z5;

  // NOTE: this is how it was mapped before I added my changes
  //assign z0 = prng0;
  //assign z2 = n_prng0;
  //assign z1 = prng1;
  //assign z3 = n_prng1;
  //assign z4 = n_prng0;
  //TODO: assign z5 = n_prng1


  // NOTE: New mapping with additional lfsr32
  /*
  generate
    if (PROLEAD_SIM == 1) begin : gen_with_prolead_randomness
*/
      assign z0 = z0_in;
      assign z1 = z1_in;
      assign z2 = z2_in;
      assign z3 = z3_in;
      assign z4 = z4_in;
      assign z5 = z5_in;
/*
    end else begin : gen_lfsr_randomness_reference
      assign z0 = prng0;
      assign z2 = n_prng0;
      assign z1 = prng1;
      assign z3 = n_prng1;
      assign z4 = prng2;
      assign z5 = n_prng2;

      wire xtap0;
      wire xtap1;
      wire xtap2;

      frv_lfsr32 #(
          .RESET_VALUE(32'h6789ABCD)
      ) i_lfsr32_0 (
          .g_clk    (g_clk),        // Clock to update PRNG
          .g_resetn (g_resetn),     // Syncrhonous active low reset.
          .update   (prng_update),  // Update PRNG with new value.
          .extra_tap(xtap0),        // Additional seed bit, possibly from TRNG.
          .prng     (prng0),        // Current PRNG value.
          .n_prng   (n_prng0)       // Next    PRNG value.
      );

      frv_lfsr32 #(
          .RESET_VALUE(32'h87654321)
      ) i_lfsr32_1 (
          .g_clk    (g_clk),        // Clock to update PRNG
          .g_resetn (g_resetn),     // Syncrhonous active low reset.
          .update   (prng_update),  // Update PRNG with new value.
          .extra_tap(xtap1),        // Additional seed bit, possibly from TRNG.
          .prng     (prng1),        // Current PRNG value.
          .n_prng   (n_prng1)       // Next    PRNG value.
      );

      // NOTE: introduced to be able to use given testbench of the whole core
      frv_lfsr32 #(
          .RESET_VALUE(32'hc0cac01a)
      ) i_lfsr32_2 (
          .g_clk    (g_clk),        // Clock to update PRNG
          .g_resetn (g_resetn),     // Syncrhonous active low reset.
          .update   (prng_update),  // Update PRNG with new value.
          .extra_tap(xtap2),        // Additional seed bit, possibly from TRNG.
          .prng     (prng2),        // Current PRNG value.
          .n_prng   (n_prng2)       // Next    PRNG value.
      );

      if (MASKING_ISE_TRNG) begin : gen_TRNG_enabled

        // wire [1:0] trng_bit, trng_rdy; // original one
        wire [2:0] trng_bit, trng_rdy;  // NOTE: to integrate my changes in tb
        frv_trng #(
            //.Nb (2),  // number of random bit (original)
            .Nb (3),  // number of random bit  (modified)
            .Ne (3),  // number of entropy sources per bit
            .ORD(3)   // filter order
        ) i_trng_0 (
            .g_clk   (g_clk),     // Clock to update PRNG
            .g_resetn(g_resetn),  // Syncrhonous active low reset.
            .gen     (1'b1),      // countinously generate random bits
            .rnb     (trng_bit),
            .rdy     (trng_rdy)
        );

        assign xtap0 = trng_rdy[0] & trng_bit[0];
        assign xtap1 = trng_rdy[1] & trng_bit[1];
        // NOTE: added to be able to use given testbench to verify results
        assign xtap2 = trng_rdy[2] & trng_bit[2];

      end else begin : gen_TRNG_disabled

        assign xtap0 = 1'b0;
        assign xtap1 = 1'b0;
        assign xtap2 = 1'b0;

      end
    end
  endgenerate

  */
  //
  // Operand Setup
  // ------------------------------------------------------------

  wire nrs2_opt = (s_op_b_ior || s_op_b_sub);
  wire [XL:0] op_a0, op_a1, op_b0, op_b1;


  assign op_a0 = rs1_s0;
  assign op_a1 = s_op_b_ior ? ~rs1_s1 : s_op_b2a ? rs1_s1 : s_op_a2b ? {XLEN{1'b0}} : rs1_s1;

  assign op_b0 = ({XLEN{s_op_b2a}} & b2a_b0) | ({XLEN{!(s_op_b2a || s_op_a2b)}} & rs2_s0);

  assign op_b1 = nrs2_opt ? ~rs2_s1 : s_op_b2a ? b2a_b1 : s_op_a2b ? ~rs1_s1 : rs2_s1;

  //
  // Bitwise Operations.
  // ------------------------------------------------------------

  wire [XL:0] mxor0, mxor1;
  wire [XL:0] mand0, mand1;
  wire [XL:0] mior0, mior1;
  wire [XL:0] mnot0, mnot1;

  // Control unit for Boolean masked calculations
  wire dologic = !flush && (s_op_b_xor || s_op_b_and || s_op_b_ior || s_op_b_not);
  wire op_b_addsub = !flush && (s_op_b_add || s_op_b_sub || s_op_b2a || s_op_a2b);

  reg  ctrl_do_arith;

  wire mlogic_ena = valid && (dologic || op_b_addsub) && !ctrl_do_arith;
  wire mlogic_rdy;

  // BOOL XOR; BOOL AND: Boolean masked logic executes BoolXor; BoolAnd;
  secure_frv_masked_bitwise #(
      .MASKING_ISE_DOM(MASKING_ISE_DOM)
  ) msklogic_ins (
      .g_resetn(g_resetn),
      .g_clk(g_clk),
      .ena(mlogic_ena),
      .i_remask0(z0),  // z0
      .i_remask1(z1),  // z1
      .i_remask2(z4),  // z4
      .i_remask3(z5),  // z5 - Fresh randomness, required for masked xor
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
  // Binary -> Arithmetic re-masking Operations.
  // ------------------------------------------------------------

  // B2A PRE: reuse the boolean masked add/sub to execute Boolean masking to arithmetic masking instruction
  // Expected:rs0 ^ rs1 = rd0 - rd1
  // BoolAdd: (a0 ^ a1) + (b0 ^ b1) = (a+b)^z ^ z st. s = a+b
  //=>
  // a0 = rs0;  a1=rs1;     b0 = prng ; b1=0
  //rd0 = s0 ^ s1;         rd1 = prng
  // keep b2a_b1 unchanging during B2A process
  assign b2a_a0 = rs1_s0;
  //wire [XL:0] b2a_b0 = {XLEN{1'b0}};

  wire [XL:0] b2a_b1_lat;
  wire        b2a_ini = s_op_b2a && mlogic_ena;

  FF_Nb #(
      .Nb(XLEN)
  ) ff_b2a_b0 (
      .g_resetn(g_resetn),
      .g_clk   (g_clk),
      .ena     (b2a_ini),
      .din     (b2a_b1),
      .dout    (b2a_b1_lat)
  );

  // in the reference implementation n_prng0 and n_prng1 are used co compute
  // b2a_gs.
  // both are not used in the bitwise module, but in the barith module.

  // FIXME: z2 ^ z3 is exposed via mb2a1 if b2a is not performed,
  // might be a small problem!
  wire [XL:0] b2a_gs = z2 ^ z3; // reference
  //assign b2a_b1 = mlogic_ena ? b2a_gs : b2a_b1_lat; // reference
  assign b2a_b1 = (mlogic_ena ? b2a_gs : b2a_b1_lat) & s_op_b2a;
  assign b2a_b0 = {XLEN{1'b0}}; //mlogic_ena ? b2a_gs0 : b2a_b1_lat0;
  //wire [XL:0] mb2a1 = b2a_b0 ^ b2a_b1;
  //


  // B2A POST: calculate the ouput of Bool2Arith from the output of BoolAdd
  // calculate output only if the b2a instruction is executed
  // to avoid unintentionally unmasking the output of masked add/sub module
  wire op_b2a_latched;  //prevent any glitches on the s_op_b2a

  FF_Nb ff_dob2a (
      .g_resetn(g_resetn),
      .g_clk   (g_clk),
      .ena     (valid),
      .din     (s_op_b2a),
      .dout    (op_b2a_latched)
  );

  // NOTE:
  // This block is mendatory to prevent lekage (...sync signals prevent lekage)
  // if the b2a operation is computed. Since the xor of the both outputs of the
  // adder exposes temporary signals of both shares.
  // This temporary signals causes leakage.
  // Therefore the registers are introduced which are only enabled when the
  // result of the adder is stable.
  // Additionaly, the registers together with the madd$_gated wires might help
  // to prevent leakage in combination with the outputs of all the other
  // operations.
  // Without the register & the gated wires the normal add operation
  // would reveal both shares of the add and would therefore leak.

  // FIXME: Do we gain something by setting this to z0 instead of just '0'
  //wire [XL:0] madd0_gated = op_b2a_latched ? madd0 : z0;
  //wire [XL:0] madd1_gated = op_b2a_latched ? madd1 : z0;
  wire [XL:0] madd0_gated = op_b2a_latched ? madd0 : {XLEN{1'b0}};
  wire [XL:0] madd1_gated = op_b2a_latched ? madd1 : {XLEN{1'b0}};
  wire [XL:0] madd0_gated_sync;
  wire [XL:0] madd1_gated_sync;


  wire        madd_rdy;

  /*
  FF_Nb #(
      .Nb(XLEN)
  ) ff_mb2a0_out (
      .g_resetn(g_resetn),
      .g_clk   (g_clk),
      .ena     (madd_rdy),
      .din     (madd0_gated),
      .dout    (madd0_gated_sync)
  );

  FF_Nb #(
      .Nb(XLEN)
  ) ff_mb2a1_out (
      .g_resetn(g_resetn),
      .g_clk   (g_clk),
      .ena     (madd_rdy),
      .din     (madd1_gated),
      .dout    (madd1_gated_sync)
  );
  */

  register_with_sync_reset #(.BITWIDTH(XLEN)) reg_mb2a0_out_v2 (
    .clk(g_clk),
    .rst(!((s_op_b2a) & madd_rdy)),
    .d(madd0_gated),
    .q(madd0_gated_sync)
  );

  register_with_sync_reset #(.BITWIDTH(XLEN)) reg_mb2a1_out_v2 (
    .clk(g_clk),
    .rst(!((s_op_b2a) & madd_rdy)),
    .d(madd1_gated),
    .q(madd1_gated_sync)
  );

  wire [XL:0] mb2a0 = madd0_gated_sync ^ madd1_gated_sync;
  wire [XL:0] mb2a1 = b2a_b0 ^ b2a_b1;


  //
  // Arithmetic Operations.
  // ------------------------------------------------------------

  // A2B PRE: reuse the boolean masked add/sub to execute arithmetic masking to Boolean masking instruction
  // expected:rs0 - rs1 = rd0 ^ rd1
  // BoolSub: (a0 ^ a1) - (b0 ^ b1) = s0 ^ s1  st. s = a-b
  //=>
  // a0 = rs0;  a1= 0;      b0 = prng; b1= rs1 ^ prng
  //rd0 = s0;              rd1 = s1



  wire        addsub_ena;

  // SUB OPT: execute the operations at line 5 & 6 in the BoolSub algorithm.
  wire        sub = s_op_b_sub || s_op_a2b;
  wire        u_0 = mand0[0] ^ (mxor0[0] && sub);
  wire        u_1 = mand1[0] ^ (mxor1[0] && sub);
  wire [XL:0] s_mand0 = {mand0[XL:1], u_0};
  wire [XL:0] s_mand1 = {mand1[XL:1], u_1};



  //reg ctrl_do_addsub;
  reg [2:0] ctrl_do_addsub;
  wire ctrl_do_addsub_o;

  always @(posedge g_clk) begin
    if (!g_resetn || (valid && madd_rdy)) begin
      //ctrl_do_addsub <= 0;
      ctrl_do_addsub <= 3'b001;
    end else if (addsub_ena && (op_b_addsub && !s_op_b2a) && (ctrl_do_addsub[2]!=1)) begin
      // ADD
      //ctrl_do_addsub <= 1;
      ctrl_do_addsub <= ctrl_do_addsub << 1;
    end else if (addsub_ena && (op_b_addsub && s_op_b2a && mlogic_rdy)&& (ctrl_do_addsub[2]!=1)) begin
      // B2A
      //ctrl_do_addsub <= 1;
      ctrl_do_addsub <= ctrl_do_addsub << 1;
    end
  end
  // NOTE: This trick with the shift register was required to ensure that the
  // bartih unit respects the additional delay wich is required to isolate
  // independent modules by a mutable register (always zero, only value if
  // computation for opcode which is set is completed).
  // This mutable register is not required if the barith unit is used to compute
  // the add part of the b2a operation,
  // thus we use ctrl_do_addsub[2:1] to compress the additonal delay.

  //assign ctrl_do_addsub_o = (s_op_b_add || s_op_b_sub) ? (|ctrl_do_addsub[2]) :
  //  (ctrl_do_addsub[2:1]) ;

  assign ctrl_do_addsub_o = (s_op_b_add || s_op_b_sub) ? (ctrl_do_addsub[2]) :
    (|ctrl_do_addsub[2:1]) ;
  generate

    if (ENABLE_BARITH) begin : gen_masked_barith_enabled

      // BOOL ADD/SUB ITERATION and BOOL ADD/SUB POST
      secure_frv_masked_barith #(
          .MASKING_ISE_DOM(MASKING_ISE_DOM)
      ) mskaddsub_ins (
          .g_resetn(g_resetn),
          .g_clk   (g_clk),
          .flush   (flush),
          .ena     (ctrl_do_addsub_o),
          //.ena     (ctrl_do_addsub),
          .sub     (sub),
          .i_gs0   (z2),              // z2
          .i_gs1   (z3),              // z3
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
  // Shift and rotate operations.
  // ------------------------------------------------------------

  wire       op_shr;
  wire       shr_rdy;
  wire [4:0] shamt;

  // Result shares of shift/rotate operations.
  wire [XL:0] mshr0, mshr1;

  assign shamt = rs2_s0[4:0];
  assign op_shr  = s_op_b_srli || s_op_b_slli || s_op_b_rori;

  wrapper_frv_masked_shfrot shfrpt_ins (
    .clk(g_clk),
    .srli(s_op_b_srli),
    .slli(s_op_b_slli),
    .rori(s_op_b_rori),
    .ena(op_shr),
    .shamt(shamt),
    .s0(rs1_s0),
    .s1(rs1_s1),
    .rp0(z0),
    .r0(mshr0),
    .r1(mshr1),
    .ready(shr_rdy)
    );

  /*
  * NOTE: Reference Code
  *

  assign       op_shr = s_op_b_srli || s_op_b_slli || s_op_b_rori;
  assign       shr_rdy = valid & op_shr;

  // Shifter for share 0
  frv_masked_shfrot shfrpt_ins0 (
      .s    (rs1_s0),
      .shamt(shamt),      // Shift amount
      .rp   (z0),      // random padding
      .srli (s_op_b_srli),  // Shift  right
      .slli (s_op_b_slli),  // Shift  left
      .rori (s_op_b_rori),  // Rotate right
      .r    (mshr0)
  );

  // Shifter for share 1
  frv_masked_shfrot shfrpt_ins1 (
      .s    (rs1_s1),
      .shamt(shamt),      // Shift amount
      .rp   (z0),      // random padding
      .srli (s_op_b_srli),  // Shift  right
      .slli (s_op_b_slli),  // Shift  left
      .rori (s_op_b_rori),  // Rotate right
      .r    (mshr1)
  );
  */

  //
  // MASK   / REMASK: Boolean masking and remasking
  // ------------------------------------------------------------

  parameter integer SECURE_MASKING_OPERATION = 2;

  wire opmask = !flush && s_op_b_mask;  //masking operation
  wire remask = !flush && s_op_b_remask;

  wire op_msk = opmask || remask;
  wire [XL:0] rmask0;
  wire [XL:0] rmask1;
  wire msk_rdy;

  generate
    if (SECURE_MASKING_OPERATION == 0) begin : gen_reference_masking_operation
      // NOTE: INSECURE version
      assign rmask0  = z0 ^ rs1_s0;
      assign rmask1  = z0 ^ ({XLEN{remask}} & rs1_s1);
      assign msk_rdy = valid & op_msk;
    end else if (SECURE_MASKING_OPERATION == 1) begin : gen_new_randomness_masking
      assign rmask0  = z5 ^ rs1_s0;
      assign rmask1  = z5 ^ ({XLEN{remask}} & rs1_s1);
      assign msk_rdy = valid & op_msk;
    end else if (SECURE_MASKING_OPERATION == 2) begin : gen_new_rand_and_reg_mask
      // NOTE: This is not evaluated with prolead,
      // but functional correctness is checked!
      // This version introduces a synchron resetted register,
      // which is a dirty hack to make all module outputs independent from each
      // other.

      //reg msk_rdy_delayed;
      wire [XL:0] remask0_in;
      wire [XL:0] remask1_in;

      assign remask0_in = z5 ^ rs1_s0;
      assign remask1_in = z5 ^ ({XLEN{remask}} & rs1_s1);
      //assign msk_rdy = msk_rdy_delayed;

      register_with_sync_reset #(
          .BITWIDTH(XLEN)
      ) delay_remask0 (
          .clk(g_clk),
          //.rst(!((s_op_b_mask|s_op_b_remask) & msk_rdy)),
          .rst(!((s_op_b_mask|s_op_b_remask) & (valid & op_msk))),
          .d  (remask0_in),
          .q  (rmask0)
      );
      register_with_sync_reset #(
          .BITWIDTH(XLEN)
      ) delay_remask1 (
          .clk(g_clk),
          //.rst(!((s_op_b_mask|s_op_b_remask) & msk_rdy)),
          .rst(!((s_op_b_mask|s_op_b_remask) & (valid & op_msk))),
          .d  (remask1_in),
          .q  (rmask1)
      );

    reg [1:0] ctr_msk_ready;
    always @(posedge g_clk) begin
      if (msk_rdy) ctr_msk_ready  = 2'b01;
      else if (valid & op_msk) ctr_msk_ready  = ctr_msk_ready << 1;
      else ctr_msk_ready = 2'b01;
    end
    assign msk_rdy = ctr_msk_ready[1];

    /*
      always @(posedge g_clk) begin
        if (msk_rdy_delayed == 1'b1) msk_rdy_delayed <= 1'b0;
        else if (valid & op_msk) msk_rdy_delayed <= 1'b1;
        else msk_rdy_delayed <= 1'b0;
      end
    */
    end
  endgenerate

  //
  // ARITH ADD/SUB: arithmetic masked add and subtraction
  // ------------------------------------------------------------

  wire [XL:0] amsk0, amsk1;
  wire op_amsk;
  wire amsk_rdy;
  generate
    if (ENABLE_ARITH == 1) begin : gen_masked_arith_enabled
      frv_masked_arith arithmask_ins (
          .i_a0  (rs1_s0),
          .i_a1  (rs1_s1),
          .i_b0  (rs2_s0),
          .i_b1  (rs2_s1),
          .i_gs  (z0),
          .mask  (op_a_mask),
          .remask(op_a_remask),
          .doadd (op_a_add),
          .dosub (op_a_sub),
          .o_r0  (amsk0),
          .o_r1  (amsk1)
      );

      assign op_amsk  = s_op_a_mask || s_op_a_remask || op_a_add || op_a_sub;
      assign amsk_rdy = valid & op_amsk;
    end else begin : gen_masked_arith_disabled
      assign amsk0 = {XLEN{1'b0}};
      assign amsk1 = {XLEN{1'b0}};
      assign op_amsk = 1'b0;
      assign amsk_rdy = 1'b0;
    end
  endgenerate

  //
  // FAFF: Boolean masked affine transformation in field gf(2^8) for AES
  // ------------------------------------------------------------

  wire [XL:0] mfaff0, mfaff1;
  wire [XL:0] mfmul0, mfmul1;

  generate
    if (ENABLE_FAFF) begin : gen_FAFF_ENABLED
      frv_masked_faff makfaff_ins (
          .i_a0(rs1_s0),
          .i_a1(rs1_s1),
          .i_mt({rs2_s1, rs2_s0}),
          .i_gs(z0),
          .o_r0(mfaff0),
          .o_r1(mfaff1)
      );
    end else begin : gen_FAFF_DISABLED
      assign mfaff0 = 32'b0;
      assign mfaff1 = 32'b0;
    end
  endgenerate

  //
  // FMUL: Boolean masked multiplication in field gf(2^8) for AES
  // ------------------------------------------------------------

  generate
    if (ENABLE_FMUL) begin : gen_FMUL_ENABLED

      wire mskfmul_ena = op_f_mul || op_f_sqr;
      frv_masked_fmul #(
          .MASKING_ISE_DOM(MASKING_ISE_DOM)
      ) mskfmul_ins (
          .g_resetn(g_resetn),
          .g_clk   (g_clk),
          .ena     (mskfmul_ena),
          .i_a0    (rs1_s0),
          .i_a1    (rs1_s1),
          .i_b0    (rs2_s0),
          .i_b1    (rs2_s1),
          .i_sqr   (op_f_sqr),
          .i_gs    (z0),
          .o_r0    (mfmul0),
          .o_r1    (mfmul1)
      );
    end else begin : gen_FMUL_DISABLED
      assign mfmul0 = 32'b0;
      assign mfmul1 = 32'b0;
    end
  endgenerate

  wire mskfield_rdy = valid && (op_f_mul || op_f_aff || op_f_sqr);

  //
  // Masked ALU Control
  // ------------------------------------------------------------


  // NOTE:
  // if not double pumped we have to wait until the results of
  // the AND and of the XOR gate are stable before we can start the adder.
  // TODO: Implement control logic to fullfil this requirement.
  // This is only required if it is only clocked on positive edge.
  // If both is used this must not be implemented
  // FIXME: Probably wrong what i wrote above

  //parameter integer POS_EDG = 0;
  //generate
   // if (POS_EDG == 0) begin : gen_adder_controler_for_double_pumped
      assign addsub_ena = valid && op_b_addsub;
    //end
/*
    if (POS_EDG == 1) begin : gen_adder_controler_for_posedge_only
      reg [1:0] ctr_wait_bitwise;

      always @(posedge g_clk) begin
        if (!g_resetn) begin
          ctr_wait_bitwise <= 2'b01;
        end else if (flush) begin
          ctr_wait_bitwise <= 2'b01;
        end else if (valid) begin
          ctr_wait_bitwise <= ctr_wait_bitwise << 1;
        end
      end
      assign addsub_ena = ctr_wait_bitwise[1] && op_b_addsub;
    end
  endgenerate
  */

  always @(posedge g_clk) begin
    if (!g_resetn || (valid && ready)) begin
      ctrl_do_arith <= 1'b0;
    end else if (valid) begin
      ctrl_do_arith <= dologic || op_b_addsub;
    end
  end

  //
  // OUTPUT MUX: gather and multiplexing results
  // ------------------------------------------------------------

  wire [XL:0] mnot0_muted;
  wire [XL:0] mxor0_muted;
  wire [XL:0] mand0_muted;
  wire [XL:0] mior0_muted;
  wire [XL:0] madd0_muted;

  wire [XL:0] mnot1_muted;
  wire [XL:0] mxor1_muted;
  wire [XL:0] mand1_muted;
  wire [XL:0] mior1_muted;
  wire [XL:0] madd1_muted;

  // NOTE: We can isolate the different modules from each other (in a setting
  // without transitions) by adding a single register stage after each of the
  // values used above as input for the multiplexer.
  register_with_sync_reset #(.BITWIDTH(XLEN)) mute_mnot0 (
    .clk(g_clk),
    .rst(!(s_op_b_not & mlogic_rdy)),
    .d(mnot0),
    .q(mnot0_muted)
  );

  register_with_sync_reset #(.BITWIDTH(XLEN)) mute_mnot1 (
    .clk(g_clk),
    .rst(!(s_op_b_not & mlogic_rdy)),
    .d(mnot1),
    .q(mnot1_muted)
  );

  register_with_sync_reset #(.BITWIDTH(XLEN)) mute_mxor0 (
    .clk(g_clk),
    .rst(!(s_op_b_xor & mlogic_rdy)),
    .d(mxor0),
    .q(mxor0_muted)
  );

  register_with_sync_reset #(.BITWIDTH(XLEN)) mute_mxor1 (
    .clk(g_clk),
    .rst(!(s_op_b_xor & mlogic_rdy)),
    .d(mxor1),
    .q(mxor1_muted)
  );

  register_with_sync_reset #(.BITWIDTH(XLEN)) mute_mand0 (
    .clk(g_clk),
    .rst(!(s_op_b_and & mlogic_rdy)),
    .d(mand0),
    .q(mand0_muted)
  );

  register_with_sync_reset #(.BITWIDTH(XLEN)) mute_mand1 (
    .clk(g_clk),
    .rst(!(s_op_b_and & mlogic_rdy)),
    .d(mand1),
    .q(mand1_muted)
  );

  register_with_sync_reset #(.BITWIDTH(XLEN)) mute_mior0 (
    .clk(g_clk),
    .rst(!(s_op_b_ior & mlogic_rdy)),
    .d(mior0),
    .q(mior0_muted)
  );

  register_with_sync_reset #(.BITWIDTH(XLEN)) mute_mior1 (
    .clk(g_clk),
    .rst(!(s_op_b_ior & mlogic_rdy)),
    .d(mior1),
    .q(mior1_muted)
  );

  register_with_sync_reset #(.BITWIDTH(XLEN)) mute_madd0 (
    .clk(g_clk),
    .rst(!((s_op_b_add | s_op_b_sub) & madd_rdy)),
    .d(madd0),
    .q(madd0_muted)
  );

  register_with_sync_reset #(.BITWIDTH(XLEN)) mute_madd1 (
    .clk(g_clk),
    .rst(!((s_op_b_add | s_op_b_sub) & madd_rdy)),
    .d(madd1),
    .q(madd1_muted)
  );

  // FIXME: Which recombination causes lekage here?

  /*
  assign rd_s0 = {XLEN{op_b_not}} &  mnot0_muted |
               {XLEN{op_b_xor}} &  mxor0_muted |
               {XLEN{op_b_and}} &  mand0_muted |
               {XLEN{op_b_ior}} &  mior0_muted |
               {XLEN{op_shr  }} &  mshr0 | // default is muted
               {XLEN{op_b_add}} &  madd0_muted |
               {XLEN{op_b_sub}} &  madd0_muted |
               //{XLEN{s_op_a2b  }} &  madd0 |
               {XLEN{s_op_b2a  }} &  mb2a0 | // default is muted
               {XLEN{op_msk  }} &  rmask0; // default is muted
  //             {XLEN{op_amsk }} &  amsk0 |
  //             {XLEN{op_f_mul}} &  mfmul0|
  //             {XLEN{op_f_sqr}} &  mfmul0|
  //             {XLEN{op_f_aff}} &  mfaff0;

  assign rd_s1 = {XLEN{op_b_not}} &  mnot1_muted |
               {XLEN{op_b_xor}} &  mxor1_muted |
               {XLEN{op_b_and}} &  mand1_muted |
               {XLEN{op_b_ior}} &  mior1_muted |
               {XLEN{op_shr  }} &  mshr1 | // default is muted
               {XLEN{op_b_add}} &  madd1_muted |
               {XLEN{op_b_sub}} &  madd1_muted |
               //{XLEN{s_op_a2b  }} &  madd1 |
               {XLEN{s_op_b2a  }} &  mb2a1 |  // default is muted
               {XLEN{op_msk  }} &  rmask1;  // default is muted
  //             {XLEN{op_amsk }} &  amsk1 |
  //             {XLEN{op_f_mul}} &  mfmul1|
  //             {XLEN{op_f_sqr}} &  mfmul1|
  //             {XLEN{op_f_aff}} &  mfaff1;
  */

  assign rd_s0 =mnot0_muted |
                mxor0_muted |
                mand0_muted |
                mior0_muted |
                mshr0 | // default is muted
                madd0_muted |
  //              madd0_muted |
                mb2a0 | // default is muted
                rmask0; // default is muted
  //             {XLEN{s_op_a2b  }} &  madd0 |
  //             {XLEN{op_amsk }} &  amsk0 |
  //             {XLEN{op_f_mul}} &  mfmul0|
  //             {XLEN{op_f_sqr}} &  mfmul0|
  //             {XLEN{op_f_aff}} &  mfaff0;

  assign rd_s1 =mnot1_muted |
                mxor1_muted |
                mand1_muted |
                mior1_muted |
                mshr1 | // default is muted
                madd1_muted |
 //               madd1_muted |
                mb2a1 |  // default is muted
                rmask1;  // default is muted
  //             {XLEN{s_op_a2b  }} &  madd1 |
  //             {XLEN{op_amsk }} &  amsk1 |
  //             {XLEN{op_f_mul}} &  mfmul1|
  //             {XLEN{op_f_sqr}} &  mfmul1|
  //             {XLEN{op_f_aff}} &  mfaff1;

  reg b2a_rdy;
  always @(posedge g_clk) begin
    if (madd_rdy) b2a_rdy <= 1'b1;
    else b2a_rdy <= 1'b0;
  end

  // TODO: make not-operation one cycle faster
  wire mlogic_rdy_delayed;
  register #(.N(1)) delay_logic_rdy (
    .clk(g_clk),
    .d(mlogic_rdy),
    .q(mlogic_rdy_delayed)
  );

  wire madd_rdy_delayed;
  register #(.N(1)) delay_madd_rdy (
    .clk(g_clk),
    .d(madd_rdy),
    .q(madd_rdy_delayed)
  );

  assign ready = (dologic && mlogic_rdy_delayed) ||
      //madd_rdy || shr_rdy || msk_rdy ||
      ((s_op_b_add || s_op_b_sub) && madd_rdy_delayed) || (b2a_rdy && s_op_b2a) || shr_rdy || msk_rdy ||
               amsk_rdy || mskfield_rdy;

endmodule


