module visualization(
    input clk,
    input rstn,
    input [7:0] number_1,
    input [7:0] number_2,
    input enable_displays_1,
    input enable_displays_2,

    output [7:0] seg_1,
    output [7:0] seg_2,
    output [7:0] seg_3,
    output [7:0] seg_4
);

    wire [3:0] bcd_1 = enable_displays_1 ? number_1[3:0] : 4'b1111;
    wire [3:0] bcd_2 = enable_displays_1 ? number_1[7:4] : 4'b1111;
    wire [3:0] bcd_3 = enable_displays_2 ? number_2[3:0] : 4'b1111;
    wire [3:0] bcd_4 = enable_displays_2 ? number_2[7:4] : 4'b1111;

    bcd_7_seg bcd_7_seg_inst_1(
        .bcd(bcd_1),
        .seg(seg_1)
    );

    bcd_7_seg bcd_7_seg_inst_2(
        .bcd(bcd_2),
        .seg(seg_2)
    );

    bcd_7_seg bcd_7_seg_inst_3(
        .bcd(bcd_3),
        .seg(seg_3)
    );

    bcd_7_seg bcd_7_seg_inst_4(
        .bcd(bcd_4),
        .seg(seg_4)
    );

endmodule 