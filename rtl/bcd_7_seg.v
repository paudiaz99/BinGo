module bcd_7_seg(
    input [3:0] bcd,
    output reg [7:0] seg
);

    always @(*) begin
        case(bcd)
            4'b0000: seg = 8'b11000000;
            4'b0001: seg = 8'b10000110;
            4'b0010: seg = 8'b11011011;
            4'b0011: seg = 8'b11001111;
            4'b0100: seg = 8'b11100110;
            4'b0101: seg = 8'b11101101;
            4'b0110: seg = 8'b11111101;
            4'b0111: seg = 8'b10000111;
            4'b1000: seg = 8'b10000000;
            4'b1001: seg = 8'b10011000;
            default: seg = 8'b01111111;
        endcase
    end

endmodule