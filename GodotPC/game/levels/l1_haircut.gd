extends LevelBase
## 第一关：只剪一次
## 理发店收银台（俯视）。按住手机拖动，松手后扫描「手机中心」下方的码。
## Tony 的手拿着办卡单，循环遮挡单次付款码（遮挡 1.5 秒，露出 0.7 秒）。
##
## 判定：
##   单次付款码露出时松手在它上面     → single
##   松手在办卡码或办卡单上           → card
##   松手位置没有任何码               → 手机弹回原位，可继续

@export_group("布局（核心区坐标，单位 px）")
@export var card_rect := Rect2(40, 280, 140, 140)       ## 办卡码
@export var single_rect := Rect2(255, 300, 80, 80)      ## 单次付款码
@export var phone_size := Vector2(90, 150)
@export var phone_start := Vector2(142, 430)            ## 手机初始位置（左上角）

@export_group("节奏")
@export var block_time := 1.5        ## 办卡单遮挡时长（秒）
@export var reveal_time := 0.7       ## 露出时长（秒）
@export var hand_speed := 900.0      ## Tony 的手移动速度（px/秒）
@export var bubble_interval := 1.8   ## Tony 气泡轮播间隔
@export var tony_lines: PackedStringArray = ["办卡打五折", "充值送护理"]

const COUNTER_Y := 232.0
const TONY := Vector2(187, 104)        ## Tony 头部中心
const TONY_SCALE := 0.72
const SHOULDER := Vector2(222, 182)
const FLYER := Vector2(112, 132)       ## 办卡单尺寸
const PACKAGES := [
	["白银卡", "¥500", "送洗发 ×3"],
	["黄金卡", "¥1000", "送头皮护理 ×5"],
	["铂金卡", "¥2000", "烫染八折"],
	["钻石卡", "¥3000", "Tony 优先预约"],
	["家庭共享卡", "¥3888", "全家共享 再送一张"],
	["烫染尊享卡", "¥4888", "头发没了也能用"],
	["至尊黑金卡", "¥6888", "Tony 终身专属服务"],
]
const ITEM_H := 74.0

var phone_pos := Vector2.ZERO
var dragging := false
var drag_off := Vector2.ZERO
var blocking := true
var cycle_t := 0.0
var flyer_c := Vector2.ZERO
var state := "play"          ## play / single / card
var mood := "grin"           ## grin / flat
var hand_out := 1.0
var zoom := 0.0
var scroll := 0.0
var line_i := 0
var next_line := 0.5
var end_scheduled := false
var _spring: Tween


func _ready() -> void:
	phone_pos = phone_start
	flyer_c = single_rect.get_center()


func cover_pos() -> Vector2:
	return single_rect.get_center()


func reveal_pos() -> Vector2:
	return Vector2(single_rect.get_center().x + 26, COUNTER_Y - 8)


func flyer_rect() -> Rect2:
	return Rect2(flyer_c - FLYER / 2.0, FLYER)


func phone_center() -> Vector2:
	return phone_pos + phone_size / 2.0


## 手机中心下方是什么码："single" / "card" / ""
func scan_target() -> String:
	var p := phone_center()
	if hand_out > 0.5 and flyer_rect().has_point(p):
		return "card"
	if single_rect.has_point(p):
		return "single"
	if card_rect.has_point(p):
		return "card"
	return ""


func _tick(delta: float) -> void:
	match state:
		"play":
			var target := cover_pos() if blocking else reveal_pos()
			flyer_c = flyer_c.move_toward(target, hand_speed * delta)
			if flyer_c.is_equal_approx(target):
				cycle_t += delta
				if cycle_t >= (block_time if blocking else reveal_time):
					blocking = not blocking
					cycle_t = 0.0
			if t > next_line:
				next_line = t + bubble_interval
				say(Vector2(78, 50), tony_lines[line_i % tony_lines.size()], bubble_interval - 0.2, TONY + Vector2(-20, 18))
				line_i += 1
		"single":
			hand_out = move_toward(hand_out, 0.0, delta * 2.5)
		"card":
			zoom = move_toward(zoom, 1.0, delta * 2.4)
			if zoom >= 1.0:
				var max_scroll := PACKAGES.size() * ITEM_H - (_list_area().size.y - 16.0)
				scroll = move_toward(scroll, max_scroll, delta * 150.0)
				if scroll >= max_scroll and not end_scheduled:
					end_scheduled = true
					Sfx.play("ding")
					later(1.4, finish.bind("card"))


