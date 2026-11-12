extends Control
## 标题画面：游戏标题 + 开始生存（进第一关）+ 删除存档（无功能）

signal start_game

@onready var start_btn: Panel = $StartBtn
@onready var delete_btn: Panel = $DeleteBtn
@onready var toast: Label = $Toast

func _ready() -> void:
	start_btn.gui_input.connect(_on_start_gui_input)
	delete_btn.gui_input.connect(_on_delete_gui_input)
	start_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	delete_btn.mouse_filter = Control.MOUSE_FILTER_STOP

func _on_start_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		start_game.emit()

func _on_delete_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		toast.text = "删除存档功能暂未开放"
		toast.visible = true
		var tween := create_tween()
		tween.tween_interval(1.2)
		tween.tween_callback(func(): toast.visible = false)
