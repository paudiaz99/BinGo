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
`include "rtl/visualization.v"
`include "rtl/bcd_7_seg.v"

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
    wire [7:0] hex_selcted_number_1;
    wire [7:0] hex_selcted_number_2;
    wire [7:0] hex_gessed_number_1;
    wire [7:0] hex_gessed_number_2;
    wire [8:0] game_state_leds;

    // Instantiate the Unit Under Test (UUT)
    top uut (
        .clk(clk), 
        .rstn(rstn), 
        .keyboard_cols(keyboard_cols), 
        .hack_number(hack_number),
        .load_hack(load_hack),
        .next(next),
        .keyboard_rows(keyboard_rows), 
        .hex_selcted_number_1(hex_selcted_number_1),
        .hex_selcted_number_2(hex_selcted_number_2),
        .hex_gessed_number_1(hex_gessed_number_1),
        .hex_gessed_number_2(hex_gessed_number_2),
        .game_state_leds(game_state_leds)
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

    // Results & Scoreboard
    integer total_passes = 0;
    integer total_fails = 0;
    integer p1_score, p2_score;

    task check_result;
        input condition;
        input string msg;
        begin
            if (condition) begin
                $display("  [PASS] %s", msg);
                total_passes = total_passes + 1;
            end else begin
                $display("  [FAIL] %s", msg);
                total_fails = total_fails + 1;
            end
        end
    endtask

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

    task trigger_next;
        begin
            wait_fsm_idle();
            @(posedge clk);
            #1;
            next = 1;
            @(posedge clk);
            #1;
            next = 0;
            wait_fsm_idle();
        end
    endtask

    // Test Stimulus
    reg [7:0] expected_mem [0:15];
    integer i, j;
    reg [3:0] d1, d2;
    reg [3:0] r1, r2; 
    reg [2:0] c1, c2;
    reg found_in_mem;

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

        // Verify initial memory
        $display("Verifying Initial Memory Integrity:");
        for(i = 0; i < 16; i = i + 1) begin
            check_result(uut.game_mem_inst.mem[i] === expected_mem[i], 
                $sformatf("Mem[%0d] = %h (Expected)", i, expected_mem[i]));
        end

        // --- 2. Start Game ---
        $display("Phase 2: Starting Game");
        get_key_coords(4'hB, r1, c1);
        press_key(r1, c1, 4'hB);
        release_key();
        #1000;
        check_result(uut.keyboard_ctrl_inst.start_game, "Game Start flag asserted");
        update_scoreboard();

        // --- 3. Random Mode Testing ---
        $display("Phase 3: Random Game Verification (LFSR Mode)");
        load_hack = 0;
        i = 0;
        while (i < 10 && !uut.game_logic_inst.endgame) begin
            reg [7:0] random_guess;
            random_guess = uut.prng_number;
            $display("Turn %0d: PRNG Guessed %h", i, random_guess);
            
            // Pulse Next
            trigger_next();
            
            update_scoreboard();
            
            if (uut.game_logic_inst.endgame) begin
                $display("  Natural BINGO occurred during random phase!");
            end
            i = i + 1;
        end

        // --- 4. Player 1 Win Scenario ---
        if (!uut.game_logic_inst.endgame) begin
            $display("Phase 4: Simulating Player 1 Win (Hack Mode)");
            load_hack = 1;
            for(i = 0; i < 8; i = i + 1) begin
                // Only guess if NOT already cleared (P1 indices 0-7)
                if (uut.game_mem_inst.mem[i] !== 8'h00) begin
                    hack_number = expected_mem[i];
                    $display("Guessing %h (Index %0d)", hack_number, i);
                    trigger_next();
                    check_result(uut.game_logic_inst.game_state[i] === 1'b1, 
                        $sformatf("Game state bit %0d set correctly", i));
                    check_result(uut.game_mem_inst.mem[i] === 8'h00, 
                        $sformatf("Memory index %0d cleared", i));
                end else begin
                    $display("Index %0d already cleared naturally.", i);
                end
            end
            check_result(uut.game_logic_inst.endgame, "Endgame (BINGO) reached for P1");
        end
        
        update_scoreboard();

        // --- 5. Final Summary ---
        #100000;
        $display("==========================================");
        $display("  VERIFICATION SUMMARY");
        $display("==========================================");
        $display("  Total Tests Passed: %0d", total_passes);
        $display("  Total Tests Failed: %0d", total_fails);
        if (total_fails == 0) begin
            $display("  RESULT: ALL TESTS PASSED");
        end else begin
            $display("  RESULT: %0d TESTS FAILED", total_fails);
        end
        $display("==========================================");
        $finish;
    end

endmodule
