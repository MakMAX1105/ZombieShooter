extends "res://scripts/zombie.gd"


func _ready() -> void:
	super._ready()
	
	# Override stats for fast zombie
	speed = 225
	attack_cooldown = 0.4
	health = 100


func die() -> void:
	is_dead = true
	sprite.play(zombie_type + "_death")
	zombie_dying.play()
	await sprite.animation_finished
	
	var ui: Node = get_node("/root/Main/UI")
	if ui and ui.has_method("add_score"):
		ui.add_score(25)
	
	queue_free()
