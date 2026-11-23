extends LevelBase
## 第二关：我只是想关掉它（操作：点击）
##
## 阶段1 开屏广告：
##   中央“×”(64x64，广告中心) → 跳转购物页（误触）
##   “跳过 5”(295,16,64x28)   → 倒计时归零后才能点，点了关闭广告
##   灰色小点(16,16，视觉10px，热区28x28) → 关闭广告
##   手指在广告上移动超过 30px → 跳转购物页（误触）
##   跳转：显示购物页 1.5 秒，然后重新开始阶段1
## 阶段2 卸载：
##   弹窗1 “确定要卸载吗？” 亮色“再想想”/ 灰色“残忍卸载”
##   弹窗2 “卸载将失去3张优惠券” 亮色“保留优惠券”/ 灰色“仍然卸载”
##   点亮色按钮 → 回到弹窗1（误触）
## 判定：完成卸载 → uninstalled；累计误触 3 次 → converted（标题显示“已被转化”）
## 演出：静止 1 秒，弹出“猜你喜欢”，图标与原 App 几乎相同

@export var skip_seconds := 5          ## 跳过倒计时
@export var swipe_limit := 30.0        ## 滑动陷阱阈值（px）
@export var shop_time := 1.5           ## 购物页停留时长
@export var max_mistakes := 3          ## 累计误触多少次判定为“已被转化”
@export var app_name := "省省乐"

const X_RECT := Rect2(155.5, 268, 64, 64)
const SKIP_RECT := Rect2(295, 16, 64, 28)
const DOT_C := Vector2(21, 21)
const DOT_HIT := Rect2(7, 7, 28, 28)
const BUY_RECT := Rect2(87.5, 452, 200, 52)

const DLG := Rect2(37.5, 160, 300, 262)
const BRIGHT := Rect2(67.5, 318, 240, 48)
const GRAY := Rect2(127.5, 376, 120, 34)

const APPS := [
	["相机", "4a4a52"], ["天气", "4fa3e0"], ["地图", "5fb36a"], ["时钟", "2b2724"],
	["日历", "f2f2f2"], ["备忘录", "f2c94c"], ["音乐", "e8574a"], ["设置", "8e8e96"],
	["计算器", "ff9f43"], ["邮件", "3d7be0"], ["省省乐", "d9483b"], ["视频", "7b5bd6"],
]
const MY_APP := 10

var state := "ad"            ## ad / shop / home / dialog / end
var ad_t := 0.0
var mistakes := 0
var press_p := Vector2.ZERO
var swiped := false
var skip_shake := -9.0
var backdrop := "ad"         ## ad / shop / home
var pop := ""                ## "" / pop1 / pop2
var pop_t := 0.0
var icon_k := 1.0            ## 原 App 图标缩放（卸载时缩到 0）
var guess_t := -1.0
var toast := ""
var toast_t := -9.0


func _tick(delta: float) -> void:
	if state == "ad":
		ad_t += delta
	if state == "end" and backdrop == "home":
		icon_k = move_toward(icon_k, 0.0, delta * 4.0)


func _remain() -> int:
	return maxi(0, skip_seconds - int(floor(ad_t)))


# ---------------------------------------------------------------- 流程

func _mistake() -> bool:
	mistakes += 1
	Sfx.play("buzz")
	if mistakes >= max_mistakes:
		_end("converted")
		return true
	return false


func _jump() -> void:
	if state != "ad":
		return
	state = "shop"
	backdrop = "shop"
	_toast("正在为你打开活动页…")
	Sfx.play("whoosh")
	if _mistake():
		return
	later(shop_time, _restart_ad)


func _restart_ad() -> void:
	if state != "shop":
		return
	state = "ad"
	backdrop = "ad"
	ad_t = 0.0


func _close_ad() -> void:
	state = "home"
	backdrop = "home"
	Sfx.play("tap")
	later(0.7, _open_pop.bind("pop1"))


func _open_pop(which: String) -> void:
	if state == "end":
		return
	state = "dialog"
	pop = which
	pop_t = t
	Sfx.play("pop")


