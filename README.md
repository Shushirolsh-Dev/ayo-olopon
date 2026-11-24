# Àyò Ọ̀pọ̀ — Yoruba Strategy Game

A Godot 4 prototype of the traditional Yoruba Ayo Ọ̀pọ̀ board game, with a warm wood-and-seed visual style.

## Features in this prototype
- **Play vs Computer:** Easy (random legal play), Medium, Hard, and Expert (search deeper with alpha-beta minimax).
- **Local multiplayer:** two players share a device.
- **Online multiplayer prototype:** ENet host/join over UDP port **8910**. The host is authoritative and synchronizes board state.
- **Offline-first:** computer and same-device modes work without network.
- **Board:** 12 pits, 4 seeds per pit at start.
- **Rules:** forward sowing, 2/3 capture, backward chain capture, and feed-if-starved behavior.

## Open in Godot
1. Install Godot 4.x.
2. Clone/download this repo.
3. Open `project.godot` in Godot.
4. Run the project.

## Online notes / limitations
The ENet mode is an early direct-connect prototype, not a matchmaking service. Host uses UDP 8910; players may need port forwarding or a network that permits direct inbound connections. For production online play, replace direct hosting with a relay/server, add lobby codes, disconnect handling, server-side rule validation, and anti-cheat.

## Rule note
The game implements a commonly described Ayo Olopon rule set, but traditional house and regional variations exist. Validate capture/feed/end-game rules with experienced players before presenting a definitive rules guide.

## Roadmap
- [ ] Verify script and game behavior in Godot editor/runtime.
- [ ] Add animated seed-by-seed sowing and sound assets.
- [ ] Refine touch layout for small phones.
- [ ] Add online relay/lobby infrastructure and reconnect flow.
- [ ] Add Yoruba/English localization, tutorial, match history, and release packaging.
