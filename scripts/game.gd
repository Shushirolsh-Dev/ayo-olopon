extends Control

const N := 12
const FOUR := 4
const TOP := [11, 10, 9, 8, 7, 6]
const BOTTOM := [0, 1, 2, 3, 4, 5]
const PORT := 8910
const AI_DEPTH := 3

enum Mode { MENU, AI, LOCAL, ONLINE }
var mode := Mode.MENU
var difficulty := 1
var pits: Array[int] = []
var scores := [0, 0]
var turn := 0
var ended := false
var message := "Choose a game mode"
var pit_rects: Dictionary = {}
var ui_buttons: Array[Button] = []
var ai_busy := false
var network_peer: ENetMultiplayerPeer
var network_connected := false
var online_host := false
var host_address := "127.0.0.1"
var address_input: LineEdit
var mode_panel: VBoxContainer
var game_panel: Control
var board_canvas: Control
var menu_panel: VBoxContainer

func _ready() -> void:
	_build_shell()
	show_menu()

func _build_shell() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 8)
	add_child(root)
	var top := HBoxContainer.new()
	root.add_child(top)
	var brand := Label.new()
	brand.text = "ÀYÒ Ọ̀PỌ̀"
	brand.add_theme_font_size_override("font_size", 25)
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(brand)
	var back := Button.new()
	back.text = "Home"
	back.pressed.connect(show_menu)
	top.add_child(back)
	var separator := HSeparator.new()
	root.add_child(separator)
	var content := Control.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(content)
	menu_panel = VBoxContainer.new()
	menu_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_panel.alignment = BoxContainer.ALIGNMENT_CENTER
	menu_panel.add_theme_constant_override("separation", 12)
	content.add_child(menu_panel)
	board_canvas = Control.new()
	board_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board_canvas.draw.connect(_draw_board)
	board_canvas.gui_input.connect(_board_input)
	content.add_child(board_canvas)
	board_canvas.hide()

func _clear_menu() -> void:
	for child in menu_panel.get_children():
		child.queue_free()

func _add_menu_label(text: String, font_size := 18) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	menu_panel.add_child(label)

