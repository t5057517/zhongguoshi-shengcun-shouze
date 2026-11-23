extends LevelBase
## 第三关：验证码
## 游戏内登录页：手机号、“获取验证码”按钮、6 格输入框。
## 点击获取后 0.8–1.5 秒开始连续弹出横幅（核心区顶部 y=0，343x64，左右各留 16px），
## 新横幅会把旧横幅压下去。验证码横幅只停留 2 秒，混在其他横幅里。
##
## 判定：点中验证码横幅 → login；连续 3 次未命中 → locked（“操作频繁，请明日再试”）
## 未命中：按钮显示“重新获取（3）”倒计时；再次获取时横幅速度提高 20%

@export var first_delay_min := 0.8
@export var first_delay_max := 1.5
@export var banner_interval := 0.55     ## 横幅弹出间隔（秒）
@export var banner_life := 3.0          ## 普通横幅停留时长
@export var code_life := 2.0            ## 验证码横幅停留时长
@export var banners_per_round := 8      ## 每次获取弹出的横幅数量
@export var speed_up := 1.2             ## 每次未命中后速度倍率
@export var max_miss := 3
@export var retry_wait := 3             ## “重新获取（3）”倒计时秒数
@export var max_stack := 4              ## 同时最多显示几条横幅

const BANNER_X := 16.0
const BANNER_W := 343.0
const BANNER_H := 64.0
const GAP := 8.0
const GET_RECT := Rect2(44, 350, 287, 48)
const LOGIN_RECT := Rect2(44, 410, 287, 48)
const POOL := [
	["省省乐", "双十一预热开启！", "e8453c", "省"],
	["钱多多", "您有一笔贷款待领取", "f2a33a", "钱"],
	["朋友圈", "好友给你点了个赞", "5fb36a", "友"],
	["消消乐", "体力已回满，快来玩", "7b5bd6", "消"],
	["驿站", "您的快递已到驿站", "3d7be0", "递"],
	["省省乐", "你看过的商品降价了", "e8453c", "省"],
	["外卖", "满30减5红包快过期", "ff9f43", "外"],
	["银行", "您的账单已出", "4a4a52", "银"],
	["视频", "你关注的主播开播了", "d64a8a", "视"],
	["天气", "明天有雨，记得带伞", "4fa3e0", "天"],
]

var state := "idle"          ## idle / sending / wait / login / locked
var misses := 0
var speed := 1.0
var banners: Array = []      ## 每条：Dictionary
var spawned := 0
var code_index := 0
var code_done := false       ## 本轮验证码横幅已结束（被点或消失）
var next_spawn := 0.0
var wait_until := 0.0
var code := ""
var typed := 0
var popup := ""              ## "" / realname / locked
var popup_t := 0.0
var _pool_order: Array = []


func _ready() -> void:
	_pool_order = range(POOL.size())
	_pool_order.shuffle()


func _button_label() -> String:
	match state:
		"sending":
			return "已发送"
		"wait":
			return "重新获取（%d）" % ceili(wait_until - t)
		"locked":
			return "明日再试"
		"login":
			return "已发送"
	return "重新获取" if misses > 0 else "获取验证码"


func _request() -> void:
	state = "sending"
	speed = pow(speed_up, misses)
	spawned = 0
	code_index = randi_range(2, 4)
	code_done = false
	code = "%06d" % randi_range(0, 999999)
	next_spawn = t + randf_range(first_delay_min, first_delay_max) / speed
	Sfx.play("tap")


func _spawn(is_code: bool) -> void:
	var b := {"code": is_code, "born": t, "y": -BANNER_H - 10.0, "gone": -1.0, "dx": 0.0}
	if is_code:
		b["title"] = "生存守则"
		b["body"] = "验证码：" + code
		b["col"] = "22a06b"
		b["glyph"] = "信"
		b["life"] = code_life / speed
	else:
		var it: Array = POOL[_pool_order[(spawned + misses * 3) % POOL.size()]]
		b["title"] = it[0]
		b["body"] = it[1]
		b["col"] = it[2]
		b["glyph"] = it[3]
		b["life"] = banner_life / speed
	banners.push_front(b)
	Sfx.play("ding", 0.15)


