class_name LevelConfig
extends Resource

enum Objetivo { PUNTAJE, RECOLECTAR_COLOR }

@export var nombre:           String  = "Nivel 1"
@export var objetivo_tipo:    Objetivo = Objetivo.PUNTAJE
@export var objetivo_valor:   int     = 1000        # puntos meta o cantidad a recolectar
@export var objetivo_color:   String  = "blue"      # solo si objetivo_tipo == RECOLECTAR_COLOR
@export var limite_movimientos: int   = 20           # 0 = sin límite de movimientos
@export var limite_segundos:  int     = 0            # 0 = sin límite de tiempo
@export var colores_disponibles: Array = [
	"blue", "green", "light_green", "pink", "yellow", "orange",
]

# ─────────────────────────────────────────────────────────────────────
# Configuraciones prediseñadas de los 3 niveles
# Úsalas en _ready() de grid.gd si no quieres crear archivos .tres:
#   niveles = [LevelConfig.nivel_1(), LevelConfig.nivel_2(), LevelConfig.nivel_3()]
# ─────────────────────────────────────────────────────────────────────
static func nivel_1() -> LevelConfig:
	var cfg = LevelConfig.new()
	cfg.nombre              = "Nivel 1 – Principiante"
	cfg.objetivo_tipo       = Objetivo.PUNTAJE
	cfg.objetivo_valor      = 1000
	cfg.limite_movimientos  = 10
	cfg.limite_segundos     = 0
	cfg.colores_disponibles = ["blue", "green", "light_green","pink", "yellow","orange",]
	return cfg

static func nivel_2() -> LevelConfig:
	var cfg = LevelConfig.new()
	cfg.nombre              = "Nivel 2 – Recolector"
	cfg.objetivo_tipo       = Objetivo.RECOLECTAR_COLOR
	cfg.objetivo_valor      = 70
	cfg.objetivo_color      = "blue"
	cfg.limite_movimientos  = 11
	cfg.limite_segundos     = 0
	cfg.colores_disponibles = ["blue", "green", "light_green", "pink", "yellow"]
	return cfg

static func nivel_3() -> LevelConfig:
	var cfg = LevelConfig.new()
	cfg.nombre              = "Nivel 3 – Contrarreloj"
	cfg.objetivo_tipo       = Objetivo.PUNTAJE
	cfg.objetivo_valor      = 1000
	cfg.limite_movimientos  = 6    # sin límite de movimientos
	cfg.limite_segundos     = 0    # 60 segundos
	cfg.colores_disponibles = ["blue", "green", "light_green", "pink", "yellow", "orange"]
	return cfg
