extends Control

@onready var btn_start: Button = $VBoxContainer/BtnStart
@onready var btn_sound: Button = $VBoxContainer/BtnSound
@onready var zeca_sprite: Sprite2D = $ZecaSprite
@onready var faisca_sprite: Sprite2D = $FaiscaSprite

var time_passed: float = 0.0

func _ready() -> void:
	btn_start.pressed.connect(_on_start_pressed)
	btn_sound.pressed.connect(_on_sound_pressed)
	update_sound_button()
	btn_start.grab_focus()

func _process(delta: float) -> void:
	time_passed += delta
	# Suave balanço nos personagens na tela inicial
	if zeca_sprite:
		zeca_sprite.position.y = 660.0 + sin(time_passed * 2.5) * 8.0
	if faisca_sprite:
		faisca_sprite.position.y = 680.0 + cos(time_passed * 2.5) * 6.0

func _on_start_pressed() -> void:
	AudioManager.start_music()
	GameManager.reset_game()
	get_tree().change_scene_to_file("res://scenes/Fase1_Corrente.tscn")

func _on_sound_pressed() -> void:
	AudioManager.toggle_sound()
	update_sound_button()

func update_sound_button() -> void:
	if btn_sound:
		btn_sound.text = "SOM: LIGADO" if AudioManager.sound_enabled else "SOM: MUDO"
