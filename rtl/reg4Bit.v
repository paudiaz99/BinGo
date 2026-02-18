module reg4Bit (
    input clk,
    input rstn,
    input enable,

    input [3:0] d,
    output reg [3:0] q

);

always @(posedge clk) begin
    if(~rstn) q <= 4'b0;
    else if(enable) q <= d;
end

endmodule