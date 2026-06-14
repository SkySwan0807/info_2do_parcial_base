extends Node2D

# state machine
enum {WAIT, MOVE}
var state

# grid
@export var width: int
@export var height: int
@export var x_start: int
@export var y_start: int
@export var offset: int
@export var y_offset: int

# Arrastra los .tres de niveles aquí en el Inspector (New Resource → LevelConfig).
@export var niveles: Array[LevelConfig] = [LevelConfig.nivel_1(),LevelConfig.nivel_2(), LevelConfig.nivel_3()]
var nivel_actual_idx: int = 0
var level_config: LevelConfig = null


# piece array
var possible_pieces = [
	preload("res://scenes/blue_piece.tscn"),
	preload("res://scenes/green_piece.tscn"),
	preload("res://scenes/light_green_piece.tscn"),
	#preload("res://scenes/pink_piece.tscn"),
	#preload("res://scenes/yellow_piece.tscn"),
	#preload("res://scenes/orange_piece.tscn"),
]

var all_possible_pieces = []
var all_pieces = []
var current_matches = []

var color_map = {
	"blue":        0,
	"green":       1,
	"light_green": 2,
	"pink":        3,
	"yellow":      4,
	"orange":      5,
}

# swap back
var piece_one = null
var piece_two = null
var last_place = Vector2.ZERO
var last_direction = Vector2.ZERO
var move_checked = false

# touch variables
var first_touch = Vector2.ZERO
var final_touch = Vector2.ZERO
var is_controlling = false

# ── Timers (deben existir como nodos hijos de "grid" en la escena) ──
@onready var destroy_timer:  Timer = $destroy_timer
@onready var collapse_timer: Timer = $collapse_timer
@onready var refill_timer:   Timer = $refill_timer
@onready var countdown_timer: Timer = $countdown_timer   # Modo tiempo

# ── Señales ──
signal score_changed(nuevo_puntaje: int)
signal counter_changed(restantes)       # int (movimientos) o float (segundos)
signal game_finished(gano: bool)
signal objetivo_actualizado(actual: int, meta: int)  # para el HUD de objetivos

# ── Estado de juego ──
var current_score: int  = 0
var moves_left:    int  = 0
var seconds_left:  float = 0.0
var game_active:   bool  = false

var collected: int = 0   # piezas del color objetivo eliminadas

# ─────────────────────────────────────────────────────────────────────
# READY
# ─────────────────────────────────────────────────────────────────────
func _ready():
	state = MOVE
	randomize()

	all_possible_pieces = possible_pieces.duplicate()
	all_pieces          = make_2d_array()

	# Cargar progreso guardado
	var datos = _leer_datos_guardados()
	nivel_actual_idx = datos.get("nivel_actual_idx", 0)
	nivel_actual_idx = clamp(nivel_actual_idx, 0, max(0, niveles.size() - 1))
	level_config = niveles[nivel_actual_idx] if niveles.size() > 0 else null
	
	_apply_level_config()
	spawn_pieces()
	game_active = true

# ─────────────────────────────────────────────────────────────────────
# CONFIGURACIÓN DEL NIVEL
# ─────────────────────────────────────────────────────────────────────
func _apply_level_config():
	# Restaurar lista completa antes de filtrar
	if all_possible_pieces.size() > 0:
		possible_pieces = all_possible_pieces.duplicate()

	if level_config == null:
		moves_left   = 20
		seconds_left = 0.0
		emit_signal("counter_changed", moves_left)
		return

	moves_left   = level_config.limite_movimientos
	seconds_left = float(level_config.limite_segundos)
	collected    = 0

	# Filtrar piezas disponibles según el nivel
	var available_indices: Array = []
	for color_name in level_config.colores_disponibles:
		if color_map.has(color_name):
			var idx = color_map[color_name]
			if idx < all_possible_pieces.size():
				available_indices.append(idx)
	if available_indices.size() > 0:
		var filtered = []
		for idx in available_indices:
			filtered.append(all_possible_pieces[idx])
		possible_pieces = filtered

	# Arrancar temporizador de cuenta regresiva si el nivel es por tiempo
	if seconds_left > 0:
		countdown_timer.wait_time = 1.0
		countdown_timer.start()
		emit_signal("counter_changed", seconds_left)
	elif moves_left > 0:
		emit_signal("counter_changed", moves_left)

	# Emitir estado inicial del objetivo
	emit_signal("objetivo_actualizado", 0, level_config.objetivo_valor)

