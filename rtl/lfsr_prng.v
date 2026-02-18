module lfsr_prng #(
    parameter DATA_WIDTH = 8
) (
    input clk,
    input rstn,
    input enable,
    output wire [DATA_WIDTH-1:0] number
);

// LFSR Parameters
localparam FEEDBACK_POLYNOMIAL = 8'b10000011;
localparam FEEDBACK_BIT = 7;

// LFSR Register
reg [DATA_WIDTH-1:0] lfsr;

always @(posedge clk) begin
    if(~rstn) begin
        lfsr <= 8'b0;
    end else if(enable) begin
        lfsr <= {lfsr[DATA_WIDTH-2:0], lfsr[DATA_WIDTH-1] ^ lfsr[FEEDBACK_BIT]};
    end
end

assign number = lfsr;

endmodule