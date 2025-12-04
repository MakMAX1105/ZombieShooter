extends Node2D

@onready var zombie_dialog: AudioStreamPlayer = $"../ZombieDialog"


func _ready() -> void:
	$Timer.wait_time = 8.0
	$Timer.start()


func _on_timer_timeout() -> void:
	zombie_dialog.play()
