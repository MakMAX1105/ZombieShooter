extends CanvasLayer

@onready var health_label: Label = $VBoxContainer/HealthLabel
@onready var score_label: Label = $VBoxContainer/ScoreLabel
@onready var ammo_label: Label = $VBoxContainer/AmmoLabel

var score: int = 0


func _ready() -> void:
	update_health(100)
	update_score(0)
	
	if ammo_label:
		ammo_label.text = "🔫 Ammo: --/--"
	
	print("UI Ready - AmmoLabel: ", ammo_label != null)


func update_health(health: int) -> void:
	var health_text: String = "❤️ "
	
	for i in range(10):
		if i < health / 10:
			health_text += "♥"
		else:
			health_text += "♡"
	
	health_label.text = health_text + " " + str(health) + "%"


func update_score(new_score: int) -> void:
	score = new_score
	score_label.text = "⭐ Score: " + str(score)


func add_score(points: int) -> void:
	score += points
	update_score(score)


func update_ammo_display(current_ammo: int, max_ammo: int, is_reloading: bool = false) -> void:
	if not ammo_label:
		print("ERROR: ammo_label is null")
		return
	
	var display_text: String = str(current_ammo) + "/" + str(max_ammo)
	
	if is_reloading:
		display_text += " Reloading..."
	
	ammo_label.text = "🔫 Ammo: " + display_text
	print("UI Updated: ", display_text)
