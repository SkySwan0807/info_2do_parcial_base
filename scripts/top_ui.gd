extends TextureRect

@onready var score_label = $MarginContainer/HBoxContainer/score_label
@onready var counter_label = $MarginContainer/HBoxContainer/counter_label

var current_score = 0
var current_count = 0

# Conecta estos métodos a las señales del tablero (grid.gd), por ejemplo en _ready:
#   var grid = get_parent().get_node("grid")
#   grid.score_changed.connect(update_score)
#   grid.counter_changed.connect(update_counter)

func update_score(nuevo_puntaje: int) -> void:
	current_score = nuevo_puntaje
	# TODO (PARCIAL · B1): refleja current_score en score_label.text con el formato que prefieras.
	pass

func update_counter(restantes: int) -> void:
	current_count = restantes
	# TODO (PARCIAL · B2): refleja current_count en counter_label.text.
	pass