# ─────────────────────────────────────────────────────────────────────
# GRID UTILITIES
# ─────────────────────────────────────────────────────────────────────
func make_2d_array():
	var array = []
	for i in width:
		array.append([])
		for j in height:
			array[i].append(null)
	return array

func grid_to_pixel(column, row):
	var new_x = x_start + offset * column
	var new_y = y_start - offset * row
	return Vector2(new_x, new_y)

func pixel_to_grid(pixel_x, pixel_y):
	var new_x = round((pixel_x - x_start) / offset)
	var new_y = round((pixel_y - y_start) / -offset)
	return Vector2(new_x, new_y)

func in_grid(column, row):
	return column >= 0 and column < width and row >= 0 and row < height

# ─────────────────────────────────────────────────────────────────────
# SPAWN
# ─────────────────────────────────────────────────────────────────────
func spawn_pieces():
	for i in width:
		for j in height:
			var rand = randi_range(0, possible_pieces.size() - 1)
			var piece = possible_pieces[rand].instantiate()
			var max_loops = 100
			var loops = 0
			while match_at(i, j, piece.color) and loops < max_loops:
				rand  = randi_range(0, possible_pieces.size() - 1)
				loops += 1
				piece = possible_pieces[rand].instantiate()
			add_child(piece)
			piece.position   = grid_to_pixel(i, j)
			all_pieces[i][j] = piece

func is_rainbow(piece_one, piece_two):
	if piece_one.color == "rainbow" or piece_two.color == "rainbow":
		return true
	return false

func match_at(i, j, color):
	if i > 1:
		if all_pieces[i - 1][j] != null and all_pieces[i - 2][j] != null:
			if all_pieces[i - 1][j].color == color and all_pieces[i - 2][j].color == color:
				return true
	if j > 1:
		if all_pieces[i][j - 1] != null and all_pieces[i][j - 2] != null:
			if all_pieces[i][j - 1].color == color and all_pieces[i][j - 2].color == color:
				return true
	return false

# ─────────────────────────────────────────────────────────────────────
# INPUT
# ─────────────────────────────────────────────────────────────────────
func touch_input():
	var mouse_pos = get_global_mouse_position()
	var grid_pos  = pixel_to_grid(mouse_pos.x, mouse_pos.y)

	if Input.is_action_just_pressed("ui_touch") and in_grid(grid_pos.x, grid_pos.y):
		first_touch   = grid_pos
		is_controlling = true

	if Input.is_action_just_released("ui_touch") and in_grid(grid_pos.x, grid_pos.y) and is_controlling:
		is_controlling = false
		final_touch    = grid_pos
		touch_difference(first_touch, final_touch)

func touch_difference(grid_1, grid_2):
	var difference = grid_2 - grid_1
	if abs(difference.x) > abs(difference.y):
		if difference.x > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(1,  0))
		elif difference.x < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(-1, 0))
	elif abs(difference.y) > abs(difference.x):
		if difference.y > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0,  1))
		elif difference.y < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0, -1))

func _process(_delta):
	if state == MOVE and game_active:
		touch_input()

# ─────────────────────────────────────────────────────────────────────
# SWAP
# ─────────────────────────────────────────────────────────────────────
func swap_pieces(column, row, direction: Vector2):
	var first_piece = all_pieces[column][row]
	var other_piece = all_pieces[column + int(direction.x)][row + int(direction.y)]
	if first_piece == null or other_piece == null:
		return
	# swap
	if is_rainbow(first_piece, other_piece):
		if first_piece.color == "rainbow" and other_piece.color == "rainbow":
			clear_board()
			_mark_matched(column, row)
			add_to_array(Vector2(column, row))
			_mark_matched(column + direction.x, row + direction.y)
			add_to_array(Vector2(column + direction.x, row + direction.y))
		elif first_piece.color == "rainbow" and other_piece.color != "rainbow":
			match_color(other_piece.color)
			_mark_matched(column, row)
			add_to_array(Vector2(column, row))
		elif other_piece.color == "rainbow" and first_piece.color != "rainbow":
			match_color(first_piece.color)
			_mark_matched(column + direction.x, row + direction.y)
			add_to_array(Vector2(column + direction.x, row + direction.y))
	state = WAIT
	store_info(first_piece, other_piece, Vector2(column, row), direction)

	all_pieces[column][row]                                         = other_piece
	all_pieces[column + int(direction.x)][row + int(direction.y)]  = first_piece

	first_piece.move(grid_to_pixel(column + int(direction.x), row + int(direction.y)))
	other_piece.move(grid_to_pixel(column, row))

	play_swap_sound()

	if not move_checked:
		find_matches()

