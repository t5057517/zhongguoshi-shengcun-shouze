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
	# 结果演出后进入下一关（暂只有一关，先打印）
	print("关卡结束，结果：", result_id)
	# 预留：黑屏转场 → 下一关
