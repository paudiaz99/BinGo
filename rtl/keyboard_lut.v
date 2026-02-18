module keyboard_lut (
    input [3:0] rows,
    input [2:0] cols,

    output reg [3:0] number,
    output wire new_num
);

always @* begin
    case({rows,cols})
    7'b1000100: number = 4'b0001;
    7'b1000010: number = 4'b0010;
    7'b1000001: number = 4'b0011;
    7'b0100100: number = 4'b0100;
    7'b0100010: number = 4'b0101;
    7'b0100001: number = 4'b0110;
    7'b0010100: number = 4'b0111;
    7'b0010010: number = 4'b1000;
    7'b0010001: number = 4'b1001;
    7'b0001100: number = 4'b1010;
    7'b0001010: number = 4'b0000;
    7'b0001001: number = 4'b1011;
    default: number = 4'b1111;
    endcase
end

assign new_num = (|cols); // A column has been pressed

endmodule