module game_mem #(
    parameter ENTRIES = 16,
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 8

)(
    input clk,
    input rstn,
    input [ADDR_WIDTH-1:0] addr,
    input [DATA_WIDTH-1:0] data_in,
    input write_en,
    output [DATA_WIDTH-1:0] data_out
);

    reg [DATA_WIDTH-1:0] mem [ENTRIES-1:0];
    reg [ENTRIES-1:0] valid_mem;

    always @(posedge clk) begin
        if(~rstn) begin
            valid_mem <= {ENTRIES{1'b0}};
        end else if(write_en) begin
            mem[addr] <= data_in;
            valid_mem[addr] <= 1'b1;
        end
    end

    assign data_out = valid_mem[addr] ? mem[addr] : 8'b0;

endmodule