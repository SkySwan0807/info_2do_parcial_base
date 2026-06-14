extends CanvasLayer
# ─────────────────────────────────────────────────────────────────────
# game_over_screen.gd
#
# NODO REQUERIDO en la escena:
#   GameOverScreen (CanvasLayer)  ← este script
#   └── Panel
#       ├── VBoxContainer
#       │   ├── title_label    (Label)
#       │   ├── score_label    (Label)
#       │   ├── record_label   (Label)
#       │   ├── restart_button (Button)  → señal "pressed" → _on_restart_pressed
#       │   └── next_button    (Button)  → señal "pressed" → _on_next_pressed
#
# Agrega este nodo al grupo "game_over_screen" desde el Inspector
# (pestaña Nodo → Grupos → "game_over_screen").
# ─────────────────────────────────────────────────────────────────────

@onready var title_label:    Label  = $Panel/VBoxContainer/title_label
@onready var score_label:    Label  = $Panel/VBoxContainer/score_label
@onready var record_label:   Label  = $Panel/VBoxContainer/record_label
@onready var restart_button: Button = $Panel/VBoxContainer/restart_button
@onready var next_button:    Button = $Panel/VBoxContainer/next_button

func _ready():
	hide()   # empieza oculto

# Llamado desde grid.gd → _mostrar_game_over_screen(gano, puntaje)
func show_result(gano: bool, puntaje: int) -> void:
	show()

	if gano:
		title_label.text = "¡VICTORIA! 🏆"
		title_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))
		next_button.visible = true
	else:
		title_label.text = "DERROTA 💀"
		title_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
		next_button.visible = false

	score_label.text = "Puntaje: %d" % puntaje

	# Mostrar récord guardado
	var grid = get_tree().get_first_node_in_group("grid")
	var record = 0
	if grid and grid.has_method("get_record"):
		record = grid.get_record()
	record_label.text = "Récord: %d" % record

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()

func _on_next_pressed() -> void:
	# grid.gd ya actualizó nivel_actual_idx antes de llamar show_result,
	# así que recargar la escena carga el siguiente nivel automáticamente.
	get_tree().reload_current_scene()
