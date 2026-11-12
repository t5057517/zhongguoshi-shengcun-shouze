extends Control
## 标题画面：游戏标题 + 开始生存（进第一关）+ 删除存档（无功能）

signal start_game

@onready var toast: Label = $Toast

var start_rect := Rect2(480, 400, 320, 80)
var delete_rect := Rect2(480, 520, 320, 60)

func _ready() -> void:
	toast.visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var pos: Vector2 = event.position
		if start_rect.has_point(pos):
			start_game.emit()
		elif delete_rect.has_point(pos):
			_show_toast("删除存档功能暂未开放")

func _show_toast(msg: String) -> void:
	toast.text = msg
	toast.visible = true
	var tween := create_tween()
	tween.tween_interval(1.2)
	tween.tween_callback(func(): toast.visible = false)
