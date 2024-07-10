module dom_dep
    #(
        parameter integer D = 2,
        parameter integer N = D+1,
        parameter integer L = ((D+1)*D)/2,
        parameter integer PIPELINING = 1
    )
    (
        input           clk,
        input           rst,
        input   [N-1:0] port_a,
        input   [N-1:0] port_b,
        input   [N-1:0] port_r1,    // randomnes for dom_dep excluding dom_indep
        input   [L-1:0] port_r2,    // randomnes for dom_indep (only used in dom_indep)
        output  [N-1:0] port_c
    );


    wire [N-1:0] a_delayed;
    wire [N-1:0] dom_mul_out;
    wire [N-1:0] dom_dec_out;

    if(PIPELINING==1) begin : gen_pipline
        register_with_sync_reset #(.BITWIDTH(N)) delay_a(
            .clk(clk),
            .rst(rst),
            .d(port_a),
            .q(a_delayed)
        );
    end
    else begin : gen_no_pipeline
        assign a_delayed = port_a;
    end

    dom_indep #(.D(D)) dom_mul(
        .clk(clk),
        .rst(rst),
        .port_a(port_a),
        .port_b(port_r1),
        .port_r(port_r2),
        .port_c(dom_mul_out)
    );

    decoder #(.D(D)) dom_dec(
        .clk(clk),
        .rst(rst),
        .port_a(a_delayed),
        .port_b(port_b),
        .port_r(port_r1),
        .port_c(dom_dec_out)
    );

    assign port_c = dom_mul_out ^ dom_dec_out;

endmodule
