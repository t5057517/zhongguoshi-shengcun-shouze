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

func _ready() -> void:
	_show_title()

func _show_title() -> void:
	if current_level:
		current_level.queue_free()
		current_level = null
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