func store_info(first_piece, other_piece, place, direction):
	piece_one       = first_piece
	piece_two       = other_piece
	last_place      = place
	last_direction  = direction

func swap_back():
	if piece_one != null and piece_two != null:
		swap_pieces(last_place.x, last_place.y, last_direction)
	state        = MOVE
	move_checked = false
	play_invalid_move_sound()

# ─────────────────────────────────────────────────────────────────────
# MATCH FINDING
# ─────────────────────────────────────────────────────────────────────
func find_matches():
	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
				continue
			var current_color = all_pieces[i][j].color

			# Horizontal
			if (i > 0 and i < width - 1
					and all_pieces[i - 1][j] != null and all_pieces[i + 1][j] != null
					and all_pieces[i - 1][j].color == current_color
					and all_pieces[i + 1][j].color == current_color):
				_mark_matched(i - 1, j)
				_mark_matched(i,     j)
				_mark_matched(i + 1, j)
				add_to_array(Vector2(i - 1, j))
				add_to_array(Vector2(i,     j))
				add_to_array(Vector2(i + 1, j))

			# Vertical
			if (j > 0 and j < height - 1
					and all_pieces[i][j - 1] != null and all_pieces[i][j + 1] != null
					and all_pieces[i][j - 1].color == current_color
					and all_pieces[i][j + 1].color == current_color):
				_mark_matched(i, j - 1)
				_mark_matched(i, j    )
				_mark_matched(i, j + 1)
				add_to_array(Vector2(i, j - 1))
				add_to_array(Vector2(i, j    ))
				add_to_array(Vector2(i, j + 1))

	get_bombed_pieces()
	destroy_timer.start()

func get_bombed_pieces():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and all_pieces[i][j].matched:
				if all_pieces[i][j].is_column:
					match_all_column(i)
				elif all_pieces[i][j].is_row:
					match_all_row(j)
				elif all_pieces[i][j].is_adjacent:
					match_all_adjecent(i, j)

func add_to_array(value, array_to_add = current_matches):
	if not array_to_add.has(value):
		array_to_add.append(value)

func _mark_matched(i, j):
	if all_pieces[i][j] != null and not all_pieces[i][j].matched:
		all_pieces[i][j].matched = true
		all_pieces[i][j].dim()

# ─────────────────────────────────────────────────────────────────────
# SPECIALS
# ─────────────────────────────────────────────────────────────────────
func find_specials():
	for i in current_matches.size():
		var current_column = current_matches[i].x
		var current_row    = current_matches[i].y
		if all_pieces[current_column][current_row] == null:
			continue
		var current_color = all_pieces[current_column][current_row].color
		var col_matched = 0
		var row_matched = 0

		for j in current_matches.size():
			var this_column = current_matches[j].x
			var this_row = current_matches[j].y
			var this_color = all_pieces[current_columm][current_row].color
			if (this_column== current_columm 
				and
				this_color == current_color):
					col_matched += 1
			if (this_row== current_row 
				and
				this_color == current_color):
					row_matched += 1
		if col_matched == 5 or row_matched == 5:
			make_specials(3, current_color)
		elif col_matched >= 3 and row_matched >= 3:
			make_specials(0, current_color)
			return
		elif col_matched == 4:
			make_specials(1, current_color)
			return
		elif row_matched == 4:
			make_specials(2, current_color)
			return

func make_specials(type, color):
	for i in current_matches.size():
		var current_column = current_matches[i].x
		var current_row    = current_matches[i].y
		if all_pieces[current_column][current_row] == piece_one and piece_one != null and piece_one.color == color:
			piece_one.matched = false
			change_to_special(type, piece_one)
		elif all_pieces[current_column][current_row] == piece_two and piece_two != null and piece_two.color == color:
			change_to_special(type, piece_two)

func change_to_special(type, piece):
	if   type == 0: piece.make_adjacent()
	elif type == 1: piece.make_row()
	elif type == 2: piece.make_column()

