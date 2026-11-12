extends Control
## 第二关：我只是想关掉它
## 阶段1：开屏广告（多个陷阱，只有灰色小点能真关闭）
## 阶段2：卸载双弹窗（误触3次=已被转化；正确关掉=卸载后弹猜你喜欢）

signal level_finished(result_id: String)

enum Phase { AD, UNINSTALL }
enum Result { NONE, CONVERTED, UNINSTALLED }

@onready var ad_root: Control = $AdRoot
@onready var uninstall_root: Control = $UninstallRoot
@onready var skip_label: Label = $AdRoot/SkipLabel
@onready var gray_dot: Control = $AdRoot/GrayDot
@onready var close_x: Control = $AdRoot/CloseX
@onready var big_button: Control = $AdRoot/BigButton
@onready var hint: Label = $Hint
@onready var result_label: Label = $ResultLabel

var phase := Phase.AD
var result := Result.NONE

# 跳过倒计时
var skip_left := 5
var skip_timer := 0.0

# 滑动陷阱
var touch_start := Vector2.ZERO
var touch_moved := false

# 弹窗状态
var uninstall_step := 0
var mistake_count := 0

func _ready() -> void:
	ad_root.visible = true
	uninstall_root.visible = false
	_setup_ad()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_mouse_filter_ignore()

func _apply_mouse_filter_ignore() -> void:
	for child in get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 但广告内的可点元素要能收到点击，这里改用 _input 统一处理，不依赖 mouse_filter

func _setup_ad() -> void:
	skip_left = 5
	skip_label.text = "跳过 " + str(skip_left)
	# 灰色小点藏在角落（右下角，28×28 热区）
	gray_dot.position = Vector2(1180, 620)
	gray_dot.size = Vector2(28, 28)

func _process(delta: float) -> void:
	if result != Result.NONE:
		return
	if phase == Phase.AD:
		skip_timer += delta
		if skip_timer >= 1.0:
			skip_timer = 0.0
			skip_left -= 1
			if skip_left <= 0:
				skip_left = 0
				skip_label.text = "跳过"
				# 归零后，"跳过"按钮变成可点的真关闭入口
			else:
				skip_label.text = "跳过 " + str(skip_left)

func _input(event: InputEvent) -> void:
	if result != Result.NONE:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			touch_start = event.position
			touch_moved = false
			_on_press(event.position)
		else:
			if phase == Phase.AD and touch_moved and touch_start.distance_to(event.position) > 30.0:
				# 滑动陷阱：跳转（转为"已被转化"）
				_converted()
			else:
				_on_release(event.position)
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if phase == Phase.AD:
			var d: Vector2 = event.position - touch_start
			if d.length() > 8.0:
				touch_moved = true

func _on_press(pos: Vector2) -> void:
	pass

func _on_release(pos: Vector2) -> void:
	if phase == Phase.AD:
		_handle_ad_click(pos)
	elif phase == Phase.UNINSTALL:
		_handle_uninstall_click(pos)

func _handle_ad_click(pos: Vector2) -> void:
	# 灰色小点：真关闭
	if gray_dot.get_global_rect().has_point(pos):
		_enter_uninstall()
		return
	# 跳过按钮（归零后可点）：真关闭
	if skip_left <= 0 and _rect_contains(skip_label, pos):
		_enter_uninstall()
		return
	# 中央 × ：陷阱 → 跳转（转化）
	if _rect_contains(close_x, pos):
		_converted()
		return
	# 大按钮：陷阱 → 跳转（转化）
	if _rect_contains(big_button, pos):
		_converted()
		return

func _rect_contains(node: Control, pos: Vector2) -> bool:
	return node.get_global_rect().has_point(pos)

func _enter_uninstall() -> void:
	phase = Phase.UNINSTALL
	ad_root.visible = false
	uninstall_root.visible = true
	uninstall_step = 0
	mistake_count = 0
	_show_uninstall_step(0)
	hint.text = "卸载这个 App（小心陷阱按钮）"

func _show_uninstall_step(step: int) -> void:
	# 用弹窗里的按钮文字区分步骤
	var popup := uninstall_root
	# 步骤0：第一弹窗「再想想 / 残忍卸载」
	# 步骤1：第二弹窗「保留优惠券 / 仍然卸载」
	var btn1: Label = popup.get_node("Btn1")
	var btn2: Label = popup.get_node("Btn2")
	var title: Label = popup.get_node("PopupTitle")
	if step == 0:
		title.text = "真的要卸载吗？"
		btn1.text = "再想想"
		btn2.text = "残忍卸载"
	else:
		title.text = "送你一张 50 元优惠券"
		btn1.text = "保留优惠券"
		btn2.text = "仍然卸载"

func _handle_uninstall_click(pos: Vector2) -> void:
	var popup := uninstall_root
	var btn1: Label = popup.get_node("Btn1")
	var btn2: Label = popup.get_node("Btn2")
	# 灰色小字（真卸载入口）藏在弹窗角落
	var gray_hint: Control = popup.get_node("GrayHint")

	if gray_hint.get_global_rect().has_point(pos):
		_uninstalled()
		return

	if _rect_contains(btn1, pos):
		# 陷阱按钮：再想想 / 保留优惠券 → 误触
		_mistake()
		return
	if _rect_contains(btn2, pos):
		# 陷阱按钮：残忍卸载 / 仍然卸载 → 误触
		_mistake()
		return

func _mistake() -> void:
	mistake_count += 1
	if mistake_count >= 3:
		_converted()
	else:
		# 继续弹下一个弹窗
		uninstall_step = (uninstall_step + 1) % 2
		_show_uninstall_step(uninstall_step)
		hint.text = "又被套路了…（误触 " + str(mistake_count) + "/3）"

func _converted() -> void:
	result = Result.CONVERTED
	uninstall_root.visible = false
	ad_root.visible = false
	result_label.text = "已被转化\n（你没能关掉它）"
	result_label.add_theme_color_override("font_color", Color(0.75, 0.2, 0.15))
	level_finished.emit("converted")

func _uninstalled() -> void:
	result = Result.UNINSTALLED
	uninstall_root.visible = false
	ad_root.visible = false
	result_label.text = "卸载成功\n猜你喜欢：又装回来了"
	result_label.add_theme_color_override("font_color", Color(0.15, 0.6, 0.3))
	level_finished.emit("uninstalled")
