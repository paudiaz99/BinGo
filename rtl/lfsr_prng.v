module lfsr_prng #(
    parameter DATA_WIDTH = 8
) (
    input clk,
    input rstn,
    input enable,
    output wire [DATA_WIDTH-1:0] number
);

// Primitive polynomial: x^8 + x^6 + x^5 + x^4 + 1
// Taps at bits 7, 5, 4, 3 (0-indexed) -> maximal-length sequence (2^8 - 1 = 255 states)
// Seed selected using techniques from:
// "A Seed Selection Procedure for LFSR-Based Random Pattern Generators"
// Ichino et al., Graduate School of Engineering, Tokyo Metropolitan University.
// Alternating-style seed used for better initial pattern distribution (Ref. Table 1).
localparam SEED = 8'b10101100;

// LFSR Register
reg [DATA_WIDTH-1:0] lfsr;

always @(posedge clk) begin
    if(~rstn) begin
        lfsr <= SEED;
    end else if(enable) begin
        lfsr <= {lfsr[6:0], lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3]};
    end
end

wire [3:0] lo_nibble = (lfsr[3:0] > 4'd9) ? (lfsr[3:0] - 4'd10) : lfsr[3:0];
wire [3:0] hi_nibble = (lfsr[7:4] > 4'd9) ? (lfsr[7:4] - 4'd10) : lfsr[7:4];

assign number = {hi_nibble, lo_nibble};

endmodule