func _add_menu_button(text: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(250, 52)
	b.pressed.connect(callback)
	menu_panel.add_child(b)
	return b

func show_menu() -> void:
	mode = Mode.MENU
	ai_busy = false
	board_canvas.hide()
	menu_panel.show()
	_clear_menu()
	_add_menu_label("ÀYÒ Ọ̀PỌ̀", 38)
	_add_menu_label("A traditional Yoruba strategy game", 16)
	_add_menu_button("Play vs Computer", start_ai)
	_add_menu_button("Two Players · Same Device", start_local)
	_add_menu_button("Online · Host Game", host_game)
	_add_menu_button("Online · Join Game", join_game)
	_add_menu_label("Offline modes work without internet.", 14)

func _setup_board(new_mode: Mode) -> void:
	mode = new_mode
	menu_panel.hide()
	board_canvas.show()
	reset_board()
	board_canvas.queue_redraw()

func start_ai() -> void:
	_clear_menu()
	_add_menu_label("Choose computer difficulty", 24)
	_add_menu_button("Easy", func(): _begin_ai(0))
	_add_menu_button("Medium", func(): _begin_ai(1))
	_add_menu_button("Hard", func(): _begin_ai(2))
	_add_menu_button("Expert", func(): _begin_ai(3))
	_add_menu_button("Back", show_menu)

func _begin_ai(level: int) -> void:
	difficulty = level
	_setup_board(Mode.AI)
	message = "Your turn. Choose a pit."
	refresh_board()

func start_local() -> void:
	_setup_board(Mode.LOCAL)
	message = "Player 1 starts. Tap your row."
	refresh_board()

func host_game() -> void:
	_clear_menu()
	_add_menu_label("Host online game", 24)
	_add_menu_label("Share your public IP and port 8910 with your opponent.", 15)
	_add_menu_button("Start hosting", _start_host)
	_add_menu_button("Back", show_menu)

func _start_host() -> void:
	network_peer = ENetMultiplayerPeer.new()
	var err := network_peer.create_server(PORT, 1)
	if err != OK:
		message = "Could not host (error %d). Check network." % err
		show_menu()
		return
	multiplayer.multiplayer_peer = network_peer
	online_host = true
	network_connected = true
	multiplayer.peer_connected.connect(_on_peer_connected)
	_setup_board(Mode.ONLINE)
	message = "Hosting on UDP %d. Waiting for opponent..." % PORT
	refresh_board()

func join_game() -> void:
	_clear_menu()
	_add_menu_label("Join online game", 24)
	address_input = LineEdit.new()
	address_input.placeholder_text = "Host IP address"
	address_input.text = host_address
	address_input.custom_minimum_size = Vector2(250, 46)
	menu_panel.add_child(address_input)
	_add_menu_button("Connect", _start_join)
	_add_menu_button("Back", show_menu)

func _start_join() -> void:
	host_address = address_input.text.strip_edges()
	if host_address.is_empty():
		return
	network_peer = ENetMultiplayerPeer.new()
	var err := network_peer.create_client(host_address, PORT)
	if err != OK:
		message = "Connection failed to start (%d)." % err
		return
	multiplayer.multiplayer_peer = network_peer
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	_setup_board(Mode.ONLINE)
	message = "Connecting to %s..." % host_address
	refresh_board()

func _on_peer_connected(id: int) -> void:
	message = "Opponent connected! Your move."
	refresh_board()
	_broadcast_state.rpc(pits, scores, turn, ended, message)

func _on_connected() -> void:
	network_connected = true
	message = "Connected. Waiting for host board."
	refresh_board()

func _on_connection_failed() -> void:
	message = "Connection failed. Check host IP and network."
	refresh_board()

func reset_board() -> void:
	pits.clear()
	pits.resize(N)
	pits.fill(FOUR)
	scores = [0, 0]
	turn = 0
	ended = false
	ai_busy = false
	message = "Player 1 starts"

func refresh_board() -> void:
	board_canvas.queue_redraw()

func _draw_board() -> void:
	var size := board_canvas.size
	board_canvas.draw_rect(Rect2(Vector2.ZERO, size), Color("#17130f"))
	var font := ThemeDB.fallback_font
	var title := "ÀYÒ Ọ̀PỌ̀"
	board_canvas.draw_string(font, Vector2(size.x * 0.5 - 80, 36), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("#e8c27c"))
	var width := min(size.x - 24.0, 880.0)
	var height := min(size.y * 0.54, 320.0)
	var x := (size.x - width) / 2.0
	var y := max(65.0, (size.y - height) * 0.42)
	var board := Rect2(x, y, width, height)
	board_canvas.draw_rect(board, Color("#51341f"))
	board_canvas.draw_rect(board, Color("#b58a51"), false, 3)
	pit_rects.clear()
	var gap := 7.0
	var pad := 16.0
	var cw := (width - 2 * pad - 5 * gap) / 6.0
	var ch := (height - 34 - gap) / 2.0
	for row in 2:
		for col in 6:
			var id: int = TOP[col] if row == 0 else BOTTOM[col]
			var rect := Rect2(x + pad + col * (cw + gap), y + 17 + row * (ch + gap), cw, ch)
			pit_rects[id] = rect
			board_canvas.draw_rect(rect, Color("#241b14"))
			board_canvas.draw_rect(rect, Color("#87613a"), false, 2)
			_draw_seed_art(rect, pits[id])
			var fsize := int(clamp(ch * 0.23, 16, 26))
			board_canvas.draw_string(font, rect.position + Vector2(rect.size.x * 0.5 - 7, rect.size.y * 0.5 + fsize * 0.35), str(pits[id]), HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, Color("#f5e3c4"))
	var status_y := y + height + 35
	var status := "GAME OVER" if ended else ("YOUR TURN" if mode == Mode.AI and turn == 0 else ("COMPUTER THINKING" if mode == Mode.AI else ("PLAYER %d TURN" % (turn + 1))))
	board_canvas.draw_string(font, Vector2(size.x * 0.5 - 95, status_y), status, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#e8c27c"))
	board_canvas.draw_string(font, Vector2(size.x * 0.5 - 145, status_y + 28), message, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#eee1cf"))
	board_canvas.draw_string(font, Vector2(size.x * 0.5 - 110, status_y + 56), "Captured: P1 %d  ·  P2 %d" % [scores[0], scores[1]], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#d2b48c"))
	board_canvas.draw_string(font, Vector2(16, size.y - 16), "Tap a pit on your row.  ·  Home returns to menu.", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#9b8974"))

func _draw_seed_art(rect: Rect2, count: int) -> void:
	var center := rect.get_center()
	var radius := max(3.0, min(rect.size.x, rect.size.y) * 0.07)
	for i in min(count, 12):
		var angle := float(i) * 2.399963
		var ring := 6.0 + float(i % 4) * 6.5
		board_canvas.draw_circle(center + Vector2(cos(angle), sin(angle)) * ring, radius, Color("#c69b5e"))
	if count > 12:
		board_canvas.draw_string(ThemeDB.fallback_font, center + Vector2(-8, 4), "+%d" % (count - 12), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#fff0d7"))

func _board_input(event: InputEvent) -> void:
	if ended or ai_busy:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_try_pick(event.position)
	elif event is InputEventScreenTouch and event.pressed:
		_try_pick(event.position)

func _try_pick(pos: Vector2) -> void:
	if mode == Mode.AI and turn != 0:
		return
	if mode == Mode.ONLINE:
		if not network_connected:
			message = "Not connected yet."
			refresh_board()
			return
		if (online_host and turn != 0) or (not online_host and turn != 1):
			message = "Waiting for opponent."
			refresh_board()
			return
	for id in pit_rects:
		if pit_rects[id].has_point(pos):
			if _owns(id, turn) and pits[id] > 0:
				_apply_turn(id)
			else:
				message = "Choose a seeded pit on your side."
			refresh_board()
			return

func _owns(id: int, player: int) -> bool:
	return id < 6 if player == 0 else id >= 6

func _has_move(board: Array, player: int) -> bool:
	for id in N:
		if _owns(id, player) and board[id] > 0:
			return true
	return false

func _feeds(board: Array, move: int, player: int) -> bool:
	var count: int = board[move]
	var cursor := move
	while count > 0:
		cursor = (cursor + 1) % N
		if cursor != move and _owns(cursor, 1 - player):
			return true
		count -= 1
	return false

func _legal_moves(board: Array, player: int) -> Array[int]:
	var moves: Array[int] = []
	var opponent_has := _has_move(board, 1 - player)
	for id in N:
		if not _owns(id, player) or board[id] <= 0:
			continue
		if not opponent_has and not _feeds(board, id, player):
			continue
		moves.append(id)
	return moves

func _simulate(board: Array, capture_scores: Array, player: int, move: int) -> Dictionary:
	var next: Array = board.duplicate()
	var next_scores: Array = capture_scores.duplicate()
	var seeds: int = next[move]
	next[move] = 0
	var cursor := move
	while seeds > 0:
		cursor = (cursor + 1) % N
		if cursor != move:
			next[cursor] += 1
		seeds -= 1
	if _owns(cursor, 1 - player) and next[cursor] in [2, 3]:
		while _owns(cursor, 1 - player) and next[cursor] in [2, 3]:
			next_scores[player] += next[cursor]
			next[cursor] = 0
			cursor = (cursor - 1 + N) % N
	var next_player := 1 - player
	if not _has_move(next, next_player) and _legal_moves(next, next_player).is_empty():
		for i in N:
			if i < 6:
				next_scores[0] += next[i]
			else:
				next_scores[1] += next[i]
			next[i] = 0
		return {"board": next, "scores": next_scores, "next": next_player, "terminal": true}
	return {"board": next, "scores": next_scores, "next": next_player, "terminal": false}

func _apply_turn(move: int) -> void:
	if mode == Mode.ONLINE and not online_host:
		_request_move.rpc_id(1, move)
		message = "Move sent to host..."
		refresh_board()
		return
	var state := _simulate(pits, scores, turn, move)
	pits = state.board
	scores = state.scores
	turn = state.next
	ended = state.terminal
	message = _winner_text() if ended else ("Player %d moved." % (turn + 1))
	if mode == Mode.ONLINE and online_host and multiplayer.multiplayer_peer != null and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		_broadcast_state.rpc(pits, scores, turn, ended, message)
	refresh_board()
	if mode == Mode.AI and turn == 1 and not ended:
		ai_busy = true
		message = "Computer is thinking..."
		refresh_board()
		await get_tree().create_timer(0.35).timeout
		var choice := _choose_ai_move()
		ai_busy = false
		if choice >= 0:
			_apply_turn(choice)

func _winner_text() -> String:
	if scores[0] > scores[1]:
		return "Player 1 wins!"
	if scores[1] > scores[0]:
		return "Player 2 wins!"
	return "Draw!"

func _choose_ai_move() -> int:
	var options := _legal_moves(pits, 1)
	if options.is_empty():
		return -1
	if difficulty == 0:
		return options[randi() % options.size()]
	var best := options[0]
	var best_score := -INF
	var depth := 2 if difficulty == 1 else (3 if difficulty == 2 else 4)
	for move in options:
		var state := _simulate(pits, scores, 1, move)
		var value := _minimax(state.board, state.scores, state.next, depth - 1, -INF, INF, state.terminal)
		if value > best_score:
			best_score = value
			best = move
	return best

func _minimax(board: Array, capture_scores: Array, player: int, depth: int, alpha: float, beta: float, terminal: bool) -> float:
	var eval := float(capture_scores[1] - capture_scores[0]) + _board_eval(board)
	if terminal or depth <= 0:
		return eval
	var moves := _legal_moves(board, player)
	if moves.is_empty():
		return eval
	if player == 1:
		var best := -INF
		for move in moves:
			var s := _simulate(board, capture_scores, player, move)
			best = max(best, _minimax(s.board, s.scores, s.next, depth - 1, alpha, beta, s.terminal))
			alpha = max(alpha, best)
			if beta <= alpha:
				break
		return best
	var best := INF
	for move in moves:
		var s := _simulate(board, capture_scores, player, move)
		best = min(best, _minimax(s.board, s.scores, s.next, depth - 1, alpha, beta, s.terminal))
		beta = min(beta, best)
		if beta <= alpha:
			break
	return best

func _board_eval(board: Array) -> float:
	var value := 0.0
	for i in N:
		if i >= 6:
			value += board[i] * 0.12
		else:
			value -= board[i] * 0.12
	return value

@rpc("any_peer", "call_remote", "reliable")
func _request_move(move: int) -> void:
	if not online_host or mode != Mode.ONLINE:
		return
	if turn != 1 or move < 6 or move > 11 or pits[move] <= 0:
		return
	_apply_turn(move)

@rpc("authority", "call_remote", "reliable")
func _broadcast_state(b: Array, s: Array, player: int, finished: bool, msg: String) -> void:
	if online_host:
		return
	pits = b
	scores = s
	turn = player
	ended = finished
	message = msg
	refresh_board()
