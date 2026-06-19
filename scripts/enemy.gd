extends CharacterBody2D

@export var speed := 120.0
@export var max_hp := 3

var hp := 3
var target: Node2D


func _ready() -> void:
	add_to_group("enemies")
	hp = max_hp
	_acquire_target()


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(target):
		_acquire_target()
		return

	var to_player := target.global_position - global_position
	if to_player.length() > 8.0:
		velocity = to_player.normalized() * speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO


func hit(damage: int) -> void:
	hp -= damage
	if hp <= 0:
		queue_free()


func _acquire_target() -> void:
	target = get_tree().get_first_node_in_group("player") as Node2D

