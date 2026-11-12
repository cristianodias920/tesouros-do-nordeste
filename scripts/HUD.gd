extends CanvasLayer

@onready var heart_1: TextureRect = $TopBar/HeartsContainer/Heart1
@onready var heart_2: TextureRect = $TopBar/HeartsContainer/Heart2
@onready var heart_3: TextureRect = $TopBar/HeartsContainer/Heart3
@onready var gems_label: Label = $TopBar/GemsContainer/GemsLabel
@onready var sound_button: Button = $TopBar/ButtonsContainer/SoundButton
@onready var pause_button: Button = $TopBar/ButtonsContainer/PauseButton

# Controles de toque
@onready var touch_controls: Control = $TouchControls
@onready var btn_touch_action: TouchScreenButton = $TouchControls/BtnAction

# Telas de sobreposição
@onready var pause_menu: Control = $PauseMenu
@onready var victory_screen: Control = $VictoryScreen
@onready var game_over_screen: Control = $GameOverScreen
@onready var victory_gems_label: Label = $VictoryScreen/Panel/VBox/GemsCountLabel

var tex_heart_full: Texture2D
var tex_heart_empty: Texture2D

func _ready() -> void:
	if ResourceLoader.exists("res://sprites/items/coracao_cheio.png"):
		tex_heart_full = load("res://sprites/items/coracao_cheio.png")
	if ResourceLoader.exists("res://sprites/items/coracao_vazio.png"):
		tex_heart_empty = load("res://sprites/items/coracao_vazio.png")

	GameManager.lives_changed.connect(_on_lives_changed)
	GameManager.gems_changed.connect(_on_gems_changed)
	GameManager.level_completed.connect(_on_level_completed)
	GameManager.game_over.connect(_on_game_over)

	update_lives_display(GameManager.current_lives)
	update_gems_display(GameManager.collected_gems, GameManager.TOTAL_GEMS)
	update_sound_button_label()

	pause_menu.visible = false
	victory_screen.visible = false
	game_over_screen.visible = false

	# Mobile / Touch inicial
	# No desktop teclado esconde os botões ao digitar
	touch_controls.visible = DisplayServer.is_touchscreen_available()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		touch_controls.visible = false
	elif event is InputEventScreenTouch or (event is InputEventMouseButton and event.pressed):
		# Se tocou na tela, exibe controles de toque
		touch_controls.visible = true

	if event.is_action_pressed("pause"):
		toggle_pause()

func _process(_delta: float) -> void:
	# O botão de coice no toque só aparece quando estiver montado no Faísca
	if btn_touch_action:
		btn_touch_action.visible = GameManager.is_mounted

func _on_lives_changed(lives: int) -> void:
	update_lives_display(lives)

func update_lives_display(lives: int) -> void:
	if heart_1:
		heart_1.texture = tex_heart_full if lives >= 1 else tex_heart_empty
	if heart_2:
		heart_2.texture = tex_heart_full if lives >= 2 else tex_heart_empty
	if heart_3:
		heart_3.texture = tex_heart_full if lives >= 3 else tex_heart_empty

func _on_gems_changed(gems: int, total: int) -> void:
	update_gems_display(gems, total)

func update_gems_display(gems: int, total: int) -> void:
	if gems_label:
		gems_label.text = str(gems) + "/" + str(total)

func _on_sound_button_pressed() -> void:
	AudioManager.toggle_sound()
	update_sound_button_label()

func update_sound_button_label() -> void:
	if sound_button:
		sound_button.text = "SOM: LIGADO" if AudioManager.sound_enabled else "SOM: MUDO"

func _on_pause_button_pressed() -> void:
	toggle_pause()

func toggle_pause() -> void:
	var tree = get_tree()
	tree.paused = not tree.paused
	pause_menu.visible = tree.paused

func _on_continue_button_pressed() -> void:
	get_tree().paused = false
	pause_menu.visible = false

func _on_menu_button_pressed() -> void:
	get_tree().paused = false
	GameManager.reset_game()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	GameManager.reset_game()
	get_tree().reload_current_scene()

func _on_level_completed() -> void:
	victory_screen.visible = true
	if victory_gems_label:
		victory_gems_label.text = "Tesouros coletados: " + str(GameManager.collected_gems) + "/" + str(GameManager.TOTAL_GEMS)

func _on_game_over() -> void:
	game_over_screen.visible = true