func _end(kind: String) -> void:
	state = "end"
	pop = ""
	if kind == "converted":
		backdrop = "shop"
		_toast("欢迎回来！已为你领好3张券")
		Sfx.play("bad", 0.0)
	else:
		backdrop = "home"
		Sfx.play("ok", 0.0)
	# 静止 1 秒 → 猜你喜欢
	later(1.0, _show_guess)
	later(3.2, finish.bind(kind))


func _show_guess() -> void:
	guess_t = t
	Sfx.play("ding")


func _toast(s: String) -> void:
	toast = s
	toast_t = t


# ---------------------------------------------------------------- 输入

func _on_press(p: Vector2) -> void:
	press_p = p
	swiped = false
	if state == "dialog":
		if BRIGHT.has_point(p):
			Sfx.play("tap")
			if not _mistake():
				pop = ""
				later(0.45, _open_pop.bind("pop1"))
		elif GRAY.has_point(p):
			Sfx.play("tap")
			if pop == "pop1":
				_open_pop("pop2")
			else:
				_end("uninstalled")


func _on_drag(p: Vector2) -> void:
	if state == "ad" and not swiped and p.distance_to(press_p) > swipe_limit:
		swiped = true
		_jump()


func _on_release(_p: Vector2) -> void:
	if state != "ad" or swiped:
		return
	var p := press_p
	if DOT_HIT.has_point(p):
		_close_ad()
	elif SKIP_RECT.has_point(p):
		if _remain() <= 0:
			_close_ad()
		else:
			skip_shake = t
			Sfx.play("buzz")
	elif X_RECT.has_point(p):
		_jump()


# ---------------------------------------------------------------- 绘制

func _draw() -> void:
	match backdrop:
		"ad":
			_draw_ad()
		"shop":
			_draw_shop()
		"home":
			_draw_home()
	if pop != "":
		_draw_dialog()
	if guess_t >= 0.0:
		_draw_guess()
	if toast != "" and t - toast_t < 1.4:
		var a := clampf((1.4 - (t - toast_t)) / 0.3, 0.0, 1.0)
		var w := text_w(toast, 15) + 32.0
		box(Rect2(W / 2 - w / 2, 520, w, 38), Color(0.17, 0.15, 0.14, 0.88 * a), 19.0, 0)
		text(toast, Vector2(W / 2, 539), 15, Color(1, 1, 1, a))
	draw_bubbles()


func _gradient(top: Color, bottom: Color) -> void:
	var r := Rect2(0, view_top, W, view_bottom - view_top)
	draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]),
		PackedColorArray([top, top, bottom, bottom]))


func _app_icon(c: Vector2, size: float, col: Color, glyph: String, fast := false) -> void:
	box_shadow(Rect2(c - Vector2(size, size) / 2.0, Vector2(size, size)), col, size * 0.24, 2.0)
	var light := col.get_luminance() > 0.7
	text(glyph, c + Vector2(0, 1), int(size * 0.46), INK if light else Color.WHITE)
	if fast:
		box(Rect2(c.x - size / 2.0 + 4, c.y + size / 2.0 - 15, size - 8, 13), Color("ffd447"), 4.0, 1.5)
		text("极速版", Vector2(c.x, c.y + size / 2.0 - 8.5), 9, INK)


