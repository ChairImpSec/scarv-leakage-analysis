module dff_with_sync_reset (
  input clk,
  input rst,
  input d,
  output reg q
  );

  always @(posedge clk) begin
    if (rst) begin
      q <= 1'b0;
    end
    else begin
      q <= d;
    end
  end
endmodule
