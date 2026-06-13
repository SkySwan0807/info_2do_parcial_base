extends TextureRect

@onready var score_label = $MarginContainer/HBoxContainer/score_label
@onready var counter_label = $MarginContainer/HBoxContainer/counter_label

var current_score = 0
var current_count = 0
var is_time_mode: bool   = false

# Conecta estos métodos a las señales del tablero (grid.gd), por ejemplo en _ready:
#   var grid = get_parent().get_node("grid")
#   grid.score_changed.connect(update_score)
#   grid.counter_changed.connect(update_counter)
func _ready():
	# Conectar señales del tablero automáticamente
	# Ajusta la ruta "../../grid" según tu árbol de escena
	var grid = _find_grid()
	if grid == null:
		push_warning("top_ui: no se encontró el nodo grid.")
		return

	grid.score_changed.connect(update_score)
	grid.counter_changed.connect(update_counter)
	grid.game_finished.connect(_on_game_finished)

	# Detectar modo tiempo según el LevelConfig del grid
	if grid.level_config != null and grid.level_config.limite_segundos > 0:
		is_time_mode = true

	# Mostrar valores iniciales
	update_score(0)
	if grid.level_config != null:
		if is_time_mode:
			update_counter(float(grid.level_config.limite_segundos))
		else:
			update_counter(grid.level_config.limite_movimientos)


func _find_grid() -> Node:
	# Sube al padre y busca el nodo llamado "grid".
	# Ajusta si tu jerarquía es diferente.
	var parent = get_parent()
	if parent and parent.has_node("grid"):
		return parent.get_node("grid")
	# Segundo intento: busca en todo el árbol por grupo
	var candidates = get_tree().get_nodes_in_group("grid")
	if candidates.size() > 0:
		return candidates[0]
	return null


func update_score(nuevo_puntaje: int) -> void:
	current_score = nuevo_puntaje
	
	# TODO (PARCIAL · B1): refleja current_score en score_label.text con el formato que prefieras.
	
	score_label.text = "%d" % current_score


func update_counter(restantes) -> void:
	current_count = restantes
	
	# TODO (PARCIAL · B2): refleja current_count en counter_label.text.
	
	
	if is_time_mode:
		# Formato MM:SS para el temporizador
		var secs  = int(restantes)
		var mins  = secs / 60
		secs      = secs % 60
		counter_label.text = "Tiempo: %02d:%02d" % [mins, secs]

		# Tinte rojo cuando quedan menos de 10 segundos
		if restantes <= 10:
			counter_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
		else:
			counter_label.remove_theme_color_override("font_color")
	else:
		counter_label.text = "Movimientos: %d" % int(restantes)

		# Tinte naranja cuando quedan 5 o menos movimientos
		if int(restantes) <= 5:
			counter_label.add_theme_color_override("font_color", Color(1, 0.5, 0.0))
		else:
			counter_label.remove_theme_color_override("font_color")


func _on_game_finished(gano: bool) -> void:
	# El grid ya llama a game_over_screen; aquí puedes hacer efectos extra en la UI.
	# Por ejemplo, congelar los labels con el puntaje final.
	if gano:
		score_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))
	else:
		score_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
