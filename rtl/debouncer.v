module debouncer(
    input clk,
    input rstn,

    input ms_16,
    input p,

    output wire rc,
    output wire enc,
    output wire debouncedP
);

localparam E0 = 0, E1 = 1, E2 = 2, E3 = 3;

localparam STATE_0 = 4'b0001;
localparam STATE_1 = STATE_0 << E1;
localparam STATE_2 = STATE_0 << E2;
localparam STATE_3 = STATE_0 << E3;

reg [3:0] current_state;
reg [3:0] next_state;

reg p_sync1, p_sync2;

always @(posedge clk) begin
    if(~rstn) begin
        p_sync1 <= 1'b0;
        p_sync2 <= 1'b0;
    end else begin
        p_sync1 <= p;
        p_sync2 <= p_sync1;
    end
end

always @* begin
    case(1'b1)
        current_state[E0]: next_state = p_sync2 ? STATE_1 : STATE_0;
        current_state[E1]: next_state = ~p_sync2 ? STATE_0 : (ms_16 ? STATE_2 : STATE_1);
        current_state[E2]: next_state = p_sync2 ? STATE_2 : STATE_3;
        current_state[E3]: next_state = ~ms_16 ? STATE_3 : STATE_0;
    endcase
end

always @(posedge clk) begin
    if(~rstn) current_state <= STATE_0;
    else current_state <= next_state;
end

assign rc = ~(current_state[E2] | current_state[E0]);
assign enc = current_state[E3] | current_state[E1];
assign debouncedP = current_state[E2];


endmodule