func _kill(b: Dictionary, slide := 0.0) -> void:
	if float(b["gone"]) >= 0.0:
		return
	b["gone"] = t
	b["dx"] = slide
	if b["code"] and state == "sending":
		code_done = true


func _tick(delta: float) -> void:
	if state == "sending" and spawned < banners_per_round and t >= next_spawn:
		_spawn(spawned == code_index)
		spawned += 1
		next_spawn += banner_interval / speed
	# 横幅：寿命、堆叠、动画
	var alive := 0
	for b in banners:
		if float(b["gone"]) < 0.0:
			if t - float(b["born"]) > float(b["life"]) or alive >= max_stack:
				_kill(b)
			else:
				var target := alive * (BANNER_H + GAP)
				b["y"] = move_toward(float(b["y"]), target, delta * 700.0)
				alive += 1
	banners = banners.filter(func(b: Dictionary) -> bool: return float(b["gone"]) < 0.0 or t - float(b["gone"]) < 0.3)
	# 本轮结束：全部弹完 + 验证码横幅已消失
	if state == "sending" and spawned >= banners_per_round and code_done:
		_round_missed()
	if state == "wait" and t >= wait_until:
		state = "idle"


func _round_missed() -> void:
	misses += 1
	Sfx.play("buzz")
	if misses >= max_miss:
		state = "locked"
		popup = "locked"
		popup_t = t
		Sfx.play("bad", 0.0)
		later(1.8, finish.bind("locked"))
	else:
		state = "wait"
		wait_until = t + retry_wait


func _hit_code(b: Dictionary) -> void:
	state = "login"
	_kill(b, 0.0)
	for other in banners:
		_kill(other, 0.0)
	Sfx.play("ok", 0.0)
	for i in 6:
		later(0.15 + i * 0.07, _type_digit)
	later(0.15 + 6 * 0.07 + 1.0, _show_realname)
	later(0.15 + 6 * 0.07 + 2.8, finish.bind("login"))


func _type_digit() -> void:
	typed += 1
	Sfx.play("scan", 0.0)


func _show_realname() -> void:
	popup = "realname"
	popup_t = t
	Sfx.play("pop")


# ---------------------------------------------------------------- 输入

func _on_press(p: Vector2) -> void:
	if state == "login" or state == "locked":
		return
	# 先判断横幅（盖在页面上方）
	for b in banners:
		if float(b["gone"]) >= 0.0:
			continue
		var r := Rect2(BANNER_X, float(b["y"]), BANNER_W, BANNER_H)
		if r.has_point(p):
			if b["code"]:
				_hit_code(b)
			else:
				Sfx.play("buzz")
				_kill(b, 1.0)
			return
	if GET_RECT.has_point(p) and state == "idle":
		_request()


# ---------------------------------------------------------------- 绘制

func _draw() -> void:
	var r := Rect2(0, view_top, W, view_bottom - view_top)
	draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]),
		PackedColorArray([Color("1d2340"), Color("1d2340"), Color("4a3a6e"), Color("4a3a6e")]))
	for i in 18:
		var sp := Vector2(fmod(i * 97.0, W), fmod(i * 61.0, 160.0) + 10.0)
		draw_circle(sp, 1.5, Color(1, 1, 1, 0.25 + 0.2 * sin(t * 2.0 + i)))
	text("生存守则", Vector2(W / 2, 118), 30, GOLD)
	text("ONLINE", Vector2(W / 2, 150), 14, Color(1, 1, 1, 0.6))

	box_shadow(Rect2(24, 174, 327, 352), PAPER, 18.0, 5.0)
	text("手机号登录", Vector2(44, 198), 17, INK, true, HORIZONTAL_ALIGNMENT_LEFT)
	box(Rect2(44, 218, 287, 46), Color("f3efe8"), 10.0, 1.5, Color("cfc6b8"))
	text("+86", Vector2(70, 241), 16, INK)
	line(Vector2(94, 228), Vector2(94, 254), Color("cfc6b8"), 1.5)
	text("138 **** 8888", Vector2(108, 241), 16, INK, false, HORIZONTAL_ALIGNMENT_LEFT)
	for i in 6:
		var cr := Rect2(44 + i * 49.4, 280, 40, 50)
		var filled := i < typed
		box(cr, Color.WHITE, 8.0, 2.0, GREEN if filled else Color("cfc6b8"))
		if filled:
			text(code.substr(i, 1), cr.get_center(), 22, INK)
		elif i == typed and state != "login" and fmod(t, 1.0) < 0.5:
			line(cr.get_center() + Vector2(0, -12), cr.get_center() + Vector2(0, 12), INK, 2.0)
	var active := state == "idle"
	box_shadow(GET_RECT, Color("ff8a3d") if active else Color("d8d0c4"), 24.0, 3.0 if active else 0.0)
	text(_button_label(), GET_RECT.get_center(), 17, Color.WHITE if active else Color("8a8178"))
	var can_login := typed >= 6
	box_shadow(LOGIN_RECT, GREEN if can_login else Color("e6e0d6"), 24.0, 3.0 if can_login else 0.0)
	text("登录" if not can_login else "登录中…", LOGIN_RECT.get_center(), 17, Color.WHITE if can_login else Color("b0a89e"))
	text("登录即同意用户协议", Vector2(W / 2, 494), 14, SOFT, false)

	for i in range(banners.size() - 1, -1, -1):
		_draw_banner(banners[i])

	if popup != "":
		_draw_popup()
	draw_bubbles()


