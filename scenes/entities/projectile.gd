class_name Projectile
extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 400.0
var damage: float = 10.0

func _process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	queue_free()