func match_all_column(column):
	for i in height:
		if all_pieces[column][i] != null:
			if all_pieces[column][i].is_row:
				match_all_row(i)
			if all_pieces[column][i].is_adjacent:
				match_all_adjecent(column, i)
			all_pieces[column][i].matched = true

func match_all_row(row):
	for j in width:
		if all_pieces[j][row] != null:
			if all_pieces[j][row].is_column:
				match_all_column(j)
			if all_pieces[j][row].is_adjacent:
				match_all_adjecent(j, row)
			all_pieces[j][row].matched = true

func match_all_adjecent(column, row):
	for i in range(-1, 2):
		for j in range(-1, 2):
			var ci = column + i
			var rj = row + j
			if in_grid(ci, rj) and all_pieces[ci][rj] != null:
				if all_pieces[ci][rj].is_column:
					match_all_column(ci)
				elif all_pieces[ci][rj].is_row:
					match_all_row(rj)
				all_pieces[ci][rj].matched = true

# ─────────────────────────────────────────────────────────────────────
# DESTROY
# ─────────────────────────────────────────────────────────────────────
func destroy_matched():
	find_specials()
	var was_matched       = false
	var pieces_destroyed  = 0

	for i in width:
		for j in height:
			if all_pieces[i][j] != null and all_pieces[i][j].matched:
				was_matched       = true
				pieces_destroyed += 1

				# Recolección por color objetivo
				if level_config != null and level_config.objetivo_tipo == LevelConfig.Objetivo.RECOLECTAR_COLOR:
					if all_pieces[i][j].color == level_config.objetivo_color:
						collected += 1
						emit_signal("objetivo_actualizado", collected, level_config.objetivo_valor)

				all_pieces[i][j].queue_free()
				all_pieces[i][j] = null

	current_matches.clear()

	if pieces_destroyed > 0:
		_add_score(pieces_destroyed)
		if pieces_destroyed >= 4:
			play_big_match_sound()

	move_checked = true

	if was_matched:
		# Consumir movimiento solo cuando hubo combinación real
		_use_move()
		collapse_timer.start()
	else:
		swap_back()

# ─────────────────────────────────────────────────────────────────────
# COLLAPSE / REFILL
# ─────────────────────────────────────────────────────────────────────
func collapse_columns():
	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
				for k in range(j + 1, height):
					if all_pieces[i][k] != null:
						all_pieces[i][k].move(grid_to_pixel(i, j))
						all_pieces[i][j] = all_pieces[i][k]
						all_pieces[i][k] = null
						break
	refill_timer.start()

func refill_columns():
	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
				var rand   = randi_range(0, possible_pieces.size() - 1)
				var piece  = possible_pieces[rand].instantiate()
				var max_loops = 100
				var loops     = 0
				while match_at(i, j, piece.color) and loops < max_loops:
					rand  = randi_range(0, possible_pieces.size() - 1)
					loops += 1
					piece = possible_pieces[rand].instantiate()
				add_child(piece)
				piece.position   = grid_to_pixel(i, j - y_offset)
				piece.move(grid_to_pixel(i, j))
				all_pieces[i][j] = piece
	check_after_refill()

func check_after_refill():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and match_at(i, j, all_pieces[i][j].color):
				find_matches()
				destroy_timer.start()
				return

	# Tablero estable
	_check_win()
	if game_active and not hay_jugadas_validas():
		rebarajar()
	state        = MOVE
	move_checked = false

# ─────────────────────────────────────────────────────────────────────
# SCORE
# ─────────────────────────────────────────────────────────────────────
func _add_score(pieces: int):
	var bonus = 1 + max(0, pieces - 3) * 0.5
	current_score += int(50 * pieces * bonus)
	emit_signal("score_changed", current_score)

	# Actualizar progreso de objetivo de puntaje
	if level_config != null and level_config.objetivo_tipo == LevelConfig.Objetivo.PUNTAJE:
		emit_signal("objetivo_actualizado", current_score, level_config.objetivo_valor)

	_check_win()

# ─────────────────────────────────────────────────────────────────────
# MOVES / TIMER
# ─────────────────────────────────────────────────────────────────────
func _use_move():
	# Si el nivel usa tiempo en vez de movimientos, no descontar
	if level_config != null and level_config.limite_segundos > 0:
		return

	if level_config == null or level_config.limite_movimientos == 0:
		return   # sin límite de movimientos

	moves_left -= 1
	emit_signal("counter_changed", moves_left)

	if moves_left <= 0:
		_check_win()
		if game_active:
			game_over()

