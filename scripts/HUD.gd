extends CanvasLayer

@onready var heart_1: TextureRect = $TopLeft/HeartsContainer/Heart1
@onready var heart_2: TextureRect = $TopLeft/HeartsContainer/Heart2
@onready var heart_3: TextureRect = $TopLeft/HeartsContainer/Heart3
@onready var gems_label: Label = $TopLeft/GemsContainer/GemsLabel
@onready var sound_button: Button = $TopRight/ButtonsContainer/SoundButton
@onready var pause_button: Button = $TopRight/ButtonsContainer/PauseButton

# Controles de toque
@onready var touch_controls: Control = $TouchControls
@onready var btn_left: TouchScreenButton = $TouchControls/BtnLeft
@onready var btn_right: TouchScreenButton = $TouchControls/BtnRight
@onready var btn_jump: TouchScreenButton = $TouchControls/BtnJump
@onready var btn_action: TouchScreenButton = $TouchControls/BtnAction

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
	# Conta o total de tesouros depois que a fase inteira entrou na árvore
	GameManager.call_deferred("recount_total", get_tree())

	pause_menu.visible = false
	victory_screen.visible = false
	game_over_screen.visible = false

	# Posiciona os botões de toque dinamicamente nas bordas da tela
	get_viewport().size_changed.connect(_update_touch_positions)
	_update_touch_positions()

	# Mobile / Touch inicial
	touch_controls.visible = DisplayServer.is_touchscreen_available()

func _update_touch_positions() -> void:
	var vp_size = get_viewport().get_visible_rect().size
	var btn_size = 150.0
	var margin_bottom = 40.0
	var margin_side = 40.0

	var y_pos = vp_size.y - btn_size - margin_bottom

	if btn_left:
		btn_left.position = Vector2(margin_side, y_pos)
	if btn_right:
		btn_right.position = Vector2(margin_side + btn_size + 30.0, y_pos)
	if btn_jump:
		btn_jump.position = Vector2(vp_size.x - btn_size - margin_side, y_pos)
	if btn_action:
		btn_action.position = Vector2(vp_size.x - (btn_size * 2.0) - margin_side - 30.0, y_pos)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		# Teclado esconde os botões de toque
		touch_controls.visible = false
	elif event is InputEventScreenTouch or (event is InputEventMouseButton and event.pressed):
		# Toque na tela reexibe os botões de toque (menos nas telas de fim)
		touch_controls.visible = not GameManager.is_level_ended

	if event.is_action_pressed("pause"):
		toggle_pause()

func _process(_delta: float) -> void:
	# O botão de coice no toque só aparece montado no Faísca
	if btn_action:
		btn_action.visible = GameManager.is_mounted

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
	if GameManager.is_level_ended:
		return # não pausa por cima da vitória ou do FIM DA AVENTURA
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
	touch_controls.visible = false
	if victory_gems_label:
		victory_gems_label.text = "Tesouros coletados: " + str(GameManager.collected_gems) + "/" + str(GameManager.TOTAL_GEMS)

func _on_game_over() -> void:
	game_over_screen.visible = true
	touch_controls.visible = false
