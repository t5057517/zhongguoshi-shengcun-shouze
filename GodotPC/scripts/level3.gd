extends Control
## 第三关：验证码
## 登录页 6 格输入框；点获取验证码后连续弹横幅，真验证码混在杂讯横幅中。
## 点中真验证码 = login（请完成实名认证）；点错或超时 = 记一次，3 次未中 = locked（操作频繁）。

signal level_finished(result_id: String)

enum Result { NONE, LOGIN, LOCKED }

@onready var code_boxes: Control = $CodeBoxes
@onready var get_btn: Panel = $GetBtn
@onready var banner: Panel = $Banner
@onready var banner_text: Label = $Banner/BannerText
@onready var hint: Label = $Hint
@onready var result_label: Label = $ResultLabel
@onready var count_label: Label = $CountLabel

var result := Result.NONE

# 验证码真值
var real_code := ""
# 横幅队列（名称 + 是否真验证码）
var banners: Array = []
var banner_index := 0
var banner_visible := false
var banner_timer := 0.0
const BANNER_SHOW_TIME := 2.0
const BANNER_GAP := 0.5

var miss_count := 0
var miss_timer := 0.0
var waiting_miss := false

var can_get := true
var get_cd := 0.0

func _ready() -> void:
	_setup_boxes()
	banner.visible = false
	get_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	get_btn.gui_input.connect(_on_get_btn_input)
	count_label.text = ""
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 让横幅、输入框等子节点不拦截鼠标
	for child in get_children():
		if child is Control and child != get_btn:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.mouse_filter = Control.MOUSE_FILTER_STOP
	banner.gui_input.connect(_on_banner_input)

func _setup_boxes() -> void:
	# 6 格验证码输入框（视觉占位）
	for i in 6:
		var box := Panel.new()
		box.position = Vector2(500 + i * 60, 260)
		box.size = Vector2(48, 56)
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		code_boxes.add_child(box)
	real_code = _gen_code()

func _gen_code() -> String:
	var s := ""
	for i in 6:
		s += str(randi() % 10)
	return s

func _process(delta: float) -> void:
	if result != Result.NONE:
		return

	# 获取按钮冷却
	if not can_get:
		get_cd -= delta
		if get_cd <= 0.0:
			can_get = true

	# 横幅轮播
	if banner_visible:
		banner_timer += delta
		if banner_timer >= BANNER_SHOW_TIME:
			_hide_banner()
	# 横幅间隔
	if not banner_visible and not banners.is_empty() and banner_index < banners.size():
		banner_timer += delta
		if banner_timer >= BANNER_GAP:
			_show_banner()

	# 未点中验证码的倒计时（横幅弹出后超时未点 = 记一次 miss）
	if waiting_miss:
		miss_timer += delta
		if miss_timer >= BANNER_SHOW_TIME + BANNER_GAP:
			waiting_miss = false
			_miss()

func _on_get_btn_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not can_get or result != Result.NONE:
			return
		can_get = false
		get_cd = 5.0
		_build_banners()

func _build_banners() -> void:
	# 构造横幅队列：真验证码 + 杂讯横幅（双十一/贷款/点赞）
	banners = [
		{"text": "双十一全场 5 折！点击领券", "is_real": false},
		{"text": "你的验证码：" + real_code, "is_real": true},
		{"text": "恭喜获得 30 万贷款额度", "is_real": false},
		{"text": "你的好友给你点了个赞", "is_real": false},
	]
	# 打乱顺序，但保证真验证码在其中
	banners.shuffle()
	banner_index = 0
	banner_timer = 0.0
	banner_visible = false
	miss_count = 0
	update_count()
	waiting_miss = false
	hint.text = "点中带有验证码的横幅"

func _show_banner() -> void:
	if banner_index >= banners.size():
		return
	var b = banners[banner_index]
	banner_text.text = b["text"]
	banner.visible = true
	banner_visible = true
	banner_timer = 0.0
	if b["is_real"]:
		# 真验证码横幅：开始计时，超时未点 = miss
		waiting_miss = true
		miss_timer = 0.0
	else:
		waiting_miss = false

func _hide_banner() -> void:
	banner.visible = false
	banner_visible = false
	banner_timer = 0.0
	banner_index += 1

func _on_banner_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not banner_visible:
			return
		var b = banners[banner_index]
		if b["is_real"]:
			_login()
		else:
			_miss()

func _login() -> void:
	result = Result.LOGIN
	banner.visible = false
	result_label.text = "请完成实名认证\n（你已登录）"
	result_label.add_theme_color_override("font_color", Color(0.15, 0.6, 0.3))
	level_finished.emit("login")

func _miss() -> void:
	if result != Result.NONE:
		return
	miss_count += 1
	update_count()
	hint.text = "没点中验证码（" + str(miss_count) + "/3）"
	# 跳过一个横幅（当前这个作废）
	if banner_visible:
		_hide_banner()
	if miss_count >= 3:
		_locked()
	else:
		# 重新开始一轮横幅
		_build_banners()

func _locked() -> void:
	result = Result.LOCKED
	banner.visible = false
	get_btn.modulate = Color(0.5, 0.5, 0.5, 1)
	result_label.text = "操作频繁，请稍后再试"
	result_label.add_theme_color_override("font_color", Color(0.75, 0.2, 0.15))
	level_finished.emit("locked")

func update_count() -> void:
	count_label.text = "剩余尝试：" + str(3 - miss_count)