func _draw_ad() -> void:
	_gradient(Color("e8453c"), Color("ff9a3c"))
	# 装饰光芒
	for i in 12:
		var a := i * TAU / 12.0 + t * 0.15
		var pts := PackedVector2Array([Vector2(187.5, 300), Vector2(187.5, 300) + Vector2(cos(a - 0.12), sin(a - 0.12)) * 420.0, Vector2(187.5, 300) + Vector2(cos(a + 0.12), sin(a + 0.12)) * 420.0])
		draw_colored_polygon(pts, Color(1, 1, 1, 0.06))
	box(Rect2(130, 52, 115, 32), Color.WHITE, 16.0, 0)
	text(app_name, Vector2(187.5, 68), 17, RED)
	text("双十一 · 爆款直降", Vector2(189.5, 131), 30, Color(0.5, 0.1, 0.05, 0.35))
	text("双十一 · 爆款直降", Vector2(187.5, 128), 30, Color.WHITE)
	text("全场低至 1 折", Vector2(187.5, 172), 18, Color("fff2a8"))
	# 礼盒 + 中央的“×”
	var bob := sin(t * 3.0) * 3.0
	box_shadow(Rect2(107, 232 + bob, 160, 136), Color("ffd447"), 12.0, 4.0)
	draw_rect(Rect2(178, 232 + bob, 20, 136), Color("e8453c"))
	draw_rect(Rect2(107, 290 + bob, 160, 18), Color("e8453c"))
	box(Rect2(97, 220 + bob, 180, 26), Color("ffe58a"), 8.0)
	circle(X_RECT.get_center(), 32, Color(1, 1, 1, 0.92), 2.5)
	var xc := X_RECT.get_center()
	line(xc + Vector2(-12, -12), xc + Vector2(12, 12), INK, 4.0)
	line(xc + Vector2(12, -12), xc + Vector2(-12, 12), INK, 4.0)
	box_shadow(BUY_RECT, Color("fff2a8"), 26.0, 4.0)
	text("立即抢购", BUY_RECT.get_center(), 22, RED)
	text("广告", Vector2(30, 584), 14, Color(1, 1, 1, 0.55), false)
	# 跳过
	var sx := 0.0
	if t - skip_shake < 0.3:
		sx = sin((t - skip_shake) * 60.0) * 4.0
	var r := Rect2(SKIP_RECT.position + Vector2(sx, 0), SKIP_RECT.size)
	box(r, Color(0, 0, 0, 0.35), 14.0, 0)
	var n := _remain()
	text("跳过 %d" % n if n > 0 else "跳过", r.get_center(), 14, Color(1, 1, 1, 0.75 if n > 0 else 1.0))
	# 灰色小点
	draw_circle(DOT_C, 5, Color(0.55, 0.55, 0.55, 0.55), true, -1.0, true)


func _draw_shop() -> void:
	fill_screen(Color("f5f3f0"))
	draw_rect(Rect2(0, view_top, W, 64 - view_top), RED)
	text(app_name, Vector2(44, 32), 18, Color.WHITE)
	box(Rect2(84, 16, 274, 32), Color.WHITE, 16.0, 0)
	text("搜索：怎么关掉广告", Vector2(104, 32), 14, SOFT, false, HORIZONTAL_ALIGNMENT_LEFT)
	box(Rect2(16, 78, 343, 104), Color("ff8a3d"), 14.0)
	text("限时秒杀", Vector2(36, 108), 24, Color.WHITE, true, HORIZONTAL_ALIGNMENT_LEFT)
	var left := 3599 - int(t * 7.0) % 3600
	text("距结束 00:%02d:%02d" % [left / 60, left % 60], Vector2(36, 146), 15, Color("fff2a8"), false, HORIZONTAL_ALIGNMENT_LEFT)
	box(Rect2(252, 112, 92, 40), Color("fff2a8"), 20.0)
	text("马上抢", Vector2(298, 132), 16, RED)
	var cols := ["e8574a", "4fa3e0", "f2c94c", "7b5bd6", "5fb36a", "ff9f43"]
	var names := ["网红手机壳", "爆款拖鞋", "九块九耳机", "多功能锅", "抽纸 40 包", "懒人支架"]
	for i in 6:
		var c := i % 2
		var row := i / 2
		var r := Rect2(16 + c * 176, 196 + row * 126, 167, 116)
		box(r, Color.WHITE, 12.0)
		box(Rect2(r.position + Vector2(10, 10), Vector2(147, 56)), Color(cols[i]), 8.0, 0)
		text(names[i], Vector2(r.position.x + 12, r.position.y + 80), 14, INK, false, HORIZONTAL_ALIGNMENT_LEFT)
		text("¥9.9", Vector2(r.position.x + 12, r.position.y + 101), 16, RED, true, HORIZONTAL_ALIGNMENT_LEFT)
		text("已拼 10万+", Vector2(r.end.x - 10, r.position.y + 101), 14, SOFT, false, HORIZONTAL_ALIGNMENT_RIGHT)


