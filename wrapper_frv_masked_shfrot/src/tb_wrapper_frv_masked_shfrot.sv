`timescale 1 ns / 10 ps

module tb_wrapper_frv_masked_shfrot;

  parameter integer PERIOD = 10;
  parameter integer BIT_WIDTH = 32;

  /* ------------------------- Adjust parameters ----------------------- */
  parameter integer DEBUG = 0;
  parameter integer ESLL = 1;
  parameter integer ESRL = 1;
  parameter integer EROR = 1;

  parameter integer TEST_REPETITION_SLL = 1000;
  parameter integer TEST_REPETITION_SRL = 1000;
  parameter integer TEST_REPETITION_ROR = 1000;
  /* ------------------------------------------------------------------- */

  // Inputs
  reg         clk;
  reg         ena;
  reg  [31:0] rs1_s0;
  reg  [31:0] rs1_s1;
  reg  [ 5:0] shamt;
  reg  [31:0] z0;  // random padding
  reg  [31:0] z1;  // random padding
  reg         op_b_slli;
  reg         op_b_srli;
  reg         op_b_rori;

  // Outputs:
  wire [31:0] rd_s0;
  wire [31:0] rd_s1;
  wire        ready;

  // Reference signal
  wire [31:0] rd_b;
  wire [31:0] rd;
  wire [31:0] rs1;
  wire [31:0] reference;
  wire [31:0] reference_slli;
  wire [31:0] reference_srli;
  wire [31:0] reference_rori;
  wire [31:0] mask_slli;
  wire [31:0] mask_srli;
  wire [31:0] mask_rori;

  assign rs1 = (rs1_s0 ^ rs1_s1);

  assign reference_srli = (rs1 >> (shamt[4:0]));
  assign reference_slli = rs1 << (shamt[4:0]);
  assign reference_rori = rs1 >> (shamt[4:0]) | (rs1 << (BIT_WIDTH - shamt[4:0]));

  assign reference =
              {BIT_WIDTH{op_b_srli}}&  reference_srli|
              {BIT_WIDTH{op_b_slli}}&  reference_slli|
              {BIT_WIDTH{op_b_rori}}&  reference_rori;

  assign rd_b = (rd_s0 ^ rd_s1);
  assign rd =
    {BIT_WIDTH{op_b_srli}} & rd_b|
    {BIT_WIDTH{op_b_slli}} & rd_b|
    {BIT_WIDTH{op_b_rori}} & rd_b;
  /* ------------------------- Instantiate UUT ------------------------ */
  wrapper_frv_masked_shfrot #(
      .BIT_WIDTH(BIT_WIDTH)
  ) uut (
      .clk(clk),
      .ena(ena),
      .srli(op_b_srli),
      .slli(op_b_slli),
      .rori(op_b_rori),
      .shamt(shamt),
      .s0(rs1_s0),
      .s1(rs1_s1),
      .rp0(z0),
      .r0(rd_s0),
      .r1(rd_s1),
      .ready(ready)
  );

  /* ------------------------------------------------------------------- */



  /* ------------------------ Setup Debug Signals --------------------- */
  // Dump waveform to file
  initial begin
    $dumpfile("tb_wrapper_frv_masked_shfrot");
    $dumpvars(0, tb_wrapper_frv_masked_shfrot);
  end

  // Check
  always @(negedge clk) begin
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
        $display("\tshamt: %h", shamt);
        $error();
        //$finish();
      end
    end
  end

  // Clock Generator
  always begin
    clk = 1'b0;
    #(PERIOD / 2);
    clk = 1'b1;
    #(PERIOD / 2);
  end

  // Randomness Generator
  generate
    if (DEBUG == 0) begin : gen_test
      always @(posedge clk) begin
        z0 = $urandom_range(2 ** (BIT_WIDTH) - 1);
      end
    end
    else begin : gen_debug
      always @(posedge clk) begin
        z0 = 32'b0;
      end
    end
  endgenerate

  task automatic setup(input string opcode);
    // SetUp Phase
    $display("[~] Setup Phase (%s)  started ...", opcode);

    op_b_srli <= 1'b0;
    op_b_slli <= 1'b0;
    op_b_rori <= 1'b0;
    ena       <= 1'b0;

    rs1_s0    <= {BIT_WIDTH{1'b0}};
    rs1_s1    <= {BIT_WIDTH{1'b0}};
    shamt     <= {BIT_WIDTH{1'b0}};
    #(PERIOD + 0.1);
    $display("[+] Setup Phase (%s) completed!", opcode);
  endtask

  task automatic shift_stimulation(input integer repetitions);
    // INIT

    // DEBUG CASE
    ena    <= 1'b1;
    rs1_s0 <= 32'h0484D609;
    rs1_s1 <= 32'h31F05663;
    shamt  <= 32'h00000004;  // how much should be shifted
    @(posedge ready);
    #(PERIOD);

    repeat (repetitions) begin
      rs1_s0 <= $urandom_range(2 ** (BIT_WIDTH) - 1);
      rs1_s1 <= $urandom_range(2 ** (BIT_WIDTH) - 1);
      shamt  <= $urandom_range(2 ** (5) - 1);
    @(posedge ready);
        #(PERIOD);  //required: on ready rs{1,2}_s{0,1} are used to compute reference
    end
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

  initial begin
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

    $finish();
  end


  /* ------------------------------------------------------------------- */


endmodule