# ---------------------------------------------------------------- 输入

func _on_press(p: Vector2) -> void:
	if state != "play":
		return
	if Rect2(phone_pos, phone_size).grow(8).has_point(p):
		if _spring and _spring.is_running():
			_spring.kill()
		dragging = true
		drag_off = phone_pos - p
		Sfx.play("tap")


func _on_drag(p: Vector2) -> void:
	if not dragging:
		return
	var prev := scan_target()
	phone_pos = p + drag_off
	phone_pos.x = clampf(phone_pos.x, -phone_size.x / 2.0, W - phone_size.x / 2.0)
	phone_pos.y = clampf(phone_pos.y, COUNTER_Y - phone_size.y / 2.0, H - phone_size.y / 2.0)
	if scan_target() != prev and scan_target() != "":
		Sfx.play("scan")


func _on_release(_p: Vector2) -> void:
	if not dragging:
		return
	dragging = false
	match scan_target():
		"single":
			_win()
		"card":
			_lose()
		_:
			_spring = create_tween()
			_spring.tween_property(self, "phone_pos", phone_start, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			Sfx.play("buzz")


func _win() -> void:
	state = "single"
	mood = "flat"
	Sfx.play("cash", 0.0)
	clear_bubbles()
	later(0.7, func() -> void: say(Vector2(78, 50), "……慢走。", 2.0, TONY + Vector2(-20, 18)))
	later(2.4, finish.bind("single"))


func _lose() -> void:
	state = "card"
	Sfx.play("fanfare", 0.0)
	clear_bubbles()


# ---------------------------------------------------------------- 绘制

func _draw() -> void:
	# 墙
	draw_rect(Rect2(0, view_top, W, COUNTER_Y - view_top), Color("e6eee8"))
	var x := 0.0
	while x < W:
		draw_rect(Rect2(x, view_top, 14, COUNTER_Y - view_top), Color("dce7e0"))
		x += 28.0
	box(Rect2(248, 10, 112, 32), Color("2f2f35"), 6.0)
	text("TONY 造型", Vector2(304, 26), 16, Color("ffb547"))
	_draw_pole(Rect2(16, 60, 16, 140))
	_draw_tony()

	# 柜台（俯视）
	draw_rect(Rect2(0, COUNTER_Y, W, view_bottom - COUNTER_Y), Color("d8b48a"))
	var gy := COUNTER_Y + 26.0
	while gy < view_bottom:
		draw_line(Vector2(0, gy), Vector2(W, gy + 6), Color(0.6, 0.42, 0.26, 0.18), 2.0)
		gy += 46.0
	box(Rect2(-6, COUNTER_Y - 6, W + 12, 14), Color("efe1c8"), 3.0)

	# 办卡码立牌
	box_shadow(Rect2(card_rect.position - Vector2(8, 30), card_rect.size + Vector2(16, 38)), Color("f3cf72"), 10.0, 3.0)
	text("办卡享五折", Vector2(card_rect.get_center().x, card_rect.position.y - 15), 15, Color("8a2a1a"))
	qr(card_rect, Color("6a1d14"), 5)
	# 单次付款码
	var sr := Rect2(single_rect.position - Vector2(8, 30), single_rect.size + Vector2(16, 38))
	box_shadow(sr, PAPER, 10.0, 3.0)
	box(Rect2(sr.position, Vector2(sr.size.x, 24)), GREEN, 8.0)
	text("单次 ¥38", Vector2(sr.get_center().x, sr.position.y + 12), 14, Color.WHITE)
	qr(single_rect, Color("1f3d2f"), 7)

	# Tony 的手 + 办卡单
	if hand_out > 0.02:
		_draw_hand()

	# 手机
	if state == "card" and zoom > 0.0:
		_draw_big_phone()
	else:
		_draw_phone()

	draw_bubbles()


func _draw_pole(r: Rect2) -> void:
	box(Rect2(r.position.x - 3, r.position.y - 10, r.size.x + 6, 10), Color("c9ccd1"), 4.0)
	box(Rect2(r.position.x - 3, r.end.y, r.size.x + 6, 10), Color("c9ccd1"), 4.0)
	draw_rect(r, Color.WHITE)
	var off := fmod(t * 30.0, 28.0)
	var i := 0
	while i * 14.0 < r.size.y + 28.0:
		var yy := r.position.y + i * 14.0 - off
		if yy >= r.position.y and yy + 14.0 <= r.end.y:
			var col := RED if i % 2 == 0 else Color("3f6fb5")
			draw_colored_polygon(PackedVector2Array([Vector2(r.position.x, yy + 8), Vector2(r.end.x, yy), Vector2(r.end.x, yy + 6), Vector2(r.position.x, yy + 14)]), col)
		i += 1
	box(r, Color(0, 0, 0, 0), 4.0)


func _draw_tony() -> void:
	draw_set_transform(TONY, 0.0, Vector2(TONY_SCALE, TONY_SCALE))
	# 身体
	box(Rect2(-85, 58, 170, 240), Color("f7f7f4"), 46.0, 2.8)
	box(Rect2(-63, 94, 126, 210), Color("2f2f35"), 16.0, 2.8)
	line(Vector2(-56, 98), Vector2(-44, 64), Color("2f2f35"), 6.0)
	line(Vector2(56, 98), Vector2(44, 64), Color("2f2f35"), 6.0)
	box(Rect2(12, 112, 44, 19), Color("e0b84a"), 3.0, 2.0)
	text("TONY", Vector2(34, 121.5), 12, INK)
	box(Rect2(-14, 32, 28, 32), SKIN, 8.0, 2.8)
	circle(Vector2(-46, 10), 9, SKIN, 2.8)
	circle(Vector2(46, 10), 9, SKIN, 2.8)
	circle(Vector2.ZERO, 46, SKIN, 2.8)
	# 发型
	var hair := PackedVector2Array([Vector2(-47, -2)])
	hair.append_array(bez3(Vector2(-47, -2), Vector2(-54, -60), Vector2(-12, -82), Vector2(18, -82)))
	hair.append_array(bez3(Vector2(18, -82), Vector2(40, -120), Vector2(86, -118), Vector2(80, -86)))
	hair.append_array(bez3(Vector2(80, -86), Vector2(70, -72), Vector2(60, -60), Vector2(54, -50), 6))
	hair.append_array(bez3(Vector2(54, -50), Vector2(52, -30), Vector2(49, -16), Vector2(46, -4), 6))
	hair.append_array(bez2(Vector2(46, -4), Vector2(30, -34), Vector2(0, -34), 8))
	hair.append_array(bez2(Vector2(0, -34), Vector2(-30, -32), Vector2(-47, -2), 8))
	hair.remove_at(hair.size() - 1)
	shape(hair, GOLD, 2.8)
	var streak1 := PackedVector2Array([Vector2(-28, -42)])
	streak1.append_array(bez2(Vector2(-28, -42), Vector2(10, -82), Vector2(60, -100)))
	draw_polyline(streak1, Color("c47d1d"), 2.5, true)
	var streak2 := PackedVector2Array([Vector2(-8, -36)])
	streak2.append_array(bez2(Vector2(-8, -36), Vector2(26, -66), Vector2(64, -82)))
	draw_polyline(streak2, Color("c47d1d"), 2.5, true)
	# 脸
	var ex := clampf((phone_center().x - TONY.x) / 180.0, -1.0, 1.0) * 4.5
	var ey := clampf((phone_center().y - TONY.y) / 400.0, -1.0, 1.0) * 2.5
	circle(Vector2(-28, 24), 8, Color(0.9, 0.47, 0.47, 0.3), 0)
	circle(Vector2(28, 24), 8, Color(0.9, 0.47, 0.47, 0.3), 0)
	ellipse(Vector2(-17, 6), 10, 8, Color.WHITE, 2.0)
	ellipse(Vector2(17, 6), 10, 8, Color.WHITE, 2.0)
	if mood == "flat":
		circle(Vector2(-17 + ex, 8), 4, INK, 0)
		circle(Vector2(17 + ex, 8), 4, INK, 0)
		draw_rect(Rect2(-29, -3, 24, 8), SKIN)
		draw_rect(Rect2(5, -3, 24, 8), SKIN)
		line(Vector2(-28, 5), Vector2(-6, 5), INK, 3.0)
		line(Vector2(6, 5), Vector2(28, 5), INK, 3.0)
		line(Vector2(-28, -13), Vector2(-8, -13), INK, 3.0)
		line(Vector2(8, -13), Vector2(28, -13), INK, 3.0)
		line(Vector2(-16, 34), Vector2(16, 34), INK, 3.0)
	else:
		circle(Vector2(-17 + ex, 6 + ey), 4.5, INK, 0)
		circle(Vector2(17 + ex, 6 + ey), 4.5, INK, 0)
		draw_arc(Vector2(-17, -6), 10, PI * 1.15, PI * 1.85, 10, INK, 3.0, true)
		draw_arc(Vector2(17, -6), 10, PI * 1.15, PI * 1.85, 10, INK, 3.0, true)
		var mouth := PackedVector2Array([Vector2(-25, 22)])
		mouth.append_array(bez2(Vector2(-25, 22), Vector2(0, 62), Vector2(25, 22), 12))
		shape(mouth, Color("7a2a2a"), 2.8)
		box(Rect2(-21, 22, 42, 9), Color.WHITE, 3.0, 1.5)
		var tw := 0.5 + 0.5 * sin(t * 5.0)
		var star := PackedVector2Array()
		for k in 8:
			var rr := 2.5 if k % 2 == 1 else 8.0
			var a := k * PI / 4.0
			star.append(Vector2(28, 20) + Vector2(cos(a), sin(a)) * rr)
		shape(star, Color(1, 1, 1, tw), 1.5, Color(INK, tw))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_hand() -> void:
	var c := SHOULDER.lerp(flyer_c, hand_out)
	var hand := c - Vector2(0, FLYER.y / 2.0 - 8.0) * hand_out
	draw_line(SHOULDER, hand, INK, 22.0, true)
	draw_line(SHOULDER, hand, Color("f7f7f4"), 17.0, true)
	if hand_out > 0.3:
		var r := Rect2(c - FLYER / 2.0 * hand_out, FLYER * hand_out)
		var s := hand_out
		box_shadow(r, Color("f3d27a"), 10.0 * s, 3.0 * s)
		draw_rect(Rect2(r.position + Vector2(6, 6) * s, r.size - Vector2(12, 12) * s), Color(0.47, 0.24, 0.08, 0.5), false, 1.5)
		if s > 0.9:
			text("VIP 尊享卡", Vector2(c.x, r.position.y + 22), 15, Color("8a2a1a"))
			qr(Rect2(c.x - 30, r.position.y + 40, 60, 60), Color("6a1d14"), 3)
			text("充值送护理", Vector2(c.x, r.position.y + 116), 14, Color("8a2a1a"))
	circle(hand, 11, SKIN, 2.5)


func _draw_phone() -> void:
	var r := Rect2(phone_pos, phone_size)
	if dragging:
		draw_style_box(_sb(Color(0, 0, 0, 0.18), 16, 0, INK), Rect2(r.position + Vector2(6, 10), r.size))
	box_shadow(r, Color("2a2a30"), 14.0, 3.0)
	circle(Vector2(r.get_center().x, r.position.y + 8), 2.5, Color("55555c"), 0)
	var scr := Rect2(r.position + Vector2(6, 16), r.size - Vector2(12, 30))
	var tg := scan_target() if state == "play" else ""
	var c := r.get_center()
	if state == "single":
		box(scr, GREEN, 7.0, 0)
		check_mark(c + Vector2(0, -18), 18, Color.WHITE, 5.0)
		text("支付成功", c + Vector2(0, 14), 14, Color.WHITE)
		text("¥38", c + Vector2(0, 36), 16, Color.WHITE)
		return
	var col := Color("dfe7ef")
	if tg == "single":
		col = Color("def5e8")
	elif tg == "card":
		col = Color("fff0c8")
	box(scr, col, 7.0, 0)
	var rc := Color("7e95ad")
	var label := "扫一扫"
	if tg == "single":
		rc = GREEN
		label = "单次付款"
	elif tg == "card":
		rc = Color("c0711d")
		label = "办卡"
	var k := 14.0
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			var corner: Vector2 = c + Vector2(sx, sy) * k
			draw_line(corner, corner - Vector2(sx * 6.0, 0), rc, 3.0, true)
			draw_line(corner, corner - Vector2(0, sy * 6.0), rc, 3.0, true)
	circle(c, 2.5, rc, 0)
	text(label, c + Vector2(0, 34), 14, rc)


func _list_area() -> Rect2:
	return Rect2(28, 86, 319, 486)


func _draw_big_phone() -> void:
	var e := ease_out(zoom)
	var small := Rect2(phone_pos, phone_size)
	var big := Rect2(14, 14, 347, 572)
	var r := Rect2(small.position.lerp(big.position, e), small.size.lerp(big.size, e))
	box_shadow(r, Color("2a2a30"), lerpf(14, 28, e), 4.0, 3.0)
	var scr := Rect2(r.position + Vector2(8, 16), r.size - Vector2(16, 30))
	box(scr, Color("fff6df"), lerpf(7, 16, e), 0)
	if e < 0.6:
		return
	var a := clampf((e - 0.6) / 0.4, 0.0, 1.0)
	var area := _list_area()
	for i in PACKAGES.size():
		var it: Array = PACKAGES[i]
		var ir := Rect2(area.position.x + 8, area.position.y + 8 + i * ITEM_H - scroll, area.size.x - 16, ITEM_H - 10)
		var clipped := ir.intersection(area)
		if clipped.size.y <= 2:
			continue
		var last := i == PACKAGES.size() - 1
		box(clipped, Color("2b2724", a) if last else Color(1, 0.99, 0.96, a), 12.0, 2.0, Color(0.84, 0.71, 0.48, a))
		if area.has_point(Vector2(ir.position.x + 10, ir.position.y + 22)) and area.has_point(Vector2(ir.position.x + 10, ir.position.y + 48)):
			var name_col := Color("ffd479") if last else Color("8a2a1a")
			text("【%s】" % it[0], Vector2(ir.position.x + 8, ir.position.y + 22), 17, Color(name_col, a), true, HORIZONTAL_ALIGNMENT_LEFT)
			text(it[2], Vector2(ir.position.x + 16, ir.position.y + 46), 14, Color(Color("d8cbb4") if last else SOFT, a), false, HORIZONTAL_ALIGNMENT_LEFT)
			text(it[1], Vector2(ir.end.x - 14, ir.position.y + 32), 20, Color(Color("ffd479") if last else RED, a), true, HORIZONTAL_ALIGNMENT_RIGHT)
	box(Rect2(scr.position.x, scr.position.y, scr.size.x, 56), Color(0.71, 0.4, 0.11, a), 14.0, 0)
	text("TONY 会员中心", Vector2(W / 2, scr.position.y + 28), 18, Color(1, 1, 1, a))
