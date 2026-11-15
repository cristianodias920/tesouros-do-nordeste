extends Control

@onready var btn_start: Button = $VBoxContainer/BtnStart
@onready var btn_sound: Button = $VBoxContainer/BtnSound

func _ready() -> void:
	btn_start.pressed.connect(_on_start_pressed)
	btn_sound.pressed.connect(_on_sound_pressed)
	update_sound_button()
	btn_start.grab_focus()

func _on_start_pressed() -> void:
	AudioManager.start_music()
	GameManager.reset_game()
	# historinha da fase antes do jogo (pode ser pulada)
	Historia.iniciar(get_tree(), "corrente", "res://scenes/Fase1_Corrente.tscn")

func _on_sound_pressed() -> void:
	AudioManager.toggle_sound()
	update_sound_button()

func update_sound_button() -> void:
	if btn_sound:
		btn_sound.text = "SOM: LIGADO" if AudioManager.sound_enabled else "SOM: MUDO"
