# Àyò Ọ̀pọ̀ — Yoruba Strategy Game

A Godot 4 mobile-friendly prototype of traditional Yoruba Ayo Ọ̀pọ̀.

## Play modes
- **Vs Computer:** Easy (random legal moves), Medium, Hard and Expert (minimax search with alpha-beta pruning).
- **Local 2-player:** pass the device between players.
- **Online direct connect prototype:** ENet host/join over UDP port **8910**, host-authoritative move state and host-controlled restart.

## Game rules in this prototype
- 12 pits; 4 seeds per pit at setup.
- Select a pit from your row and sow forward one seed at a time, skipping the emptied starting pit on lap(s).
- Capture when the final seed lands in the opponent's pit and the pit contains 2 or 3 seeds.
- Chain capture backward through adjacent qualifying opponent pits.
- When the opponent has no seeds, feed them if a legal feeding move exists.
- If a player cannot move or feed, remaining seeds are collected and the game ends.

## Run locally
1. Install Godot 4.x.
2. Clone this repository.
3. Open `project.godot` in Godot.
4. Press Play.

## Online limitations
Online mode is an early direct-connect demo, **not** matchmaking. Host listens on UDP 8910. Depending on the host's network/router/firewall, incoming connections may require UDP port forwarding or a network that permits direct peer connections. Both devices may need to be on compatible networks. A production build should use a dedicated relay/server, room codes, robust validation, reconnect handling, and security hardening.

## Verification status
This repository was updated by remote file commits, but the project has not yet been run in Godot in this environment. Please test/verify scene startup, mobile scaling, AI response speed and online connectivity before considering it playable or release-ready.

## Next polish
- Seed-by-seed movement animation and sound.
- Better board sizing for narrow/landscape screens.
- Tutorial and rule variants.
- Online lobby/relay, NAT traversal, reconnect and stronger network security (direct connect remains fragile).
- Android export presets and release testing.

## Cultural note
Ayo has house and regional variations. This is a playable prototype interpretation, not a definitive rules authority; review the capture, feeding and end-game rules with experienced players.
