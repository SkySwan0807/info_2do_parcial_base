extends TextureRect

# ── Referencias a etiquetas del HUD ──────────────────────────────────
# Asegúrate de que estos nodos existan dentro de tu TextureRect (top_ui).
# Estructura esperada:
#   top_ui (TextureRect)
#   └── MarginContainer
#       └── HBoxContainer
#           ├── score_label    (Label)
#           ├── counter_label  (Label)
#           └── objetivo_label (Label)
@onready var score_label:    Label = $MarginContainer/HBoxContainer/score_label
@onready var counter_label:  Label = $MarginContainer/HBoxContainer/counter_label
@onready var objetivo_label: Label = $MarginContainer/HBoxContainer/objetivo_label

var current_score: int   = 0
var current_count        = 0
var is_time_mode:  bool  = false

# ─────────────────────────────────────────────────────────────────────
func _ready():
	var grid = _find_grid()
	if grid == null:
		push_warning("top_ui: no se encontró el nodo grid.")
		return

	# Conectar señales
	grid.score_changed.connect(update_score)
	grid.counter_changed.connect(update_counter)
	grid.game_finished.connect(_on_game_finished)
	grid.objetivo_actualizado.connect(_on_objetivo_actualizado)

	# Determinar modo tiempo
	if grid.level_config != null and grid.level_config.limite_segundos > 0:
		is_time_mode = true

	# Valores iniciales
	update_score(0)
	if grid.level_config != null:
		if is_time_mode:
			update_counter(float(grid.level_config.limite_segundos))
		else:
			update_counter(grid.level_config.limite_movimientos)
		_update_objetivo_label(grid.level_config)
	else:
		update_counter(20)
		if objetivo_label:
			objetivo_label.text = "Objetivo: libre"

	# Música de fondo
	var music = get_node_or_null("../MusicSound")
	if music:
		music.play()

# ─────────────────────────────────────────────────────────────────────
func _find_grid() -> Node:
	var parent = get_parent()
	if parent and parent.has_node("grid"):
		return parent.get_node("grid")
	var candidates = get_tree().get_nodes_in_group("grid")
	if candidates.size() > 0:
		return candidates[0]
	return null

# ─────────────────────────────────────────────────────────────────────
# SCORE
# ─────────────────────────────────────────────────────────────────────
func update_score(nuevo_puntaje: int) -> void:
	current_score = nuevo_puntaje
	if score_label:
		score_label.text = "Pts: %d" % current_score

# ─────────────────────────────────────────────────────────────────────
# COUNTER (movimientos o tiempo)
# ─────────────────────────────────────────────────────────────────────
func update_counter(restantes) -> void:
	current_count = restantes
	if counter_label == null:
		return

	if is_time_mode:
		var secs = int(restantes)
		var mins = secs / 60
		secs     = secs % 60
		counter_label.text = "%02d:%02d" % [mins, secs]
		if restantes <= 10:
			counter_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
		else:
			counter_label.remove_theme_color_override("font_color")
	else:
		counter_label.text = "%d" % int(restantes)
		if int(restantes) <= 5:
			counter_label.add_theme_color_override("font_color", Color(1, 0.5, 0.0))
		else:
			counter_label.remove_theme_color_override("font_color")

func _update_objetivo_label(lc: LevelConfig) -> void:
	if objetivo_label == null:
		return
	match lc.objetivo_tipo:
		LevelConfig.Objetivo.PUNTAJE:
			objetivo_label.text = "Meta: %d pts" % lc.objetivo_valor
		LevelConfig.Objetivo.RECOLECTAR_COLOR:
			objetivo_label.text = "Recolectar: 0/%d %s" % [lc.objetivo_valor, lc.objetivo_color]

func _on_objetivo_actualizado(actual: int, meta: int) -> void:
	if objetivo_label == null:
		return
	var grid = _find_grid()
	if grid == null or grid.level_config == null:
		return
	match grid.level_config.objetivo_tipo:
		LevelConfig.Objetivo.PUNTAJE:
			objetivo_label.text = "Meta: %d/%d pts" % [actual, meta]
		LevelConfig.Objetivo.RECOLECTAR_COLOR:
			objetivo_label.text = "Recolectar: %d/%d %s" % [actual, meta, grid.level_config.objetivo_color]

func _on_game_finished(gano: bool) -> void:
	if score_label == null:
		return
	if gano:
		score_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))
	else:
		score_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
