# Àyò Ọ̀pọ̀ (Ayo Olopon)

A modern 2D digital version of the traditional Yoruba Ayo Ọ̀pọ̀ board game.

## Current prototype
- Godot 4 / GDScript
- 12 pits, 48 seeds (4 per pit)
- Local two-player hot-seat gameplay
- Sowing, capture, turn switching, feeding rule, and basic game-end detection

## Rules used for this prototype
This build follows the rules previously agreed in the project conversation: choose a pit from your own row, sow one seed at a time forward around the 12-pit loop, capture when the final seed lands in an opponent pit containing 2 or 3 seeds, and continue backward capturing consecutive opponent pits that also contain 2 or 3. If the opponent has no seeds, a move must feed them whenever a legal feeding move exists. Rule variations can be revised as we validate the implementation.


## Run
Open the project folder in Godot 4 and run `Main.tscn`.
