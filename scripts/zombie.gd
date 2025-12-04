extends CharacterBody2D

# Stats
var speed: int = 100
var health: int = 50
var zombie_type: String = "zombie1"
var attack_cooldown: float = 1.0

# State
var player: Node = null
var is_dead: bool = false
var is_in_attack_range: bool = false
var is_playing_hurt: bool = false
var attack_timer: float = 0.0
var hurt_cooldown: float = 0.1

# Nodes
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var zombie_hit: AudioStreamPlayer = $ZombieHit
@onready var hitmarker: AudioStreamPlayer = $Hitmarker2
@onready var zombie_dying: AudioStreamPlayer = $ZombieDying


func _ready() -> void:
	add_to_group("zombies")
	
	var zombie_types: Array = ["zombie1", "zombie2"]
	zombie_type = zombie_types[randi() % zombie_types.size()]
	sprite.play(zombie_type + "_walk")
	
	var players: Array = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]


func _process(delta: float) -> void:
	if player and not is_dead:
		handle_movement()
	
	if is_in_attack_range and not is_dead:
		handle_attack(delta)


func handle_movement() -> void:
	var direction: Vector2 = (player.position - position).normalized()
	velocity = direction * speed
	move_and_slide()
	
	if abs(direction.x) > abs(direction.y):
		sprite.flip_h = direction.x < 0


func handle_attack(delta: float) -> void:
	attack_timer -= delta
	if attack_timer <= 0:
		attack()
		attack_timer = attack_cooldown


func take_damage(damage: int) -> void:
	if is_dead:
		return
	
	is_playing_hurt = true
	
	# Play hit sounds
	play_hit_sounds()
	
	# Visual feedback
	sprite.modulate = Color.RED
	var current_anim: String = sprite.animation
	sprite.play(zombie_type + "_hurt")
	
	await get_tree().create_timer(0.05).timeout
	sprite.modulate = Color.WHITE
	
	await get_tree().create_timer(0.15).timeout
	
	if not is_dead:
		sprite.play(current_anim)
	
	is_playing_hurt = false
	await get_tree().create_timer(hurt_cooldown).timeout
	
	health -= damage
	
	if health <= 0 and not is_dead:
		die()


func play_hit_sounds() -> void:
	var audio1: AudioStreamPlayer = hitmarker.duplicate()
	get_tree().current_scene.add_child(audio1)
	audio1.play()
	audio1.finished.connect(audio1.queue_free)
	
	var audio2: AudioStreamPlayer = zombie_hit.duplicate()
	get_tree().current_scene.add_child(audio2)
	audio2.play()
	audio2.finished.connect(audio2.queue_free)


func apply_knockback(direction: Vector2, force: float) -> void:
	if is_dead:
		return
	
	velocity = direction * force
	move_and_slide()
	velocity = Vector2.ZERO


func die() -> void:
	# Disable collisions
	$CollisionShape2D.disabled = true
	zombie_dying.play()
	is_dead = true
	
	
	if has_node("AttackRange"):
		$AttackRange/CollisionShape2D.disabled = true
	
	sprite.play(zombie_type + "_death")
	await sprite.animation_finished
	
	var ui: Node = get_node("/root/Main/UI")
	if ui and ui.has_method("add_score"):
		ui.add_score(10)
	
	queue_free()


func attack() -> void:
	if is_dead:
		return
	
	sprite.play(zombie_type + "_attack")
	await sprite.animation_finished
	
	if is_dead:
		return
	
	var players: Array = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		players[0].take_damage(10)
	
	sprite.play(zombie_type + "_walk")


func _on_attack_range_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		is_in_attack_range = true
		attack_timer = 0


func _on_attack_range_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		is_in_attack_range = false
