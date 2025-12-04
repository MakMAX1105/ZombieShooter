extends CharacterBody2D

# Movement
var speed: int = 300
var health: int = 100

# Weapon system
var weapons: Array = ["pistol", "shotgun", "rifle"]
var current_weapon_index: int = 0
var current_gun: Node = null
var is_reloading: bool = false

# Shooting
var can_shoot: bool = true
var fire_timer: float = 0.0

# Reload times
var reload_times: Dictionary = {
	"pistol": 3,
	"shotgun": 3,
	"rifle": 3
}

# Weapon stats
var weapon_stats: Dictionary = {
	"pistol": {
		"fire_rate": 0.5,
		"bullet_speed": 5000,
		"knockback": 1200,
		"bullet_count": 1,
		"spread": 0.0,
		"damage": 45
	},
	"shotgun": {
		"fire_rate": 1.0,
		"bullet_speed": 4000,
		"knockback": 800,
		"bullet_count": 5,
		"spread": 0.1,
		"damage": 120
	},
	"rifle": {
		"fire_rate": 0.1,
		"bullet_speed": 6000,
		"knockback": 600,
		"bullet_count": 1,
		"spread": 0.0,
		"damage": 39
	}
}

# Ammo system
var ammo: Dictionary = {
	"pistol": 9999999,
	"shotgun": 8,
	"rifle": 45
}
var max_ammo: Dictionary = {
	"pistol": 9999999,
	"shotgun": 8,
	"rifle": 45
}

# Audio
@onready var weapon_holder: Node2D = $WeaponHolder
@onready var reload_sound: AudioStreamPlayer2D = $ReloadSound

var shoot_sounds: Dictionary = {}
var switch_sounds: Dictionary = {}
var reload_sounds: Dictionary = {
	"pistol": preload("res://assets/sounds/clean-revolver-reload-6889.ogg"),
	"shotgun": preload("res://assets/sounds/shotgun-reload-sfx-36524.mp3"),
	"rifle": preload("res://assets/sounds/m4a1-or-m16-reload-sound-84436.ogg")
}


func _ready() -> void:
	add_to_group("player")
	
	# Load shoot sounds
	shoot_sounds["pistol"] = load("res://assets/sounds/single-pistol-gunshot-33-37187.mp3")
	shoot_sounds["shotgun"] = load("res://assets/sounds/doom-shotgun-2017-80549.mp3")
	shoot_sounds["rifle"] = load("res://assets/sounds/ak47_firing.mp3")
	
	# Load switch sounds
	switch_sounds["pistol"] = load("res://assets/sounds/pistol-cock-6014.mp3")
	switch_sounds["shotgun"] = load("res://assets/sounds/realistic-shotgun-cocking-sound-38640.mp3")
	switch_sounds["rifle"] = load("res://assets/sounds/cocking-m16-90729.mp3")
	
	await get_tree().process_frame
	switch_weapon(weapons[current_weapon_index])


func _physics_process(delta: float) -> void:
	handle_movement()
	handle_aim()
	handle_input(delta)
	handle_fire_rate(delta)


func handle_movement() -> void:
	var input: Vector2 = Input.get_vector("left", "right", "up", "down")
	velocity = input * speed
	move_and_slide()


func handle_aim() -> void:
	var mouse_pos: Vector2 = get_global_mouse_position()
	weapon_holder.look_at(mouse_pos)
	
	# Flip player based on aim direction
	if weapon_holder.rotation_degrees > -90 and weapon_holder.rotation_degrees < 90:
		scale.x = 1
	else:
		scale.x = -1


func handle_input(_delta: float) -> void:
	# Reload
	if Input.is_action_just_pressed("reload") and not is_reloading:
		start_reload()
	
	# Shooting
	if Input.is_action_pressed("shoot") and can_shoot and ammo[weapons[current_weapon_index]] > 0:
		shoot()
		can_shoot = false
		fire_timer = weapon_stats[weapons[current_weapon_index]].fire_rate
	elif Input.is_action_pressed("shoot") and ammo[weapons[current_weapon_index]] <= 0:
		print("Out of ammo!")
	
	# Weapon switching
	if Input.is_action_just_pressed("weapon_1"):
		switch_weapon("pistol")
	if Input.is_action_just_pressed("weapon_2"):
		switch_weapon("shotgun")
	if Input.is_action_just_pressed("weapon_3"):
		switch_weapon("rifle")
	
	# Scroll wheel switching
	if Input.is_action_just_pressed("scroll_up"):
		current_weapon_index = wrapi(current_weapon_index - 1, 0, weapons.size())
		switch_weapon(weapons[current_weapon_index])
	if Input.is_action_just_pressed("scroll_down"):
		current_weapon_index = wrapi(current_weapon_index + 1, 0, weapons.size())
		switch_weapon(weapons[current_weapon_index])


