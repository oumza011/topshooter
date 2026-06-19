extends Node2D

@export var enemy_scene: PackedScene = preload("res://scenes/enemy.tscn")
@export var spawn_interval := 1.2
@export var spawn_radius := 700.0

var _spawn_timer := 0.0

@onready var player: Node2D = $Player


func _ready() -> void:
	randomize()


func _process(delta: float) -> void:
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_enemy()
		_spawn_timer = spawn_interval


func _spawn_enemy() -> void:
	if not is_instance_valid(player):
		return

	var enemy := enemy_scene.instantiate() as Node2D
	var angle := randf() * TAU
	var offset := Vector2(cos(angle), sin(angle)) * spawn_radius
	enemy.global_position = player.global_position + offset
	add_child(enemy)

