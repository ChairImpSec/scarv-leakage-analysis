`timescale 1 ns / 10 ps

module tb_wrapper_frv_masked_barith;

  parameter integer PERIOD = 10;
  parameter integer BIT_WIDTH = 32;

  /* ------------------------- Adjust parameters ----------------------- */
  parameter integer ADDITION = 1;
  parameter integer SUBTRACTION = 1;

  parameter integer TEST_REPETITION_ADDITION = 100;
  parameter integer TEST_REPETITION_SUBTRACTION = 100;

  /* ------------------------------------------------------------------- */

  /* ------------------------- Instantiate UUT ------------------------ */
  // Inputs
  reg                  clk;
  reg                  resetn;
  reg                  flush;
  reg                  valid;
  reg                  op_add;
  reg                  op_sub;

  reg  [BIT_WIDTH-1:0] z0;
  reg  [BIT_WIDTH-1:0] z1;
  reg  [BIT_WIDTH-1:0] z2;
  reg  [BIT_WIDTH-1:0] z3;
  reg  [BIT_WIDTH-1:0] z4;
  reg  [BIT_WIDTH-1:0] z5;

  reg  [BIT_WIDTH-1:0] rs1_s0;
  reg  [BIT_WIDTH-1:0] rs1_s1;
  wire [BIT_WIDTH-1:0] rs1;

  reg  [BIT_WIDTH-1:0] rs2_s0;
  reg  [BIT_WIDTH-1:0] rs2_s1;
  wire [BIT_WIDTH-1:0] rs2;

  wire [BIT_WIDTH-1:0] rd_s0;
  wire [BIT_WIDTH-1:0] rd_s1;
  wire [BIT_WIDTH-1:0] rd;
  wire                 ready;
  reg                  ready_and_stable;

  // Reference values
  assign rs1 = rs1_s0 ^ rs1_s1;
  assign rs2 = rs2_s0 ^ rs2_s1;
  wire [BIT_WIDTH-1:0] reference_add = rs1 + rs2;
  wire [BIT_WIDTH-1:0] reference_sub = rs1 - rs2;
  wire [BIT_WIDTH-1:0] reference;

  assign reference = op_add ? reference_add : reference_sub;

  // DUT
  wrapper_frv_masked_barith #(
      .BIT_WIDTH(BIT_WIDTH)
  ) uut (
      .g_clk(clk),
      .g_resetn(resetn),
      .flush(flush),
      .valid(valid),
      .op_add(op_add),
      .op_sub(op_sub),
      .z0(z0),
      .z1(z1),
      .z2(z2),
      .z3(z3),
      .z4(z4),
      .z5(z5),
      .rs1_s0(rs1_s0),
      .rs1_s1(rs1_s1),
      .rs2_s0(rs2_s0),
      .rs2_s1(rs2_s1),
      .rd_s0(rd_s0),
      .rd_s1(rd_s1),
      .ready(ready)
  );
  /* ------------------------------------------------------------------- */

  /* ------------------------ Setup Debug Signals --------------------- */
  // Dump waveform to file
  initial begin
    $dumpfile("tb_wrapper_frv_masked_barith.vcd");
    $dumpvars(0, tb_wrapper_frv_masked_barith);
  end

  // Clock Generator
  always begin
    clk = 1'b0;
    #(PERIOD / 2);
    clk = 1'b1;
    #(PERIOD / 2);
  end

  assign rd = rd_s0 ^ rd_s1;

  //------------------------------ Check ------------------------------
  // NOTE: we check on negative edge here,
  // since reference_add has no register and changes directly on
  // positive edge!
  always @(negedge clk) begin
    if (ready == 1) begin
      if (^rd === 1'bx) begin
        $display("\nERROR undefined value!");
        $error();
      end
      if (reference != rd) begin
        if (op_sub == 1) begin
          $display("ERROR (subtraction): ");
        end else begin
          $display("ERROR (addition): ");
        end
        $display("%h != %h with inputs:", reference_add, rd);
        $display("\trs1_s0: %h", rs1_s0);
        $display("\trs1_s1: %h", rs1_s1);
        $display("\trs2_s0: %h", rs2_s0);
        $display("\trs2_s1: %h", rs2_s1);
        $error();
      end
    end
  end
  //------------------------------------------------------------------
  always @(posedge clk) begin
      z0     = $urandom_range(2 ** (BIT_WIDTH) - 1);
      z1     = $urandom_range(2 ** (BIT_WIDTH) - 1);
      z2     = $urandom_range(2 ** (BIT_WIDTH) - 1);
      z3     = $urandom_range(2 ** (BIT_WIDTH) - 1);
      z4     = $urandom_range(2 ** (BIT_WIDTH) - 1);
      z5     = $urandom_range(2 ** (BIT_WIDTH) - 1);
  end

  /* ---------------------- Stimulate Circuit -------------------------- */
  initial begin

    $display("[INIT] Test with parameters:");
    $display("[INIT] BIT_WIDTH =%d", BIT_WIDTH);

    if (ADDITION == 1) begin
      $display("Testing addition started!");
      // RESET
      resetn = 1'b0;
      valid  = 1'b0;
      flush  = 1'b1;

      op_add = 1'b1;
      op_sub = 1'b0;

      rs1_s0 = 32'h00000000;
      rs1_s1 = 32'h00000000;
      rs2_s0 = 32'h00000000;
      rs2_s1 = 32'h00000000;
      #(PERIOD + (0.1) * PERIOD);
    end

    repeat (TEST_REPETITION_ADDITION * ADDITION) begin
      // INIT
      resetn = 1'b1;
      valid  = 1'b1;
      flush  = 1'b0;

      rs1_s0 = $urandom_range(2 ** (BIT_WIDTH) - 1);
      rs1_s1 = $urandom_range(2 ** (BIT_WIDTH) - 1);
      rs2_s0 = $urandom_range(2 ** (BIT_WIDTH) - 1);
      rs2_s1 = $urandom_range(2 ** (BIT_WIDTH) - 1);
      @(posedge ready);
      #(PERIOD);
    end

    if (ADDITION) begin
      $display("Testing addition finished successfully!");
    end

    if (SUBTRACTION == 1) begin
      $display("Testing subtraction started!");
      // RESET
      resetn = 1'b0;
      valid  = 1'b0;
      flush  = 1'b1;

      op_add = 1'b0;
      op_sub = 1'b1;

      rs1_s0 = 32'h00000000;
      rs1_s1 = 32'h00000000;
      rs2_s0 = 32'h00000000;
      rs2_s1 = 32'h00000000;
      #(PERIOD + (0.1) * PERIOD);
    end
    repeat (TEST_REPETITION_SUBTRACTION * SUBTRACTION) begin
      // INIT
      resetn = 1'b1;
      valid  = 1'b1;
      flush  = 1'b0;

      rs1_s0 = $urandom_range(2 ** (BIT_WIDTH) - 1);
      rs1_s1 = $urandom_range(2 ** (BIT_WIDTH) - 1);
      rs2_s0 = $urandom_range(2 ** (BIT_WIDTH) - 1);
      rs2_s1 = $urandom_range(2 ** (BIT_WIDTH) - 1);
      @(posedge ready);
      #(PERIOD);
    end
    if (SUBTRACTION == 1) begin
      $display("Testing subtraction finished successfully!");
    end
    $finish;
  end
  /* ------------------------------------------------------------------- */

endmodule