func handle_fire_rate(delta: float) -> void:
	if not can_shoot:
		fire_timer -= delta
		if fire_timer <= 0:
			can_shoot = true


func shoot() -> void:
	# Can't shoot while reloading
	if is_reloading or not current_gun:
		return
	
	var bullet_spawn: Node2D = current_gun.get_node("BulletSpawn")
	if not bullet_spawn:
		return
	
	var current_weapon_name: String = weapons[current_weapon_index]
	var stats: Dictionary = weapon_stats[current_weapon_name]
	
	# Check ammo
	if ammo[current_weapon_name] <= 0:
		start_reload()
		return
	
	# Shoot bullets
	for i in range(stats.bullet_count):
		var bullet: Node = preload("res://scenes/bullet.tscn").instantiate()
		bullet.position = bullet_spawn.global_position
		
		var mouse_pos: Vector2 = get_global_mouse_position()
		var shoot_direction: Vector2 = (mouse_pos - bullet_spawn.global_position).normalized()
		
		# Apply spread for shotgun
		if stats.spread > 0:
			var angle_offset: float = randf_range(-stats.spread, stats.spread)
			shoot_direction = shoot_direction.rotated(angle_offset)
		
		bullet.direction = shoot_direction
		bullet.rotation = shoot_direction.angle()
		bullet.speed = stats.bullet_speed
		bullet.knockback_force = stats.knockback
		bullet.damage = stats.damage
		
		get_tree().current_scene.add_child(bullet)
	
	# Reduce ammo
	ammo[current_weapon_name] -= 1
	
	if ammo[current_weapon_name] <= 0:
		start_reload()
	
	play_shoot_sound(current_weapon_name)
	update_ammo_ui()


func play_shoot_sound(weapon_name: String) -> void:
	if shoot_sounds.has(weapon_name) and shoot_sounds[weapon_name]:
		var audio: AudioStreamPlayer = AudioStreamPlayer.new()
		audio.stream = shoot_sounds[weapon_name]
		audio.pitch_scale = randf_range(0.9, 1.1)
		
		get_tree().current_scene.add_child(audio)
		audio.play()
		audio.finished.connect(audio.queue_free)
	else:
		$Ak47Firing.play()


func switch_weapon(weapon_name: String) -> void:
	play_switch_sound(weapon_name)
	
	if not weapons.has(weapon_name):
		return
	
	# Cancel reload if in progress
	if is_reloading:
		print("Cancelled reload to switch weapon")
		is_reloading = false
		reload_sound.stop()
	
	# Remove old gun
	for child in weapon_holder.get_children():
		child.queue_free()
	
	# Load new gun
	var gun_path: String = "res://scenes/weapons/" + weapon_name + ".tscn"
	var gun_scene: Resource = load(gun_path)
	current_gun = gun_scene.instantiate()
	weapon_holder.add_child(current_gun)
	
	current_weapon_index = weapons.find(weapon_name)
	print("Switched to: ", weapon_name, " | Ammo: ", ammo[weapon_name])
	
	update_ammo_ui()


func play_switch_sound(weapon_name: String) -> void:
	if switch_sounds.has(weapon_name) and switch_sounds[weapon_name]:
		var audio: AudioStreamPlayer = AudioStreamPlayer.new()
		audio.stream = switch_sounds[weapon_name]
		audio.pitch_scale = randf_range(0.9, 1.1)
		
		get_tree().current_scene.add_child(audio)
		audio.play()
		audio.finished.connect(audio.queue_free)


func start_reload() -> void:
	var current_weapon_name: String = weapons[current_weapon_index]
	
	# Don't reload if already full or already reloading
	if ammo[current_weapon_name] >= max_ammo[current_weapon_name] or is_reloading:
		return
	
	is_reloading = true
	print("Reloading ", current_weapon_name, "...")
	
	if reload_sounds.has(current_weapon_name):
		reload_sound.stream = reload_sounds[current_weapon_name]
		reload_sound.play()
	
	await get_tree().create_timer(reload_times[current_weapon_name]).timeout
	
	ammo[current_weapon_name] = max_ammo[current_weapon_name]
	is_reloading = false
	
	print("Reload complete! Ammo: ", ammo[current_weapon_name])
	update_ammo_ui()


func update_ammo_ui() -> void:
	var ui: Node = get_node("/root/Main/UI")
	if ui and ui.has_method("update_ammo_display"):
		var weapon_name: String = weapons[current_weapon_index]
		ui.update_ammo_display(ammo[weapon_name], max_ammo[weapon_name], is_reloading)


func take_damage(amount: int) -> void:
	health -= amount
	var ui: Node = get_node("/root/Main/UI")
	if ui:
		ui.update_health(health)
	
	if health <= 0:
		die()


func die() -> void:
	print("GAME OVER")
	get_tree().reload_current_scene()
