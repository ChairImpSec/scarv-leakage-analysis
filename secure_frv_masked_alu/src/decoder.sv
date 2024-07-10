module decoder
    #(
        parameter integer D = 2,
        parameter integer N = D + 1
    )
    (
        input   clk,
        input   rst,
        input   [N-1:0] port_a,
        input   [N-1:0] port_b,
        input   [N-1:0] port_r,
        output  [N-1:0] port_c
    );

    wire [N-1:0] b_masked;
    wire [N-1:0] b_masked_delayed;
    wire sum;

    assign b_masked = port_r ^ port_b;

    register_with_sync_reset #(.BITWIDTH(N)) delay_b_masked(
        .clk(clk),
        .rst(rst),
        .d(b_masked),
        .q(b_masked_delayed)
    );

    assign sum = ^b_masked_delayed;

    assign port_c = {N{sum}} & port_a;

endmodule