func _draw_home() -> void:
	_gradient(Color("6a7fd8"), Color("c98bd6"))
	var jiggle := state == "dialog" or state == "home"
	for i in APPS.size():
		var col := i % 4
		var row := i / 4
		var c := Vector2(55.5 + col * 88, 80 + row * 100)
		var app: Array = APPS[i]
		if i == MY_APP:
			if icon_k <= 0.01:
				continue
			draw_set_transform(c, sin(t * 18.0) * 0.06 if jiggle else 0.0, Vector2(icon_k, icon_k))
			_app_icon(Vector2.ZERO, 56, Color(app[1]), "省")
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			if icon_k > 0.9:
				text(app[0], c + Vector2(0, 44), 14, Color.WHITE, false)
		else:
			_app_icon(c, 56, Color(app[1]), String(app[0]).substr(0, 1))
			text(app[0], c + Vector2(0, 44), 14, Color.WHITE, false)
	box(Rect2(16, 498, 343, 86), Color(1, 1, 1, 0.25), 26.0, 0)
	var dock := [["电话", "5fb36a"], ["短信", "5fb36a"], ["浏览器", "3d7be0"], ["相册", "f2c94c"]]
	for i in 4:
		_app_icon(Vector2(55.5 + i * 88, 541), 54, Color(dock[i][1]), String(dock[i][0]).substr(0, 1))


func _draw_dialog() -> void:
	fill_screen(Color(0, 0, 0, 0.45))
	var k := ease_out_back(clampf((t - pop_t) / 0.22, 0.0, 1.0))
	var c := DLG.get_center()
	draw_set_transform(c * (1.0 - k), 0.0, Vector2(k, k))
	box_shadow(DLG, PAPER, 18.0, 4.0)
	_app_icon(Vector2(187.5, 200), 52, RED, "省")
	if pop == "pop1":
		text("确定要卸载吗？", Vector2(187.5, 254), 20)
		text("卸载后将无法领取每日福利", Vector2(187.5, 284), 14, SOFT, false)
		box_shadow(BRIGHT, RED, 24.0, 4.0)
		text("再想想", BRIGHT.get_center(), 18, Color.WHITE)
		text("残忍卸载", GRAY.get_center(), 14, Color("b0a89e"), false)
	else:
		text("卸载将失去3张优惠券", Vector2(187.5, 254), 19)
		for i in 3:
			var r := Rect2(78 + i * 76, 272, 68, 34)
			box(r, Color("ffe1d6"), 6.0, 1.5, RED)
			text("¥%d" % [5, 10, 20][i], r.get_center(), 15, RED)
		box_shadow(BRIGHT, RED, 24.0, 4.0)
		text("保留优惠券", BRIGHT.get_center(), 18, Color.WHITE)
		text("仍然卸载", GRAY.get_center(), 14, Color("b0a89e"), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_guess() -> void:
	var k := ease_out(clampf((t - guess_t) / 0.35, 0.0, 1.0))
	var top := lerpf(view_bottom, 360.0, k)
	box(Rect2(0, top, W, view_bottom - top + 30), PAPER, 22.0)
	text("猜你喜欢", Vector2(24, top + 34), 20, INK, true, HORIZONTAL_ALIGNMENT_LEFT)
	text("根据你最近的卸载记录推荐", Vector2(24, top + 62), 14, SOFT, false, HORIZONTAL_ALIGNMENT_LEFT)
	_app_icon(Vector2(58, top + 122), 60, RED, "省", true)
	text(app_name + "极速版", Vector2(104, top + 108), 18, INK, true, HORIZONTAL_ALIGNMENT_LEFT)
	text("更省流量，更多优惠", Vector2(104, top + 136), 14, SOFT, false, HORIZONTAL_ALIGNMENT_LEFT)
	box_shadow(Rect2(277, top + 102, 76, 40), GREEN, 20.0, 3.0)
	text("安装", Vector2(315, top + 122), 16, Color.WHITE)
