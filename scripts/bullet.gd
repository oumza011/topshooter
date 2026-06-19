extends Area2D

@export var speed := 900.0
@export var direction := Vector2.RIGHT
@export var lifetime := 1.5

var _age := 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_age += delta
	if _age >= lifetime:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.has_method("hit"):
		body.hit(1)
		queue_free()

