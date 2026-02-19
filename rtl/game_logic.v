module game_logic #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4,
    parameter NUM_ENTRIES = 16,
    parameter NUM_ENTRIES_PLAYER = 8
) (
    input clk,
    input rstn,
    input start_game,
    input [DATA_WIDTH-1:0] guessed_number,
    input next_edge,
    input [DATA_WIDTH-1:0] ram_read_number,

    output reg [NUM_ENTRIES-1:0] game_state,
    output wire ram_delete,
    output wire ram_write_en,
    output wire enable_displays,
    output wire [ADDR_WIDTH-1:0] ram_addr,
    output reg [DATA_WIDTH-1:0] guessed_number_r,
    output reg toggle_1s
);

// FSM States
localparam E0 = 0;
localparam E1 = 1;
localparam E2 = 2;
localparam E3 = 3;
localparam E4 = 4;
localparam E5 = 5;
localparam E6 = 6;
localparam E7 = 7;
localparam E8 = 8;

reg [3:0] current_state;
reg [3:0] next_state;

wire found = ram_read_number == guessed_number_r;

wire endgame = &game_state[NUM_ENTRIES_PLAYER-1:0] | &game_state[NUM_ENTRIES-1:NUM_ENTRIES_PLAYER];

always @* begin
    case(current_state)
    E0: next_state = start_game ? E1 : E0;
    E1: next_state = next_edge ? E2 : E1;
    E2: next_state = E3;
    E3: next_state = found ? E5 : (address_overflow ? E1 : E4);
    E4: next_state = E3;
    E5: next_state = ram_addr[3] ? E6 : E7;
    E6: next_state = endgame ? E8 : (address_overflow ? E1 : E4);
    E7: next_state = endgame ? E8 : (address_overflow ? E1 : E4);
    E8: next_state = E8;
    endcase
end

always @(posedge clk) begin
    if(~rstn) current_state <= E0;
    else current_state <= next_state;
end

// FSM Output Signals
wire enable_one_sec_counter = (current_state == E1);
wire reset_address_counter = (current_state == E1);
wire load_enable = (current_state == E2); // Load Guessed Number
wire enable_address_counter = (current_state == E4);
wire update_player = (current_state == E6) | (current_state == E7);


assign enable_displays = (current_state == E3);
assign ram_write_en = (current_state == E5);
assign ram_delete = (current_state == E5);


// Guessed number register
always @(posedge clk) begin
    if(~rstn) guessed_number_r <= 8'b0;
    else if(load_enable) guessed_number_r <= guessed_number;
end

// Address Counter
wire address_overflow = ram_addr == 4'b1111;

counter #(
    .COUNT(256),
    .WIDTH(ADDR_WIDTH)
)address_counter(
    .clk(clk),
    .rstn(~reset_address_counter),
    .enable(enable_address_counter),
    .val(ram_addr),
    .overflow()
);


// 1s Counter
wire one_sec_overflow;

counter #(
    .COUNT(50) // 100000000 for 1s @ 100MHzç
)counter_inst(
    .clk(clk),
    .rstn(rstn),
    .enable(enable_one_sec_counter),
    .val(),
    .overflow(one_sec_overflow)
);

always @(posedge clk) begin
    if(~rstn) toggle_1s <= 1'b0;
    else if(one_sec_overflow) toggle_1s <= ~toggle_1s;
end

// Game State Register
always @(posedge clk) begin
    if(~rstn) game_state <= 16'b0;
    else if(update_player) game_state <= game_state | (1 << ram_addr);
end



endmodule