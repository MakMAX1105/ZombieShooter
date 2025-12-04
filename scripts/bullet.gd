extends Area2D

var speed: int = 5000
var knockback_force: int = 1200
var damage: int = 1
var direction: Vector2 = Vector2.RIGHT  # Default, will be overridden


func _ready() -> void:
	$Timer.start()
	print("DEBUG: Bullet direction on spawn: ", direction)


func _process(delta: float) -> void:
	position += direction * speed * delta


func _on_timer_timeout() -> void:
	queue_free()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("zombies"):
		queue_free()
		if body.has_method("take_damage"):
			body.take_damage(damage)
			
		
		if body.has_method("apply_knockback"):
			var knockback_direction: Vector2 = Vector2(cos(rotation), sin(rotation))
			body.apply_knockback(knockback_direction, knockback_force)


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
