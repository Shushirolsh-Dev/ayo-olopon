extends Control

const INITIAL_SEEDS := 4
const PIT_COUNT := 12
const HUMAN := 0
const TOP_ROW := [11, 10, 9, 8, 7, 6]
const BOTTOM_ROW := [0, 1, 2, 3, 4, 5]

var pits: Array[int] = []
var scores := [0, 0]
var current_player := HUMAN
var selected_pit := -1
var game_over := false
var message := "Player 1: choose a pit"
var pit_rects: Dictionary = {}

func _ready() -> void:
	reset_game()

func reset_game() -> void:
	pits = []
	pits.resize(PIT_COUNT)
	pits.fill(INITIAL_SEEDS)
	scores = [0, 0]
	current_player = HUMAN
	selected_pit = -1
	game_over = false
	message = "Player 1: choose a pit"
	queue_redraw()

func _draw() -> void:
	var size := get_viewport_rect().size
	var bg := Color("17130f")
	var board := Color("51341f")
	var pit_color := Color("241b14")
	var accent := Color("d5a45e")
	draw_rect(Rect2(Vector2.ZERO, size), bg)
	_draw_title(size)
	var board_w := min(size.x - 48.0, 920.0)
	var board_h := min(size.y * 0.54, 350.0)
	var board_x := (size.x - board_w) / 2.0
	var board_y := (size.y - board_h) / 2.0 + 22.0
	var board_rect := Rect2(board_x, board_y, board_w, board_h)
	draw_rect(board_rect, board, true, 0)
	draw_rect(board_rect, Color("b58a51"), false, 3)
	pit_rects.clear()
	var gap := 10.0
	var side_pad := 24.0
	var cell_w := (board_w - side_pad * 2.0 - gap * 5.0) / 6.0
	var cell_h := (board_h - 42.0 - gap) / 2.0
	for row in 2:
		for col in 6:
			var pit_id: int = TOP_ROW[col] if row == 0 else BOTTOM_ROW[col]
			var rect := Rect2(board_x + side_pad + col * (cell_w + gap), board_y + 20.0 + row * (cell_h + gap), cell_w, cell_h)
			pit_rects[pit_id] = rect
			draw_rect(rect, pit_color, true, 0)
			draw_rect(rect, Color("87613a"), false, 2)
			if pit_id == selected_pit:
				draw_rect(rect.grow(3), accent, false, 3)
			_draw_seeds(rect, pits[pit_id])
			var label := str(pits[pit_id])
			var font := ThemeDB.fallback_font
			var font_size := int(clamp(cell_h * 0.3, 18, 34))
			var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
			var text_pos := rect.position + Vector2((rect.size.x - text_size.x) / 2.0, rect.size.y / 2.0 + font_size / 3.0)
			draw_string(font, text_pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("f5e3c4"))
	_draw_status(size, board_y, board_h)

func _draw_title(size: Vector2) -> void:
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(size.x / 2.0 - 90, 55), "ÀYÒ Ọ̀PỌ̀", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("e8c27c"))
	draw_string(font, Vector2(size.x / 2.0 - 115, 80), "A Yoruba strategy game", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("b7a28b"))

func _draw_status(size: Vector2, board_y: float, board_h: float) -> void:
	var font := ThemeDB.fallback_font
	var player_text := "PLAYER 1 TURN" if current_player == 0 else "PLAYER 2 TURN"
	if game_over:
		player_text = "GAME OVER"
	var status_y := board_y + board_h + 46
	draw_string(font, Vector2(size.x / 2.0 - 105, status_y), player_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("e8c27c"))
	draw_string(font, Vector2(size.x / 2.0 - 145, status_y + 32), message, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("eee1cf"))
	draw_string(font, Vector2(size.x / 2.0 - 150, status_y + 66), "Captured: P1 %d     P2 %d" % [scores[0], scores[1]], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("d2b48c"))
	draw_string(font, Vector2(24, size.y - 26), "Tap a pit on your side. Pass the device for Player 2.", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("9b8974"))

func _draw_seeds(rect: Rect2, count: int) -> void:
	var center := rect.get_center()
	var radius := min(rect.size.x, rect.size.y) * 0.24
	for i in min(count, 16):
		var angle := float(i) * 2.399963
		var ring := 8.0 + float(i % 4) * 7.0
		var pos := center + Vector2(cos(angle), sin(angle)) * ring
		draw_circle(pos, radius, Color("c69b5e"))
		if count > 16:
			draw_string(ThemeDB.fallback_font, center + Vector2(-10, 5), "+%d" % (count - 16), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("fff0d7"))

func _gui_input(event: InputEvent) -> void:
	if game_over or current_player != HUMAN:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_tap(event.position)
	elif event is InputEventScreenTouch and event.pressed:
		_handle_tap(event.position)

func _handle_tap(pos: Vector2) -> void:
	for pit_id in pit_rects:
		if pit_rects[pit_id].has_point(pos):
			if _is_owned_pit(pit_id, current_player) and pits[pit_id] > 0:
				play_move(pit_id)
			else:
				message = "Choose a pit on your own row with seeds."
				queue_redraw()
			return

func _is_owned_pit(pit_id: int, player: int) -> bool:
	return pit_id >= 0 and pit_id <= 5 if player == 0 else pit_id >= 6 and pit_id <= 11

func _has_seeds(player: int) -> bool:
	for i in PIT_COUNT:
		if _is_owned_pit(i, player) and pits[i] > 0:
			return true
	return false

func _can_feed(player: int) -> bool:
	var opponent := 1 - player
	if _has_seeds(opponent):
		return true
	for i in PIT_COUNT:
		if _is_owned_pit(i, player) and pits[i] > 0:
			var count := pits[i]
			var cursor := i
			for _seed in count:
				cursor = (cursor + 1) % PIT_COUNT
				if _is_owned_pit(cursor, opponent):
				return true
	return false

func play_move(pit_id: int) -> void:
	if pits[pit_id] <= 0:
		return
	if not _has_seeds(1 - current_player) and not _move_feeds_opponent(pit_id):
		message = "You must feed your opponent if possible."
		queue_redraw()
		return
	var seeds := pits[pit_id]
		pits[pit_id] = 0
	var cursor := pit_id
	while seeds > 0:
		cursor = (cursor + 1) % PIT_COUNT
		if cursor == pit_id:
			continue
		pits[cursor] += 1
		seeds -= 1
	if _is_owned_pit(cursor, 1 - current_player) and pits[cursor] in [2, 3]:
		while _is_owned_pit(cursor, 1 - current_player) and pits[cursor] in [2, 3]:
			scores[current_player] += pits[cursor]
			pits[cursor] = 0
			cursor = (cursor - 1 + PIT_COUNT) % PIT_COUNT
	selected_pit = -1
	current_player = 1 - current_player
	message = "Player %d: choose a pit" % (current_player + 1)
	if not _has_seeds(current_player):
		if not _can_feed(current_player):
			game_over = true
			for i in PIT_COUNT:
				scores[0] += pits[i] if i >= 6 else 0
				scores[1] += pits[i] if i < 6 else 0
				pits[i] = 0
			message = "Player %d wins!" % (1 if scores[0] > scores[1] else 2 if scores[1] > scores[0] else 0)
	queue_redraw()

func _move_feeds_opponent(pit_id: int) -> bool:
	var seeds := pits[pit_id]
	var cursor := pit_id
	for _seed in seeds:
		cursor = (cursor + 1) % PIT_COUNT
		if _is_owned_pit(cursor, 1 - current_player):
			return true
	return false
