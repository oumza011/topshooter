extends CharacterBody2D

const SPEED := 280.0
const BULLET_SCENE := preload("res://scenes/bullet.tscn")

@export var fire_rate := 0.16

var _fire_cooldown := 0.0


func _ready() -> void:
	add_to_group("player")
	$Camera2D.make_current()


func _physics_process(delta: float) -> void:
	var move_direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = move_direction * SPEED
	move_and_slide()

	look_at(get_global_mouse_position())

	_fire_cooldown = maxf(_fire_cooldown - delta, 0.0)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and _fire_cooldown <= 0.0:
		_shoot()
		_fire_cooldown = fire_rate


func _shoot() -> void:
	var bullet := BULLET_SCENE.instantiate()
	bullet.global_position = global_position
	bullet.direction = (get_global_mouse_position() - global_position).normalized()
	get_tree().current_scene.add_child(bullet)