func _on_countdown_timer_timeout():
	if not game_active:
		return
	seconds_left = max(0.0, seconds_left - 1.0)
	emit_signal("counter_changed", seconds_left)
	if seconds_left <= 0:
		_check_win()
		if game_active:
			game_over()

# ─────────────────────────────────────────────────────────────────────
# WIN / LOSE
# ─────────────────────────────────────────────────────────────────────
func _check_win():
	if not game_active or level_config == null:
		return

	var gano = false
	match level_config.objetivo_tipo:
		LevelConfig.Objetivo.PUNTAJE:
			if current_score >= level_config.objetivo_valor:
				gano = true
		LevelConfig.Objetivo.RECOLECTAR_COLOR:
			if collected >= level_config.objetivo_valor:
				gano = true

	if gano:
		game_active = false
		countdown_timer.stop()
		_guardar_progreso(nivel_actual_idx + 1)
		emit_signal("game_finished", true)
		_mostrar_game_over_screen(true)
		
func _mostrar_game_over_screen(gano: bool):
	print("Buscando game_over_screen...")
	var screen = get_tree().get_first_node_in_group("game_over_screen")
	print("Screen encontrado: ", screen)
	if screen:
		print("Llamando show_result con gano=", gano)
		screen.show_result(gano, current_score)
	else:
		push_warning("grid.gd: no se encontró ningún nodo en el grupo 'game_over_screen'.")

func game_over():
	if not game_active:
		return
	game_active = false
	state       = WAIT
	countdown_timer.stop()
	_guardar_record()
	emit_signal("game_finished", true)
	_mostrar_game_over_screen(false)


# ─────────────────────────────────────────────────────────────────────
# JUGADAS VÁLIDAS / REBARAJE
# ─────────────────────────────────────────────────────────────────────
func hay_jugadas_validas() -> bool:
	var directions = [Vector2(1, 0), Vector2(0, 1)]
	for i in width:
		for j in height:
			for dir in directions:
				var ni = i + int(dir.x)
				var nj = j + int(dir.y)
				if not in_grid(ni, nj):
					continue
				if all_pieces[i][j] == null or all_pieces[ni][nj] == null:
					continue
				# Intercambio temporal
				var tmp            = all_pieces[i][j]
				all_pieces[i][j]   = all_pieces[ni][nj]
				all_pieces[ni][nj] = tmp

				var genera = _simulacion_genera_match(i, j) or _simulacion_genera_match(ni, nj)

				# Revertir
				tmp                = all_pieces[i][j]
				all_pieces[i][j]   = all_pieces[ni][nj]
				all_pieces[ni][nj] = tmp

				if genera:
					return true
	return false

func _simulacion_genera_match(i, j) -> bool:
	if all_pieces[i][j] == null:
		return false
	var c = all_pieces[i][j].color

	var h = 1
	var k = i - 1
	while k >= 0 and all_pieces[k][j] != null and all_pieces[k][j].color == c:
		h += 1; k -= 1
	k = i + 1
	while k < width and all_pieces[k][j] != null and all_pieces[k][j].color == c:
		h += 1; k += 1
	if h >= 3: return true

	var v = 1
	k = j - 1
	while k >= 0 and all_pieces[i][k] != null and all_pieces[i][k].color == c:
		v += 1; k -= 1
	k = j + 1
	while k < height and all_pieces[i][k] != null and all_pieces[i][k].color == c:
		v += 1; k += 1
	if v >= 3: return true

	return false

func rebarajar():
	var piezas_planas = []
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				piezas_planas.append(all_pieces[i][j])

	piezas_planas.shuffle()
	var idx = 0
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				all_pieces[i][j] = piezas_planas[idx]
				all_pieces[i][j].move(grid_to_pixel(i, j))
				idx += 1

	var intentos = 0
	while not hay_jugadas_validas() and intentos < 10:
		piezas_planas.shuffle()
		idx = 0
		for i in width:
			for j in height:
				if all_pieces[i][j] != null:
					all_pieces[i][j] = piezas_planas[idx]
					all_pieces[i][j].move(grid_to_pixel(i, j))
					idx += 1
		intentos += 1

