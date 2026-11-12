extends Control
## 第一关：只剪一次（理发店收银台）
## 统一使用全局坐标，拖动逻辑用 _unhandled_input 处理，避免子节点拦截。

signal level_finished(result_id: String)

enum Result { NONE, SINGLE, CARD }

@onready var phone: Control = $Phone
@onready var hand: Control = $TonyHand
@onready var card_qr: Control = $CardQR
@onready var single_qr: Control = $SingleQR
@onready var tony_bubble: Label = $TonyBubble
@onready var result_label: Label = $ResultLabel

var phone_start_pos: Vector2

var blocking := true
var block_timer := 0.0
const BLOCK_TIME := 1.5
const REVEAL_TIME := 0.7

var dragging := false
var drag_offset := Vector2.ZERO

var result := Result.NONE

var tony_words := ["办卡打五折", "充值送护理"]
var tony_index := 0
var tony_timer := 0.0

# 套餐滚动演出用
var menu_items := ["剪发 ¥38", "洗剪吹 ¥68", "烫染会员卡 ¥1280", "至尊黑金卡 ¥6888"]
var menu_index := 0
var menu_playing := false
var menu_rolling := false
var menu_timer := 0.0
const MENU_STEP := 0.4

func _ready() -> void:
	phone_start_pos = phone.position
	_setup_qr()
	_show_hand_blocking(true)
	# 根节点设为 IGNORE，让鼠标事件不被子节点或根节点消费，
	# 统一走 _unhandled_input 处理
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _setup_qr() -> void:
	_draw_fake_qr(card_qr)
	_draw_fake_qr(single_qr)

func _draw_fake_qr(target: Control) -> void:
	for child in target.get_children():
		child.queue_free()
	var grid := 7
	var cell_size := target.size.x / grid
	for y in grid:
		for x in grid:
			var corner := (x < 2 and y < 2) or (x >= grid - 2 and y < 2) or (x < 2 and y >= grid - 2)
			if corner:
				continue
			if randf() < 0.5:
				var cell := ColorRect.new()
				cell.color = Color(0.1, 0.1, 0.1)
				cell.position = Vector2(x * cell_size, y * cell_size)
				cell.size = Vector2(cell_size * 0.9, cell_size * 0.9)
				target.add_child(cell)

func _show_hand_blocking(on: bool) -> void:
	if on:
		hand.position = single_qr.position - Vector2(20, 20)
		hand.modulate.a = 1.0
	else:
		hand.position = single_qr.position + Vector2(160, -60)
		hand.modulate.a = 0.35

func _process(delta: float) -> void:
	if result != Result.NONE:
		return

	block_timer += delta
	if blocking and block_timer >= BLOCK_TIME:
		blocking = false
		block_timer = 0.0
		_show_hand_blocking(false)
	elif not blocking and block_timer >= REVEAL_TIME:
		blocking = true
		block_timer = 0.0
		_show_hand_blocking(true)

	tony_timer += delta
	if tony_timer >= 1.8:
		tony_timer = 0.0
		tony_index = (tony_index + 1) % tony_words.size()
		tony_bubble.text = tony_words[tony_index]

	# 套餐滚动演出（card 结果时逐条滚动）
	if menu_playing and not menu_rolling:
		menu_timer += delta
		if menu_timer >= MENU_STEP:
			menu_timer = 0.0
			menu_index += 1
			if menu_index >= menu_items.size():
				menu_playing = false
				menu_rolling = true
				var wait := create_tween()
				wait.tween_interval(0.8)
				wait.tween_callback(_finish_menu)
			else:
				_show_menu_item(menu_index)

func _input(event: InputEvent) -> void:
	if result != Result.NONE:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# 只在鼠标点在手机上时才开始拖动
			if _global_mouse_in_phone():
				dragging = true
				drag_offset = phone.global_position - get_global_mouse_position()
		else:
			if dragging:
				dragging = false
				_judge()
	elif event is InputEventMouseMotion and dragging:
		phone.global_position = get_global_mouse_position() + drag_offset

func _global_mouse_in_phone() -> bool:
	return phone.get_global_rect().has_point(get_global_mouse_position())

func _judge() -> void:
	# 扫码点：手机中心 + 向下偏移（手机底部靠下）
	var phone_rect := phone.get_global_rect()
	var scan_point := phone_rect.position + Vector2(phone_rect.size.x / 2.0, phone_rect.size.y + 12.0)

	var in_card := card_qr.get_global_rect().has_point(scan_point)
	var in_single := single_qr.get_global_rect().has_point(scan_point)

	if not blocking and in_single:
		_finish_single()
	elif in_card or (blocking and in_single):
		_start_menu_show()
	else:
		var tween := create_tween()
		tween.tween_property(phone, "position", phone_start_pos, 0.3)

func _finish_single() -> void:
	result = Result.SINGLE
	hand.modulate.a = 0.0
	result_label.text = "支付成功 ¥38"
	result_label.add_theme_color_override("font_color", Color(0.15, 0.6, 0.3))
	level_finished.emit("single")

func _start_menu_show() -> void:
	result = Result.CARD
	hand.modulate.a = 0.0
	result_label.text = "套餐列表："
	result_label.add_theme_color_override("font_color", Color(0.75, 0.2, 0.15))
	menu_index = 0
	menu_playing = true
	menu_rolling = false
	menu_timer = 0.0
	_show_menu_item(0)

func _show_menu_item(i: int) -> void:
	result_label.text = "套餐列表\n" + menu_items[i]

func _finish_menu() -> void:
	# 滚动到最后一条后停留一下，再真正结束关卡
	result_label.text = "套餐列表\n至尊黑金卡 ¥6888"
	level_finished.emit("card")
