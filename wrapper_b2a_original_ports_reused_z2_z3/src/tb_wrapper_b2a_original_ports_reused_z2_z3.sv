`timescale 1 ns / 10 ps

module tb_wrapper_b2a_original_ports_reused_z2_z3 ();

  parameter integer PERIOD = 10;
  parameter integer BIT_WIDTH = 32;

  /* ------------------------- Adjust parameters ----------------------- */

  parameter integer TEST_REPETITION = 10000;

  /* ------------------------------------------------------------------- */

  /* ------------------------- Instantiate UUT ------------------------ */
  // Inputs
  reg                  clk;
  reg                  resetn;
  reg                  flush;
  reg                  valid;
  reg                  op_add;
  reg                  op_sub;
  reg                  op_b2a;

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

  wire [BIT_WIDTH-1:0] reference;
  assign reference = (rs1_s0 ^ rs1_s1);

  // DUT
  wrapper_b2a_original_ports_reused_z2_z3 #(
      .BIT_WIDTH(BIT_WIDTH)
  ) uut (
      .g_clk(clk),
      .g_resetn(resetn),
      .flush(flush),
      .valid(valid),
      .op_add(op_add),
      .op_sub(op_sub),
      .op_b2a(op_b2a),
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

  assign rd = (rd_s0 - rd_s1);
  /* ------------------------------------------------------------------- */

  /* ------------------------ Setup Debug Signals --------------------- */
  // Dump waveform to file
  initial begin
    $dumpfile("tb_wrapper_b2a_original_ports_reused_z2_z3.vcd");
    $dumpvars(0, tb_wrapper_b2a_original_ports_reused_z2_z3);
  end

  // Clock Generator
  always begin
    clk = 1'b0;
    #(PERIOD / 2);
    clk = 1'b1;
    #(PERIOD / 2);
  end

  //------------------------------ Check ------------------------------
  /*
  wire ready_delayed;
  register #(1) delay_ready (
    .clk(g_clk),
    .d(ready),
    .q(ready_delayed)
  );
  */
  always @(negedge clk) begin
    if (ready == 1) begin
      if (^rd === 1'bx) begin
        $display("\nERROR undefined value!");
        $error();
      end
      if (reference != rd) begin
        $display("ERROR (b2a): ");
        $display("%h != %h with inputs:", reference, rd);
        $display("\trs1_s0: %h", rs1_s0);
        $display("\trs1_s1: %h", rs1_s1);
        $display("\trs2_s0: %h", rs2_s0);
        $display("\trs2_s1: %h", rs2_s1);
        $error();
      end
    end
  end

  //------------------------------------------------------------------

  /* ---------------------- Stimulate Circuit -------------------------- */

  initial begin
    // RESET
    resetn = 1'b0;
    valid  = 1'b0;
    flush  = 1'b1;

    op_add = 1'b0;
    op_sub = 1'b0;
    op_b2a = 1'b1;

    z0     = {BIT_WIDTH{1'b0}};
    z1     = {BIT_WIDTH{1'b0}};
    z2     = {BIT_WIDTH{1'b0}};
    z3     = {BIT_WIDTH{1'b0}};
    z4     = {BIT_WIDTH{1'b0}};
    z5     = {BIT_WIDTH{1'b0}};

    rs1_s0 = 32'h00000000;
    rs1_s1 = 32'h00000000;
    rs2_s0 = 32'h00000000;
    rs2_s1 = 32'h00000000;
    #(PERIOD + (0.1 * PERIOD));

    repeat (TEST_REPETITION) begin

      // INIT
      resetn = 1'b1;
      valid  = 1'b1;
      flush  = 1'b0;

      if (TEST_REPETITION != 1) begin
        z0     = $urandom_range(2 ** (BIT_WIDTH) - 1);
        z1     = $urandom_range(2 ** (BIT_WIDTH) - 1);
        z2     = $urandom_range(2 ** (BIT_WIDTH) - 1);
        z3     = $urandom_range(2 ** (BIT_WIDTH) - 1);
        z4     = $urandom_range(2 ** (BIT_WIDTH) - 1);
        z5     = $urandom_range(2 ** (BIT_WIDTH) - 1);

        rs1_s0 = $urandom_range(2 ** (BIT_WIDTH) - 1);
        rs1_s1 = $urandom_range(2 ** (BIT_WIDTH) - 1);
        rs2_s0 = $urandom_range(2 ** (BIT_WIDTH) - 1);
        rs2_s1 = $urandom_range(2 ** (BIT_WIDTH) - 1);
      end else begin
        z0     = 32'hae366011;
        //z0     = 32'b0;
        z1     = 32'h5048108b;
        z2     = 32'h130b12e4;
        z3     = 32'h92153524;
        z4     = 32'h40895E81;
        z5     = 32'hbaae80ff;

        //rs1_s0 = 32'h0484D609;
        //rs1_s1 = 32'h31F05663;
        rs1_s0 = 32'h00000002;
        rs1_s1 = 32'h00000001;
        rs2_s0 = 32'b0;
        rs2_s1 = 32'b0;
      end
      @(posedge ready);

      // RESET
      resetn = 1'b0;
      valid  = 1'b0;
      flush  = 1'b1;
      #(PERIOD);
    end
    $finish();
  end
  //------------------------------------------------------------------

endmodule
