`timescale 1ns / 1ps

`include "rtl/top.v"
`include "rtl/keyboard_ctrl.v"
`include "rtl/keyboard_lut.v"
`include "rtl/counter.v"
`include "rtl/debouncer.v"
`include "rtl/reg4Bit.v"
`include "rtl/game_mem.v"
`include "rtl/lfsr_prng.v"
`include "rtl/game_logic.v"

module top_tb;

    // Inputs
    reg clk;
    reg rstn;
    reg [2:0] keyboard_cols; 
    
    reg [7:0] hack_number = 0;
    reg load_hack = 0;
    reg player_sel = 0;
    reg next = 0;

    // Outputs
    wire [3:0] keyboard_rows;
    wire [7:0] selcted_number;
    wire [7:0] output_number;

    // Instantiate the Unit Under Test (UUT)
    top uut (
        .clk(clk), 
        .rstn(rstn), 
        .keyboard_cols(keyboard_cols), 
        .hack_number(hack_number),
        .load_hack(load_hack),
        .player_sel(player_sel),
        .next(next),
        .keyboard_rows(keyboard_rows), 
        .selcted_number(selcted_number), 
        .output_number(output_number)
    );

    // Override the counter parameter for faster simulation
    defparam uut.keyboard_ctrl_inst.debounce_counter.COUNT = 20;
    defparam uut.game_logic_inst.counter_inst.COUNT = 50; 

    // Keypad Model State
    reg [3:0] pressed_row_mask; 
    reg [2:0] pressed_col_mask; 

    // Keypad Logic
    always @(*) begin
        if ((keyboard_rows & pressed_row_mask) != 0) begin
            keyboard_cols = pressed_col_mask;
        end else begin
            keyboard_cols = 3'b0;
        end
    end

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end

    // Task to simulate a key press
    task press_key;
        input [3:0] r;
        input [2:0] c;
        input [3:0] expected_val; 
        begin
            pressed_row_mask = r;
            pressed_col_mask = c;
            #3000; 
        end
    endtask

    task release_key;
        begin
            pressed_row_mask = 4'b0;
            pressed_col_mask = 3'b0;
            #3000;
        end
    endtask

    // Task to input a full 2-digit number
    task input_number;
        input [3:0] d1;
        input [3:0] d2;
        input [3:0] r1, c1;
        input [3:0] r2, c2;
        begin
            press_key(r1, c1, d1);
            release_key();
            press_key(r2, c2, d2);
            release_key();
        end
    endtask

    // Helper to map hex digit to keypad coordinates
    task get_key_coords;
        input [3:0] val;
        output [3:0] r;
        output [2:0] c;
        begin
            case(val)
                4'h1: begin r=4'b1000; c=3'b100; end
                4'h2: begin r=4'b1000; c=3'b010; end
                4'h3: begin r=4'b1000; c=3'b001; end
                4'h4: begin r=4'b0100; c=3'b100; end
                4'h5: begin r=4'b0100; c=3'b010; end
                4'h6: begin r=4'b0100; c=3'b001; end
                4'h7: begin r=4'b0010; c=3'b100; end
                4'h8: begin r=4'b0010; c=3'b010; end
                4'h9: begin r=4'b0010; c=3'b001; end
                4'hA: begin r=4'b0001; c=3'b100; end 
                4'h0: begin r=4'b0001; c=3'b010; end
                4'hB: begin r=4'b0001; c=3'b001; end 
                default: begin r=4'b0000; c=3'b000; end
            endcase
        end
    endtask

    // Scoreboard
    integer p1_score, p2_score;

    function integer count_set_bits;
        input [7:0] val;
        integer k;
        begin
            count_set_bits = 0;
            for (k = 0; k < 8; k = k + 1) begin
                if (val[k]) count_set_bits = count_set_bits + 1;
            end
        end
    endfunction

    task update_scoreboard;
        reg [15:0] current_state;
        begin
            current_state = uut.game_logic_inst.game_state;
            p1_score = count_set_bits(current_state[7:0]);
            p2_score = count_set_bits(current_state[15:8]);
            
            $display("--------------------------------------------------");
            $display("SCOREBOARD: Player 1: %0d/8 | Player 2: %0d/8", p1_score, p2_score);
            $display("GAME STATE: %b", current_state);
            $display("FSM STATE:  %0d", uut.game_logic_inst.current_state);
            $display("--------------------------------------------------");
        end
    endtask

    // Task: Wait for FSM to reach E1 (idle), with timeout
    task wait_fsm_idle;
        integer timeout;
        begin
            timeout = 0;
            while (uut.game_logic_inst.current_state !== 1 && timeout < 100000) begin
                @(posedge clk);
                timeout = timeout + 1;
            end
            if (timeout >= 100000) 
                $display("WARNING: FSM did not return to E1 within timeout (state=%0d)", uut.game_logic_inst.current_state);
        end
    endtask

    // Task: Guess a number (set hack, pulse next, wait for FSM)
    task guess_number;
        input [7:0] number;
        input integer idx;
        begin
            // Set hack number BEFORE pulsing next
            hack_number = number;
            $display("Time=%t | Guessing: %h (Targeting Index %0d)", $time, number, idx);
            
            // Wait for FSM to be in E1 (ready for next)
            wait_fsm_idle();
            
            // Pulse next - drive AFTER clock edge to avoid race condition with next_edge_r FF
            @(posedge clk);
            #1; // Small delta-delay: ensures FF samples next=0 on this edge, next=1 on the next
            next = 1;
            @(posedge clk);
            #1;
            next = 0;
            
            // Wait for FSM to process (scan memory, find/not find, return to E1)
            wait_fsm_idle();
            
            // Display scoreboard
            update_scoreboard();
        end
    endtask

    // Test Stimulus
    reg [7:0] expected_mem [0:15];
    integer i;
    reg [3:0] d1, d2;
    reg [3:0] r1, r2; 
    reg [2:0] c1, c2;

    initial begin
        // Dump waves
        $dumpfile("top_tb.vcd");
        $dumpvars(0, top_tb);

        // Initialize Inputs
        rstn = 0;
        pressed_row_mask = 0;
        pressed_col_mask = 0;
        next = 0;
        load_hack = 0;
        hack_number = 0;

        // Reset
        #100;
        rstn = 1;
        #100;
        
        $display("==========================================");
        $display("  BINGO - Full Game Verification");
        $display("==========================================");
        
        // --- 1. Fill Memory ---
        // P1 (Indices 0-7): 0x01, 0x02, ... 0x08
        // P2 (Indices 8-15): 0x11, 0x12, ... 0x18
        $display("Phase 1: Populating Memory");
        for(i = 0; i < 16; i = i + 1) begin
            if (i < 8) begin
                d1 = 0;
                d2 = (i + 1) % 10;
            end else begin
                d1 = 1;
                d2 = (i - 8 + 1) % 10;
            end
            
            expected_mem[i] = {d1, d2};
            
            get_key_coords(d1, r1, c1);
            get_key_coords(d2, r2, c2);
            input_number(d1, d2, r1, c1, r2, c2);
            #1000;
        end

        // Print memory contents
        $display("Memory Contents:");
        for(i = 0; i < 16; i = i + 1) begin
            $display("  Mem[%0d] = %h (expected %h)", i, uut.game_mem_inst.mem[i], expected_mem[i]);
        end

        // --- 2. Start Game ---
        $display("Phase 2: Starting Game");
        get_key_coords(4'hB, r1, c1);
        press_key(r1, c1, 4'hB);
        release_key();
        
        #1000;
        if(uut.keyboard_ctrl_inst.start_game) $display("Game Started.");
        else $error("Error: Game did not start!");

        update_scoreboard();

        // --- 3. Player 1 Win Scenario ---
        $display("Phase 3: Simulating Player 1 Win (Hack Mode)");
        load_hack = 1;
        
        // Guess all P1 numbers one by one
        for(i = 0; i < 8; i = i + 1) begin
            guess_number(expected_mem[i], i);
        end
        
        // --- 4. Verify Endgame ---
        $display("Phase 4: Checking Endgame");
        if (uut.game_logic_inst.endgame) begin
             $display("BINGO! Player 1 Wins!");
        end else begin
             $display("Endgame NOT reached. FSM State: %0d, Game State: %b", 
                      uut.game_logic_inst.current_state, uut.game_logic_inst.game_state);
        end

        // --- 5. Final Memory Check ---
        $display("Phase 5: Final Memory State");
        for(i = 0; i < 16; i = i + 1) begin
            if (i < 8) begin
                // P1 entries should be cleared (deleted)
                if(uut.game_mem_inst.mem[i] === 8'h00) 
                    $display("  Mem[%0d]: Cleared (OK)", i);
                else 
                    $error("  Mem[%0d]: NOT cleared! Value: %h", i, uut.game_mem_inst.mem[i]);
            end else begin
                // P2 entries should be untouched
                if(uut.game_mem_inst.mem[i] === expected_mem[i]) 
                    $display("  Mem[%0d]: Intact (OK) Value: %h", i, uut.game_mem_inst.mem[i]);
                else 
                    $error("  Mem[%0d]: MODIFIED! Expected: %h, Got: %h", i, expected_mem[i], uut.game_mem_inst.mem[i]);
            end
        end

        #100000;
        $display("==========================================");
        $display("  Simulation Complete");
        $display("==========================================");
        $finish;
    end

endmodule
