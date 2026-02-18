module counter #(
    parameter COUNT=1600000,
    parameter WIDTH=64
)(
    input clk,
    input rstn,
    input enable,

    output reg [WIDTH-1:0] val,
    output overflow
);

always @(posedge clk) begin
    if(~rstn | (val == COUNT)) begin 
        val <= 64'b0;
    end else if(enable) begin
        val <= val + 64'b1;
    end
end

assign overflow = (val == COUNT);

endmodule