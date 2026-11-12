extends Control
## 中国式生存守则 — 主场景：关卡管理

const Level1Scene := preload("res://scenes/Level1.tscn")

var current_level: Node = null

func _ready() -> void:
	# 关卡列表（后续关卡逐个加入）
	_load_level(0)

func _load_level(index: int) -> void:
	if current_level:
		current_level.queue_free()
		current_level = null

	match index:
		0:
			current_level = Level1Scene.instantiate()
		_:
			return

	add_child(current_level)
	current_level.level_finished.connect(_on_level_finished)

func _on_level_finished(result_id: String) -> void:
	# 结果演出后，黑屏 0.5s 转场，再重新加载本关（后续关卡逐个接入）
	print("关卡结束，结果：", result_id)
	var fade := ColorRect.new()
	fade.color = Color(0, 0, 0, 1)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)
	await get_tree().create_timer(0.5).timeout
	_load_level(0)
	fade.queue_free()