func make_specials(type, color):
	for i in current_matches.size():
		var current_column = current_matches[i].x
		var current_row = current_matches[i].y
		if all_pieces[current_column][current_row] == piece_one and piece_one.color == color:
			piece_one.matched = false
			change_to_special(type, piece_one)
		if all_pieces[current_column][current_row] == piece_two and piece_two.color == color:
			change_to_special(type, piece_two)

func change_to_special(type, piece):
	if type == 0:
		piece.make_adjacent()
	elif type == 1:
		piece.make_row()
	elif type == 2:
		piece.make_column()
	elif type == 3:
		piece.make_rainbow()

func match_all_column(column):
	for i in height:
		if all_pieces[column][i] != null:
			if all_pieces[column][i].is_row:
				match_all_row(i)
			if all_pieces[column][i].is_adjacent:
				match_all_adjecent(column, i)
			_mark_matched(column, i)
			add_to_array(Vector2(column, i))

func match_all_row(row):
	for j in width:
		if all_pieces[j][row] != null:
			if all_pieces[j][row].is_column:
				match_all_column(j)
			if all_pieces[j][row].is_adjacent:
				match_all_adjecent(j, row)
			_mark_matched(j, row)
			add_to_array(Vector2(j, row))

func is_in_grid(grid_position):
	if(grid_position.x >= 0 and grid_position.x < width):
		if(grid_position.y >= 0 and grid_position.y < height):
			return true
	return false

func match_all_adjecent(column, row):
	for i in range(-1, 2):
		for j in range(-1, 2):
			if (is_in_grid(Vector2((column + i), (row + j)))
				and all_pieces[column + i][row + j] != null):
				if all_pieces[i][j].is_column:
					match_all_column(i)
				if all_pieces[i][j].is_column:
					match_all_column(j)
				_mark_matched(column + i, row + j)

func match_color(color):
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and all_pieces[i][j].color == color:
				_mark_matched(i, j)
				add_to_array(Vector2(i,j))
				
func clear_board():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				_mark_matched(i, j)
				add_to_array(Vector2(i,j))

# ─────────────────────────────────────────────────────────────────────
# SONIDOS (nodos hijos de la escena raíz)
# ─────────────────────────────────────────────────────────────────────
func play_invalid_move_sound():
	var node = get_node_or_null("../InvalidMoveSound")
	if node: node.play()

func play_swap_sound():
	var node = get_node_or_null("../SwapSound")
	if node: node.play()

func play_big_match_sound():
	var node = get_node_or_null("../BigMatchSound")
	if node: node.play()

# ─────────────────────────────────────────────────────────────────────
# TIMER CALLBACKS
# ─────────────────────────────────────────────────────────────────────
func _on_destroy_timer_timeout():
	destroy_matched()

func _on_collapse_timer_timeout():
	collapse_columns()

func _on_refill_timer_timeout():
	refill_columns()

# ─────────────────────────────────────────────────────────────────────
# PERSISTENCIA
# ─────────────────────────────────────────────────────────────────────
const RUTA_GUARDADO = "user://save.json"

func _leer_datos_guardados() -> Dictionary:
	if not FileAccess.file_exists(RUTA_GUARDADO):
		return {"record_puntaje": 0, "nivel_actual_idx": 0}
	var file = FileAccess.open(RUTA_GUARDADO, FileAccess.READ)
	if file == null:
		return {"record_puntaje": 0, "nivel_actual_idx": 0}
	var resultado = JSON.parse_string(file.get_as_text())
	file.close()
	if resultado == null or not resultado is Dictionary:
		return {"record_puntaje": 0, "nivel_actual_idx": 0}
	return {"record_puntaje": 0, "nivel_actual_idx": 0}

func _guardar_record() -> void:
	var datos = _leer_datos_guardados()
	if current_score > datos.get("record_puntaje", 0):
		datos["record_puntaje"] = current_score
	var file = FileAccess.open(RUTA_GUARDADO, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(datos))
		file.close()

func _guardar_progreso(siguiente_idx: int) -> void:
	var datos = _leer_datos_guardados()
	datos["nivel_actual_idx"] = siguiente_idx
	if current_score > datos.get("record_puntaje", 0):
		datos["record_puntaje"] = current_score
	var file = FileAccess.open(RUTA_GUARDADO, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(datos))
		file.close()

func get_record() -> int:
	return _leer_datos_guardados().get("record_puntaje", 0)