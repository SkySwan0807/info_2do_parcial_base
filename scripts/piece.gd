extends Node2D

@export var color: String

var matched = false

# TODO (PARCIAL · M3): para las piezas especiales podrías guardar aquí su tipo
# (por ejemplo, "fila", "columna" o "bomba") y exponer un método que dispare su
# efecto sobre el tablero cuando se active.

@onready var sprite = $Sprite2D

enum SpecialType {
	NONE,
	ROW,
	COLUMN,
	ADJACENT,
	RAINBOW
}

var textures = {
	"light_green": {
		SpecialType.NONE: preload("res://assets/pieces/Light Green Piece.png"),
		SpecialType.ROW: preload("res://assets/pieces/Light Green Row.png"),
		SpecialType.COLUMN: preload("res://assets/pieces/Light Green Column.png"),
		SpecialType.ADJACENT: preload("res://assets/pieces/Light Green Adjacent.png"),
	},

	"blue": {
		SpecialType.NONE: preload("res://assets/pieces/Blue Piece.png"),
		SpecialType.ROW: preload("res://assets/pieces/Blue Row.png"),
		SpecialType.COLUMN: preload("res://assets/pieces/Blue Column.png"),
		SpecialType.ADJACENT: preload("res://assets/pieces/Blue Adjacent.png"),
	},

	"green": {
		SpecialType.NONE: preload("res://assets/pieces/Green Piece.png"),
		SpecialType.ROW: preload("res://assets/pieces/Green Row.png"),
		SpecialType.COLUMN: preload("res://assets/pieces/Green Column.png"),
		SpecialType.ADJACENT: preload("res://assets/pieces/Green Adjacent.png"),
	},

	"yellow": {
		SpecialType.NONE: preload("res://assets/pieces/Yellow Piece.png"),
		SpecialType.ROW: preload("res://assets/pieces/Yellow Row.png"),
		SpecialType.COLUMN: preload("res://assets/pieces/Yellow Column.png"),
		SpecialType.ADJACENT: preload("res://assets/pieces/Yellow Adjacent.png"),
	},

	"pink": {
		SpecialType.NONE: preload("res://assets/pieces/Pink Piece.png"),
		SpecialType.ROW: preload("res://assets/pieces/Pink Row.png"),
		SpecialType.COLUMN: preload("res://assets/pieces/Pink Column.png"),
		SpecialType.ADJACENT: preload("res://assets/pieces/Pink Adjacent.png"),
	},

	"orange": {
		SpecialType.NONE: preload("res://assets/pieces/Orange Piece.png"),
		SpecialType.ROW: preload("res://assets/pieces/Orange Row.png"),
		SpecialType.COLUMN: preload("res://assets/pieces/Orange Column.png"),
		SpecialType.ADJACENT: preload("res://assets/pieces/Orange Adjacent.png"),
	},
	
	"rainbow": {
		SpecialType.RAINBOW: preload("res://assets/pieces/Rainbow.png"),
	}
}

var special_type = SpecialType.NONE

func move(target):
	var move_tween = create_tween()
	move_tween.set_trans(Tween.TRANS_ELASTIC)
	move_tween.set_ease(Tween.EASE_OUT)
	move_tween.tween_property(self, "position", target, 0.4)

func dim():
	$Sprite2D.modulate = Color(1, 1, 1, 0.5)

func undim() -> void:
	$Sprite2D.modulate = Color(1, 1, 1, 1.0)

func _ready():
	update_sprite()

func set_special_type(type: SpecialType):
	special_type = type
	if type == SpecialType.RAINBOW:
		set_color("rainbow")
	update_sprite()

func update_sprite():
	if textures.has(color):
		sprite.texture = textures[color][special_type]

func set_color(new_color: String):
	color = new_color
	

	
