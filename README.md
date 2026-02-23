# BinGo

BinGo is a digital bingo game designed and synthesized using open source tools. The game was originally implemented in 74LS logic gate series as a university project. The goal of this project is to build the same system, but at the microelectronic level. Achieving a reduction in size of almost x500000.

<div align="center">
  <img src="https://github.com/user-attachments/assets/d8554dc3-b70a-4271-967f-ca9dc06e7137" alt="centered image">
  <br>
  <sup>BinGo ASIC visualized in GDS3D.</sup>
</div>

## How the game works:

The game is played by two players, each one has a bingo card with 8 two-digit numbers. At the beginning of the game, each player will choose their own numbers by introducing them via a matrix keyboard. Numbers are entered sequentially starting by first player's 8 numbers, then second player's 8 numbers. Every two digits, the game will automatically consider it as a number, and store it in memory.

Once the 16 numbers are selected, the game will wait for the players to pulse the '#' key in the keyboard for the game to start. Random numbers will be then generated once the button "next" is pressed, this is checked whether it is in the player's card. If it is, the game will update the game state and check if the player has won. If the player has won, the game will end. If the player hasn't, the game state updates, and waits for the next button to be pressed to generate a new random number.

To accelerate debugging, a "hack" number can be introduced by the player. The hack number will be used instead of the random number generator.

The game uses multiple visualization elements that enable the players to observe the game state. These are:
- Two 7-Segment displays to show the selected numbers.
- Two 7-Segment displays to show the guessed numbers.
- A 10-Led display to show the game state.

In order to interact with the game, players will also need:
- Matrix keyboard to introduce the numbers.
- A button for the "next" action.
- A button for the reset.
- 8 switches to introduce the hack number.
- A switch to select if the hack number is used or not.

## Synthesis

The BinGo ASIC was synthesized using librelane, and skywater130 pdk. Althought the synthesized RTL netlist and the final GDS are already available inside synth directory, I encourage you to perform the synthesis yourself following these steps:

```bash
cd your/path/to/librelane // Ensure that you already have librelane installed!

nix-shell // Enter nix shell environment

cd your/path/to/BinGo/synth/scripts // Enter the synthesis scripts directory

./run_synth.sh your/path/to/BinGo // Run the synthesis script
```

## Visualization

After the synthesis is done, you can visualize the synthesized design using the following commands inside the nix shell:

```bash
    cd your/path/to/BinGo/synth/scripts

    ./visualization.sh openroad  // Open the design in OpenROAD GUI
    ./visualization.sh klayout   // Open the design in KLayout GUI
    ./visualization.sh gds3d     // Open the design in GDS3D
```

> [!NOTE]
> You will need to update paths inside the visualization script to match your installation. Also, in order to visualize the design in GDS3D, you will need to specify the synthesis run name (e.g. RUN_2026-02-21_21-32-16).

## Gate-Level Simulation

To run GLS, you will first need to change the values of the following parameters in the verilog files in order to not simulate seconds and milisecond counters:
- `top.game_logic_inst.counter_inst.COUNT = 50;`
- `top.keyboard_ctrl_inst.debounce_counter.COUNT = 20;`

After that, you can run the GLS using the following command:

```bash
cd your/path/to/BinGo/synth/scripts

./run_gls.sh
```

## Tools
- Simulation: Icarus Verilog (https://github.com/steveicarus/iverilog)
- Waveform viewer: GTKWave (https://github.com/gtkwave/gtkwave)
- FPGA Synthesis: Quartus Prime Lite (Not open source but free for non-commercial use)
- Synthesis: librelane (https://github.com/librelane/librelane)


## Roadmap

- [x] Bingo Game Design
- [x] Verilog Implementation
- [x] Verification and Simulation
- [x] FPGA Synthesis and Validation
- [x] ASIC Implementation using librelane (https://github.com/librelane/librelane)
- [x] Verification of the ASIC