func _draw_banner(b: Dictionary) -> void:
	var a := 1.0
	var off := Vector2.ZERO
	if float(b["gone"]) >= 0.0:
		var k := clampf((t - float(b["gone"])) / 0.3, 0.0, 1.0)
		a = 1.0 - k
		off = Vector2(float(b["dx"]) * 260.0 * k, -30.0 * k * (1.0 - float(b["dx"])))
	var r := Rect2(Vector2(BANNER_X, float(b["y"])) + off, Vector2(BANNER_W, BANNER_H))
	var col := Color(String(b["col"]))
	draw_style_box(_sb(Color(0, 0, 0, 0.25 * a), 14, 0, INK), Rect2(r.position + Vector2(0, 3), r.size))
	box(r, Color(1, 1, 1, a), 14.0, 2.0, Color(INK, a))
	box(Rect2(r.position + Vector2(2, 10), Vector2(5, BANNER_H - 20)), Color(col, a), 2.0, 0)
	var ic := Rect2(r.position + Vector2(16, 14), Vector2(36, 36))
	box(ic, Color(col, a), 9.0, 0)
	text(String(b["glyph"]), ic.get_center(), 18, Color(1, 1, 1, a))
	text(String(b["title"]), r.position + Vector2(62, 21), 14, Color(INK, a), true, HORIZONTAL_ALIGNMENT_LEFT)
	text("刚刚", r.position + Vector2(BANNER_W - 14, 21), 14, Color(SOFT, a), false, HORIZONTAL_ALIGNMENT_RIGHT)
	text(String(b["body"]), r.position + Vector2(62, 44), 15, Color(INK, a), false, HORIZONTAL_ALIGNMENT_LEFT)


func _draw_popup() -> void:
	fill_screen(Color(0, 0, 0, 0.5))
	var k := ease_out_back(clampf((t - popup_t) / 0.22, 0.0, 1.0))
	var dlg := Rect2(37.5, 178, 300, 248) if popup == "realname" else Rect2(47.5, 240, 280, 120)
	var c := dlg.get_center()
	draw_set_transform(c * (1.0 - k), 0.0, Vector2(k, k))
	box_shadow(dlg, PAPER, 18.0, 4.0)
	if popup == "realname":
		text("请完成实名认证", Vector2(187.5, 210), 20)
		for i in 2:
			var fr := Rect2(61.5, 236 + i * 52, 252, 42)
			box(fr, Color("f3efe8"), 10.0, 1.5, Color("cfc6b8"))
			text(["姓名", "身份证号"][i], fr.position + Vector2(14, 21), 15, SOFT, false, HORIZONTAL_ALIGNMENT_LEFT)
		var gb := Rect2(61.5, 350, 252, 48)
		box_shadow(gb, Color("ff8a3d"), 24.0, 3.0)
		text("获取验证码", gb.get_center(), 17, Color.WHITE)
	else:
		text("操作频繁", Vector2(187.5, 276), 20, RED)
		text("请明日再试", Vector2(187.5, 316), 16, SOFT, false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
