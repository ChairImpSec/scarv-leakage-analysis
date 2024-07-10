`timescale 1 ns / 10 ps

module tb_wrapper_bitwise_shift_masking;

  /* ------------------------- Adjust parameters ----------------------- */
  parameter integer ENOT = 1;
  parameter integer EAND = 1;
  parameter integer EXOR = 1;
  parameter integer EIOR = 1;
  parameter integer ESLL = 1;
  parameter integer ESRL = 1;
  parameter integer EROR = 1;
  parameter integer EMASK = 1;
  parameter integer EREMASK = 1;

  parameter integer TEST_REPETITION_NOT = 1000;
  parameter integer TEST_REPETITION_AND = 1000;
  parameter integer TEST_REPETITION_XOR = 1000;
  parameter integer TEST_REPETITION_IOR = 1000;
  parameter integer TEST_REPETITION_SLL = 1000;
  parameter integer TEST_REPETITION_SRL = 1000;
  parameter integer TEST_REPETITION_ROR = 1000;
  parameter integer TEST_REPETITION_MASK = 1000;
  parameter integer TEST_REPETITION_REMASK = 1000;
  /* ------------------------------------------------------------------- */


  /* ---------------------------- Parameters --------------------------- */
  parameter integer PERIOD = 10;
  parameter integer BIT_WIDTH = 32;

  parameter integer D = 1;
  parameter integer N = D + 1;

  parameter integer DELAY = 1;
  parameter integer L = ((D + 1) * D) / 2;
  /* ------------------------------------------------------------------ */



  /* ------------------------- Instantiate UUT ------------------------ */
  // CLOCK
  reg                  clk;

  // CONTROL
  reg                  g_resetn;
  reg                  valid;
  reg                  flush;
  reg                  prng_update;

  // OPCODE
  reg                  op_b2a;
  reg                  op_a2b;
  reg                  op_b_mask;
  reg                  op_b_remask;
  reg                  op_a_mask;
  reg                  op_a_remask;
  reg                  op_b_not;
  reg                  op_b_and;
  reg                  op_b_ior;
  reg                  op_b_xor;
  reg                  op_b_add;
  reg                  op_b_sub;
  reg                  op_b_srli;
  reg                  op_b_slli;
  reg                  op_b_rori;
  reg                  op_a_add;
  reg                  op_a_sub;
  reg                  op_f_mul;
  reg                  op_f_aff;
  reg                  op_f_sqr;
  wire                 op_shr;

  // INPUT 1 (share0, share1)
  reg  [BIT_WIDTH-1:0] rs1_s0;
  reg  [BIT_WIDTH-1:0] rs1_s1;
  wire [BIT_WIDTH-1:0] rs1;

  // INPUT 2 (share0, share1)
  reg  [BIT_WIDTH-1:0] rs2_s0;
  reg  [BIT_WIDTH-1:0] rs2_s1;
  wire [BIT_WIDTH-1:0] rs2;

  // RANDOMNESS
  reg  [         XL:0] z0;
  reg  [         XL:0] z1;
  reg  [         XL:0] z2;
  reg  [         XL:0] z3;
  reg  [         XL:0] z4;
  reg  [         XL:0] z5;

  // RESULT
  wire [BIT_WIDTH-1:0] rd_s0;
  wire [BIT_WIDTH-1:0] rd_s1;
  wire [BIT_WIDTH-1:0] rd;
  wire [BIT_WIDTH-1:0] rd_b;
  wire [BIT_WIDTH-1:0] rd_b2a;

  // READY
  wire                 ready;

  // REFERENCE
  wire                 bmasking;
  wire [BIT_WIDTH-1:0] reference;
  wire [BIT_WIDTH-1:0] reference_and;
  wire [BIT_WIDTH-1:0] reference_xor;
  wire [BIT_WIDTH-1:0] reference_ior;
  wire [BIT_WIDTH-1:0] reference_not;
  wire [BIT_WIDTH-1:0] reference_shr;
  wire [BIT_WIDTH-1:0] reference_add;
  wire [BIT_WIDTH-1:0] reference_sub;
  wire [BIT_WIDTH-1:0] reference_b2a;
  wire [BIT_WIDTH-1:0] reference_srli;
  wire [BIT_WIDTH-1:0] reference_slli;
  wire [BIT_WIDTH-1:0] reference_rori;

  // DUT
  wrapper_bitwise_shift_masking UUT (
      .g_clk(clk),
      .g_resetn(g_resetn),

      .valid(valid),
      .flush(flush),

      .op_b2a(op_b2a),
      .op_a2b(op_a2b),
      .op_b_mask(op_b_mask),
      .op_b_remask(op_b_remask),
      .op_a_mask(op_a_mask),
      .op_a_remask(op_a_remask),
      .op_b_not(op_b_not),
      .op_b_and(op_b_and),
      .op_b_ior(op_b_ior),
      .op_b_xor(op_b_xor),
      .op_b_add(op_b_add),
      .op_b_sub(op_b_sub),
      .op_b_srli(op_b_srli),
      .op_b_slli(op_b_slli),
      .op_b_rori(op_b_rori),
      .op_a_add(op_a_add),
      .op_a_sub(op_a_sub),
      .op_f_mul(op_f_mul),
      .op_f_aff(op_f_aff),
      .op_f_sqr(op_f_sqr),

      .prng_update(prng_update),
      .ready(ready),

      .rs1_s0(rs1_s0),  // BIT_WIDTH sized input
      .rs1_s1(rs1_s1),  // BIT_WIDTH sized input
      .rs2_s0(rs2_s0),  // BIT_WIDTH sized input
      .rs2_s1(rs2_s1),  // BIT_WIDTH sized input

      // NOTE: randomness was added to use good randomness
      // not the given (reference) one
      .z0_in(z0),
      .z1_in(z1),
      .z2_in(z2),
      .z3_in(z3),
      .z4_in(z4),
      .z5_in(z5),

      .rd_s0(rd_s0),  // BIT_WIDTH sized input
      .rd_s1(rd_s1)   // BIT_WIDTH sized input
  );

  assign rs1 = rs1_s0 ^ rs1_s1;
  assign rs2 = rs2_s0 ^ rs2_s1;

  assign reference_not = ~rs1;
  assign reference_and = rs1 & rs2;
  assign reference_xor = rs1 ^ rs2;
  assign reference_ior = rs1 | rs2;
  assign reference_add = rs1 + rs2;
  assign reference_sub = rs1 - rs2;
  assign reference_b2a = rs1;
  assign reference_srli= rs1 >> (rs2[4:0]);
  assign reference_slli= rs1 << (rs2[4:0]);
  assign reference_rori= rs1 >> (rs2[4:0]) | (rs1 << (BIT_WIDTH - rs2[4:0]));

  assign reference = {XLEN{op_b_not}} &  reference_not |
              {XLEN{op_b_xor}} &  reference_xor |
              {XLEN{op_b_and}} &  reference_and |
              {XLEN{op_b_ior}} &  reference_ior |
              {XLEN{op_b_add}} &  reference_add |
              {XLEN{op_b_sub}} &  reference_sub |
              {XLEN{op_b_srli}}&  reference_srli|
              {XLEN{op_b_slli}}&  reference_slli|
              {XLEN{op_b_rori}}&  reference_rori|
              {XLEN{op_b2a  }} &  reference_b2a;
  //{XLEN{op_msk  }} &  rmask0;

  assign rd_b = (rd_s0 ^ rd_s1);
  assign rd_b2a = (rd_s0 - rd_s1);
  assign rd = {XLEN{op_b_not}} & rd_b |
    {XLEN{op_b_xor}} & rd_b |
    {XLEN{op_b_and}} & rd_b |
    {XLEN{op_b_ior}} & rd_b |
    {XLEN{op_b_add}} & rd_b |
    {XLEN{op_b_sub}} & rd_b |
    {XLEN{op_b_srli}} & rd_b |
    {XLEN{op_b_slli}} & rd_b |
    {XLEN{op_b_rori}} & rd_b |
    {XLEN{op_b2a}} & rd_b2a;
  /* ------------------------------------------------------------------ */

  /* --------------------- Dump waveform to file ---------------------- */
  initial begin
    $dumpfile("tb_wrapper_bitwise_shift_masking.vcd");
    $dumpvars(0,tb_wrapper_bitwise_shift_masking);
  end
  /* ------------------------------------------------------------------ */

  // Check
  always @(posedge clk) begin
    if (ready == 1) begin
      if (^rd === 1'bx) begin
        $display("\nERROR undefined value!");
        $error();
        $finish();
      end
      if (reference != rd) begin
        $display("ERROR:");
        $display("%h != %h with inputs:", reference, rd);
        $display("\trs1_s0: %h", rs1_s0);
        $display("\trs1_s1: %h", rs1_s1);
        $display("\trs2_s0: %h", rs2_s0);
        $display("\trs2_s1: %h", rs2_s1);
        $error();
        $finish();
      end
    end
  end

  /* ---------------------- Stimulate Circuit -------------------------- */
  // Clock Generator
  always begin
    clk = 1'b1;
    #(PERIOD / 2);
    clk = 1'b0;
    #(PERIOD / 2);
  end

  // Randomness Generator
  always @(posedge clk) begin
      z0     = $urandom_range(2 ** (BIT_WIDTH) - 1);
      z1     = $urandom_range(2 ** (BIT_WIDTH) - 1);
      z2     = $urandom_range(2 ** (BIT_WIDTH) - 1);
      z3     = $urandom_range(2 ** (BIT_WIDTH) - 1);
      z4     = $urandom_range(2 ** (BIT_WIDTH) - 1);
      z5     = $urandom_range(2 ** (BIT_WIDTH) - 1);
  end

  task automatic setup(input string opcode);
    // SetUp Phase
    $display("[~] Setup Phase (%s)  started ...", opcode);
    g_resetn    <= 1'b0;
    valid       <= 1'b0;
    flush       <= 1'b1;

    op_b2a      <= 1'b0;
    op_a2b      <= 1'b0;
    op_b_mask   <= 1'b0;
    op_b_remask <= 1'b0;
    op_a_mask   <= 1'b0;
    op_a_remask <= 1'b0;
    op_b_not    <= 1'b0;
    op_b_and    <= 1'b0;
    op_b_ior    <= 1'b0;
    op_b_xor    <= 1'b0;
    op_b_add    <= 1'b0;
    op_b_sub    <= 1'b0;
    op_b_srli   <= 1'b0;
    op_b_slli   <= 1'b0;
    op_b_rori   <= 1'b0;
    op_a_add    <= 1'b0;
    op_a_sub    <= 1'b0;
    op_f_mul    <= 1'b0;
    op_f_aff    <= 1'b0;
    op_f_sqr    <= 1'b0;
    prng_update <= 1'b0;

    rs1_s0      <= {BIT_WIDTH{1'b0}};
    rs1_s1      <= {BIT_WIDTH{1'b0}};
    rs2_s0      <= {BIT_WIDTH{1'b0}};
    rs2_s1      <= {BIT_WIDTH{1'b0}};
    #(PERIOD + 0.1);
    $display("[+] Setup Phase (%s) completed!", opcode);
  endtask

  task automatic default_stimulation(input integer repetitions);
    // INIT
    g_resetn <= 1'b1;
    valid    <= 1'b1;
    flush    <= 1'b0;

    // DEBUG CASE
    rs1_s0   <= 32'h0484D609;
    rs1_s1   <= 32'h31F05663;
    rs2_s0   <= 32'b0;
    rs2_s1   <= 32'b0;
    @(posedge ready);
    #(PERIOD);

    repeat (repetitions) begin
      rs1_s0 <= $urandom_range(2 ** (BIT_WIDTH) - 1);
      rs1_s1 <= $urandom_range(2 ** (BIT_WIDTH) - 1);
      rs2_s0 <= $urandom_range(2 ** (BIT_WIDTH) - 1);
      rs2_s1 <= $urandom_range(2 ** (BIT_WIDTH) - 1);
      @(posedge ready);
      #(PERIOD);  //required: on ready rs{1,2}_s{0,1} are used to compute reference
    end
  endtask

  task automatic shift_stimulation(input integer repetitions);
    // INIT
    g_resetn <= 1'b1;
    valid    <= 1'b1;
    flush    <= 1'b0;

    // DEBUG CASE
    rs1_s0   <= 32'h0484D609;
    rs1_s1   <= 32'h31F05663;
    rs2_s0   <= 32'h00000001; // how much should be shifted
    @(posedge ready);
    #(PERIOD);

    repeat (repetitions) begin
      rs1_s0 <= $urandom_range(2 ** (BIT_WIDTH) - 1);
      rs1_s1 <= $urandom_range(2 ** (BIT_WIDTH) - 1);
      rs2_s0 <= $urandom_range(2 ** (5) - 1);
      @(posedge ready);
      #(PERIOD);  //required: on ready rs{1,2}_s{0,1} are used to compute reference
    end
  endtask

  task automatic no_register_stimulation(input integer repetitions);
    // This task is used to simulate operations, where no registers are in
    // datapath and the ready is constant 1
    // INIT
    g_resetn <= 1'b1;
    valid    <= 1'b1;
    flush    <= 1'b0;

    // DEBUG CASE
    rs1_s0   <= 32'h0484D609;
    rs1_s1   <= 32'h31F05663;
    rs2_s0   <= 32'b0;
    rs2_s1   <= 32'b0;
    #(PERIOD);

    repeat (repetitions) begin
      rs1_s0 <= $urandom_range(2 ** (BIT_WIDTH) - 1);
      rs1_s1 <= $urandom_range(2 ** (BIT_WIDTH) - 1);
      rs2_s0 <= $urandom_range(2 ** (BIT_WIDTH) - 1);
      rs2_s1 <= $urandom_range(2 ** (BIT_WIDTH) - 1);
      #(PERIOD);  //required: on ready rs{1,2}_s{0,1} are used to compute reference
    end
  endtask

  task automatic not_stimulation(input integer repetitions);
    $display("[~] Testing NOT Operation (%d) times ...", repetitions);
    op_b_not <= 1'b1;
    default_stimulation(repetitions);
    $display("[~] Testing NOT Operation completed!\n");
  endtask

  task automatic and_stimulation(input integer repetitions);
    $display("[~] Testing AND Operation (%d) times ...", repetitions);
    op_b_and <= 1'b1;
    default_stimulation(repetitions);
    $display("[~] Testing AND Operation completed!\n");
  endtask

  task automatic xor_stimulation(input integer repetitions);
    $display("[~] Testing XOR Operation (%d) times ...", repetitions);
    op_b_xor <= 1'b1;
    default_stimulation(repetitions);
    $display("[~] Testing XOR Operation completed!\n");
  endtask

  task automatic ior_stimulation(input integer repetitions);
    $display("[~] Testing IOR Operation (%d) times ...", repetitions);
    op_b_ior <= 1'b1;
    default_stimulation(repetitions);
    $display("[~] Testing IOR Operation completed!\n");
  endtask

  task automatic sll_stimulation(input integer repetitions);
    $display("[~] Testing SLL Operation (%d) times ...", repetitions);
    op_b_slli <= 1'b1;
    shift_stimulation(repetitions);
    $display("[~] Testing SLL Operation completed!\n");
  endtask

  task automatic srl_stimulation(input integer repetitions);
    $display("[~] Testing SRL Operation (%d) times ...", repetitions);
    op_b_srli <= 1'b1;
    shift_stimulation(repetitions);
    $display("[~] Testing SRL Operation completed!\n");
  endtask

  task automatic ror_stimulation(input integer repetitions);
    $display("[~] Testing ROR Operation (%d) times ...", repetitions);
    op_b_rori <= 1'b1;
    shift_stimulation(repetitions);
    $display("[~] Testing ROR Operation completed!\n");
  endtask

  task automatic masking_stimulation(input integer repetitions);
    $display("[~] Testing Masking Operation (%d) times ...", repetitions);
    op_b_mask <= 1'b1;
    no_register_stimulation(repetitions);
    $display("[~] Testing Masking Operation completed!\n");
  endtask

  task automatic remasking_stimulation(input integer repetitions);
    $display("[~] Testing Remasking Operation (%d) times ...", repetitions);
    op_b_remask <= 1'b1;
    no_register_stimulation(repetitions);
    $display("[~] Testing Remasking Operation completed!\n");
  endtask

  initial begin

    if (ENOT == 1) begin
      setup("NOT");
      not_stimulation(TEST_REPETITION_NOT);
    end

    if (EAND == 1) begin
      setup("AND");
      and_stimulation(TEST_REPETITION_AND);
    end

    if (EXOR) begin
      setup("XOR");
      xor_stimulation(TEST_REPETITION_XOR);
    end

    if (EIOR) begin
      setup("IOR");
      ior_stimulation(TEST_REPETITION_IOR);
    end

    if (ESLL) begin
      setup("SLL");
      sll_stimulation(TEST_REPETITION_SLL);
    end

    if (ESRL) begin
      setup("SRL");
      srl_stimulation(TEST_REPETITION_SRL);
    end

    if (EROR) begin
      setup("ROR");
      ror_stimulation(TEST_REPETITION_ROR);
    end

    if (EMASK) begin
      setup("MASK");
      masking_stimulation(TEST_REPETITION_MASK);
    end

    if (EREMASK) begin
      setup("REMASK");
      remasking_stimulation(TEST_REPETITION_REMASK);
    end
    $finish;

  end
  /* ------------------------------------------------------------------ */
endmodule
