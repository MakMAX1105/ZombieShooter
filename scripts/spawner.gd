extends Node2D

var zombie_scene: Resource = preload("res://scenes/zombies/zombie.tscn")
var fast_zombie_scene: Resource = preload("res://scenes/zombies/fast_zombie.tscn")
@onready var fast_zombie_dia: AudioStreamPlayer = $"../FastZombieDia"


func _ready() -> void:
	$Timer.wait_time = 3.0
	$Timer.start()


func _on_timer_timeout() -> void:
	spawn_zombie()


func spawn_zombie() -> void:
	var zombie: Node
	
	# Choose random zombie type
	if randf() < 0.4:
		zombie = fast_zombie_scene.instantiate()
		fast_zombie_dia.play()
	else:
		zombie = zombie_scene.instantiate()
	
	var players: Array = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player: Node = players[0]
		var angle: float = randf() * TAU
		var distance: int = 700
		zombie.position = player.position + Vector2(cos(angle), sin(angle)) * distance
	
	get_parent().add_child(zombie)
