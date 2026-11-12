extends Control
## 中国式生存守则 — 主场景：标题 → 关卡管理

const TitleScene := preload("res://scenes/Title.tscn")
const Level1Scene := preload("res://scenes/Level1.tscn")
const Level2Scene := preload("res://scenes/Level2.tscn")
const Level3Scene := preload("res://scenes/Level3.tscn")

const LEVELS := [Level1Scene, Level2Scene, Level3Scene]

var title_screen: Node = null
var current_level: Node = null
var current_index := 0

var back_btn: Panel = null
var back_text: Label = null

func _ready() -> void:
	_show_title()

func _show_title() -> void:
	if current_level:
		current_level.queue_free()
		current_level = null
	_remove_back_btn()
	title_screen = TitleScene.instantiate()
	add_child(title_screen)
	title_screen.start_game.connect(_on_start_game)

func _on_start_game() -> void:
	if title_screen:
		title_screen.queue_free()
		title_screen = null
	_load_level(0)

func _load_level(index: int) -> void:
	if current_level:
		current_level.queue_free()
		current_level = null

	current_index = index % LEVELS.size()
	current_level = LEVELS[current_index].instantiate()
	add_child(current_level)
	current_level.level_finished.connect(_on_level_finished)
	_add_back_btn()

func _add_back_btn() -> void:
	_remove_back_btn()
	back_btn = Panel.new()
	back_btn.name = "BackBtn"
	back_btn.position = Vector2(1200, 16)
	back_btn.size = Vector2(64, 40)
	back_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	back_btn.gui_input.connect(_on_back_btn_input)
	# 可见背景
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.2, 0.2, 0.25, 0.9)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back_btn.add_child(bg)
	back_text = Label.new()
	back_text.text = "返回"
	back_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	back_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	back_text.set_anchors_preset(Control.PRESET_FULL_RECT)
	back_text.add_theme_font_size_override("font_size", 18)
	back_text.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	back_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back_btn.add_child(back_text)
	add_child(back_btn)

func _remove_back_btn() -> void:
	if back_btn:
		back_btn.queue_free()
		back_btn = null
		back_text = null

func _on_back_btn_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_show_title()

func _on_level_finished(result_id: String) -> void:
	# 结果演出后，黑屏 0.5s 转场，进入下一关（当前 4 关规划，暂实现 3 关，循环演示）
	print("关卡结束，结果：", result_id)
	var fade := ColorRect.new()
	fade.color = Color(0, 0, 0, 1)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)
	await get_tree().create_timer(0.5).timeout
	_load_level(current_index + 1)
	fade.queue_free()
