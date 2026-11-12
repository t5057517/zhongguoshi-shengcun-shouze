extends Control
## 第一关：只剪一次（理发店收银台）

signal level_finished(result_id: String)

# 判定结果
enum Result { NONE, SINGLE, CARD }

# 场景节点引用
@onready var phone: Control = $Phone
@onready var hand: Control = $TonyHand
@onready var card_qr: Control = $CardQR
@onready var single_qr: Control = $SingleQR
@onready var tony_bubble: Label = $TonyBubble
@onready var result_label: Label = $ResultLabel

# 手机初始位置
var phone_start_pos: Vector2

# 遮挡状态
var blocking := true
var block_timer := 0.0
const BLOCK_TIME := 1.5
const REVEAL_TIME := 0.7

# 拖动状态
var dragging := false
var drag_offset := Vector2.ZERO

# 结果
var result := Result.NONE

# Tony 气泡轮播
var tony_words := ["办卡打五折", "充值送护理"]
var tony_index := 0
var tony_timer := 0.0

func _ready() -> void:
	phone_start_pos = phone.position
	_setup_qr()
	_show_hand_blocking(true)

func _setup_qr() -> void:
	# 装饰性二维码（不生成真实可识别二维码）
	_draw_fake_qr(card_qr)
	_draw_fake_qr(single_qr)

func _draw_fake_qr(target: Control) -> void:
	# 用 ColorRect 拼一个伪二维码图案
	for child in target.get_children():
		child.queue_free()
	var grid := 7
	var cell_size := target.size.x / grid
	for y in grid:
		for x in grid:
			# 三个角留白模拟定位角
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
	# Tony 的手遮挡/移开单次付款码
	if on:
		# 盖住单次付款码
		hand.position = single_qr.position - Vector2(20, 20)
		hand.modulate.a = 1.0
	else:
		# 移开
		hand.position = single_qr.position + Vector2(140, -60)
		hand.modulate.a = 0.35

func _process(delta: float) -> void:
	if result != Result.NONE:
		return

	# 遮挡循环
	block_timer += delta
	if blocking and block_timer >= BLOCK_TIME:
		blocking = false
		block_timer = 0.0
		_show_hand_blocking(false)
	elif not blocking and block_timer >= REVEAL_TIME:
		blocking = true
		block_timer = 0.0
		_show_hand_blocking(true)

	# Tony 气泡轮播
	tony_timer += delta
	if tony_timer >= 1.8:
		tony_timer = 0.0
		tony_index = (tony_index + 1) % tony_words.size()
		tony_bubble.text = tony_words[tony_index]

# ---- 拖动手机 ----
func _gui_input(event: InputEvent) -> void:
	if result != Result.NONE:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			drag_offset = phone.position - event.position
		else:
			if dragging:
				dragging = false
				_judge()
	elif event is InputEventMouseMotion and dragging:
		phone.position = event.position + drag_offset

func _judge() -> void:
	# 扫码点：手机底部偏下
	var scan_point := phone.position + Vector2(phone.size.x / 2, phone.size.y + 10)
	var in_card := _point_in_rect(scan_point, card_qr)
	var in_single := _point_in_rect(scan_point, single_qr)

	if not blocking and in_single:
		_finish(Result.SINGLE)
	elif in_card or (blocking and in_single):
		_finish(Result.CARD)
	else:
		# 弹回原位
		var tween := create_tween()
		tween.tween_property(phone, "position", phone_start_pos, 0.3)

func _point_in_rect(p: Vector2, rect: Control) -> bool:
	var r := rect.get_global_rect()
	return r.has_point(p)

func _finish(r: int) -> void:
	result = r
	hand.modulate.a = 0.0
	if r == Result.SINGLE:
		result_label.text = "支付成功 ¥38"
		level_finished.emit("single")
	else:
		result_label.text = "套餐列表\n烫染会员卡 ¥1280\n至尊黑金卡 ¥6888"
		level_finished.emit("card")
