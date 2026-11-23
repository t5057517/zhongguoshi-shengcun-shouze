class_name LevelBase
extends Node2D
## 所有关卡（以及标题/过场画面）的基类。
##
## 坐标系 = 核心交互区 375x600，左上角为 (0,0)，与《关卡策划案》里的坐标一一对应。
## 背景要画满屏幕时，用 view_top / view_bottom（可能超出 0~600）。
##
## 子类常用写法：
##   func _tick(delta)          每帧逻辑
##   func _draw()               画画面（结尾调用 draw_bubbles() 画对话气泡）
##   func _on_press(p) / _on_drag(p) / _on_release(p)   触摸 / 鼠标（p 为核心区坐标）
##   later(秒, 函数)            延时执行（演出编排用）
##   finish("result_id")        结果演出结束后调用，进入黑屏 → 关卡标题卡

signal finished(result_id: String)

const W := 375.0
const H := 600.0

# —— 配色（全游戏统一）——
const INK := Color("2b2724")
const PAPER := Color("fffdf8")
const SOFT := Color("8a8178")
const RED := Color("d9483b")
const GREEN := Color("22a06b")
const GOLD := Color("e9a23b")
const SKIN := Color("f3d3b8")
const BG := Color("f4efe6")

const FONT: Font = preload("res://game/fonts/ui_font.tres")
const FONT_BOLD: Font = preload("res://game/fonts/ui_font_bold.tres")

var t := 0.0                 ## 本关已进行的秒数
var view_top := 0.0          ## 屏幕可见区域上边界（核心区坐标，通常为负数）
var view_bottom := H         ## 屏幕可见区域下边界
var done := false
var input_locked := false

var _timers: Array = []
var _bubbles: Array = []
var _pressing := false
var _sb_cache := {}


func _process(delta: float) -> void:
	t += delta
	var i := 0
	while i < _timers.size():
		var item: Array = _timers[i]
		if t >= float(item[0]):
			_timers.remove_at(i)
			var fn: Callable = item[1]
			if fn.is_valid():
				fn.call()
		else:
			i += 1
	_tick(delta)
	queue_redraw()


func _tick(_delta: float) -> void:
	pass


## 延时执行（秒）
func later(sec: float, fn: Callable) -> void:
	_timers.append([t + sec, fn])


## 判定完成（结果演出结束后调用）
func finish(result_id: String) -> void:
	if done:
		return
	done = true
	input_locked = true
	finished.emit(result_id)


# ---------------------------------------------------------------- 输入

func _unhandled_input(event: InputEvent) -> void:
	if input_locked or done:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var p := _local(event)
		if event.pressed:
			_pressing = true
			_on_press(p)
		elif _pressing:
			_pressing = false
			_on_release(p)
	elif event is InputEventMouseMotion and _pressing:
		_on_drag(_local(event))


func _local(event: InputEvent) -> Vector2:
	var e := make_input_local(event)
	if e is InputEventMouse:
		return (e as InputEventMouse).position
	return Vector2.ZERO


func _on_press(_p: Vector2) -> void:
	pass


func _on_drag(_p: Vector2) -> void:
	pass


func _on_release(_p: Vector2) -> void:
	pass


# ---------------------------------------------------------------- 绘图工具

func fill_screen(col: Color) -> void:
	draw_rect(Rect2(0, view_top, W, view_bottom - view_top), col)


func _sb(fill: Color, radius: float, bw: float, bc: Color) -> StyleBoxFlat:
	var key := "%s|%d|%d|%s" % [fill.to_html(), int(radius), int(bw), bc.to_html()]
	if _sb_cache.has(key):
		return _sb_cache[key]
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_corner_radius_all(int(radius))
	sb.set_border_width_all(int(bw))
	sb.border_color = bc
	sb.anti_aliasing = true
	sb.corner_detail = 10
	_sb_cache[key] = sb
	return sb


## 圆角矩形（带描边）
func box(r: Rect2, fill: Color, radius := 10.0, bw := 2.0, bc := INK) -> void:
	draw_style_box(_sb(fill, radius, bw, bc), r)


## 圆角矩形 + 底部实心阴影（按钮 / 卡片）
func box_shadow(r: Rect2, fill: Color, radius := 10.0, drop := 3.0, bw := 2.0) -> void:
	draw_style_box(_sb(INK, radius, 0, INK), Rect2(r.position + Vector2(0, drop), r.size))
	box(r, fill, radius, bw)


func circle(c: Vector2, r: float, fill: Color, bw := 2.0, bc := INK) -> void:
	if fill.a > 0.0:
		draw_circle(c, r, fill, true, -1.0, true)
	if bw > 0.0:
		draw_arc(c, r, 0.0, TAU, 40, bc, bw, true)


func ellipse_pts(c: Vector2, rx: float, ry: float, rot := 0.0, n := 36) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * float(i) / float(n)
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry).rotated(rot))
	return pts


## 任意多边形（填充 + 描边）
func shape(pts: PackedVector2Array, fill: Color, bw := 2.0, bc := INK) -> void:
	if pts.size() < 3:
		return
	if fill.a > 0.0:
		draw_colored_polygon(pts, fill)
	if bw > 0.0:
		var closed := pts.duplicate()
		closed.append(pts[0])
		draw_polyline(closed, bc, bw, true)


func ellipse(c: Vector2, rx: float, ry: float, fill: Color, bw := 2.0, rot := 0.0) -> void:
	shape(ellipse_pts(c, rx, ry, rot), fill, bw)


func line(a: Vector2, b: Vector2, col := INK, w := 2.0) -> void:
	draw_line(a, b, col, w, true)


## 三次贝塞尔采样点
func bez3(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, n := 10) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(1, n + 1):
		var u := float(i) / float(n)
		var v := 1.0 - u
		pts.append(p0 * v * v * v + p1 * 3.0 * v * v * u + p2 * 3.0 * v * u * u + p3 * u * u * u)
	return pts


## 二次贝塞尔采样点
func bez2(p0: Vector2, p1: Vector2, p2: Vector2, n := 10) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(1, n + 1):
		var u := float(i) / float(n)
		var v := 1.0 - u
		pts.append(p0 * v * v + p1 * 2.0 * v * u + p2 * u * u)
	return pts


func text_w(s: String, size := 16, bold := true) -> float:
	var f: Font = FONT_BOLD if bold else FONT
	return f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


## 文字：pos 为对齐点（默认水平居中、垂直居中）
func text(s: String, pos: Vector2, size := 16, col := INK, bold := true, align := HORIZONTAL_ALIGNMENT_CENTER) -> void:
	var f: Font = FONT_BOLD if bold else FONT
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var x := pos.x
	if align == HORIZONTAL_ALIGNMENT_CENTER:
		x -= w / 2.0
	elif align == HORIZONTAL_ALIGNMENT_RIGHT:
		x -= w
	var base := pos.y + (f.get_ascent(size) - f.get_descent(size)) / 2.0
	draw_string(f, Vector2(x, base), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


## 对话气泡。tail_to 为尾巴指向的点（null = 没有尾巴）
func bubble(center: Vector2, s: String, size := 15, tail_to: Variant = null, sc := 1.0, alpha := 1.0, fill := PAPER) -> void:
	var lines := s.split("\n")
	var w := 0.0
	for l in lines:
		w = maxf(w, text_w(l, size))
	var pad := 9.0
	var lh := size * 1.3
	var bw := w + pad * 2.0
	var bh := lines.size() * lh + pad * 1.2
	var ink := Color(INK, INK.a * alpha)
	var f := Color(fill, fill.a * alpha)
	draw_set_transform(center, 0.0, Vector2(sc, sc))
	var has_tail := tail_to != null
	var bx := 0.0
	var by := 0.0
	var tip := Vector2.ZERO
	var below := true
	if has_tail:
		var tp: Vector2 = (tail_to as Vector2) - center
		below = tp.y > 0.0
		by = bh / 2.0 - 1.0 if below else -bh / 2.0 + 1.0
		bx = clampf(tp.x * 0.5, -bw / 2.0 + 14.0, bw / 2.0 - 14.0)
		tip = Vector2(bx, by) + (tp - Vector2(bx, by)).limit_length(15.0)
		var tri := PackedVector2Array([Vector2(bx - 7, by), tip, Vector2(bx + 7, by)])
		draw_colored_polygon(tri, f)
		draw_polyline(tri, ink, 2.0, true)
	box(Rect2(-bw / 2.0, -bh / 2.0, bw, bh), f, minf(12.0, bh / 2.0), 2.0, ink)
	if has_tail:
		var yy := by + (-3.0 if below else 3.0)
		draw_colored_polygon(PackedVector2Array([Vector2(bx - 5, yy), Vector2(bx + 5, yy), Vector2(bx, by).lerp(tip, 0.5)]), f)
	for i in lines.size():
		text(lines[i], Vector2(0, -bh / 2.0 + pad * 0.6 + lh * (i + 0.5)), size, ink)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## 添加一个会自动弹出/消失的气泡。life < 0 表示一直显示。
func say(pos: Vector2, s: String, life := 2.0, tail_to: Variant = null, size := 15) -> Dictionary:
	var b := {"pos": pos, "text": s, "life": life, "tail": tail_to, "born": t, "size": size}
	_bubbles.append(b)
	Sfx.play("pop")
	return b


func clear_bubbles() -> void:
	for b in _bubbles:
		var age: float = t - float(b["born"])
		if float(b["life"]) < 0.0 or float(b["life"]) > age + 0.15:
			b["life"] = age + 0.15


func draw_bubbles() -> void:
	var keep: Array = []
	for b in _bubbles:
		var age: float = t - float(b["born"])
		var life: float = b["life"]
		if life >= 0.0 and age > life:
			continue
		keep.append(b)
		var a := 1.0
		if life >= 0.0 and life - age < 0.18:
			a = maxf(0.0, (life - age) / 0.18)
		bubble(b["pos"], b["text"], b["size"], b["tail"], ease_out_back(clampf(age / 0.2, 0.0, 1.0)), a)
	_bubbles = keep


## 装饰用伪二维码（随机图案，不可识别）
func qr(r: Rect2, col: Color, seed_val: int) -> void:
	draw_rect(r, Color.WHITE)
	var n := 11
	var c := r.size.x / float(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	for i in n:
		for j in n:
			var finder := (i < 3 and j < 3) or (i > n - 4 and j < 3) or (i < 3 and j > n - 4)
			if finder:
				continue
			if rng.randf() < 0.45:
				draw_rect(Rect2(r.position + Vector2(i * c, j * c), Vector2(c + 0.3, c + 0.3)), col)
	for fp in [Vector2(0, 0), Vector2(n - 3, 0), Vector2(0, n - 3)]:
		var p: Vector2 = r.position + (fp as Vector2) * c
		draw_rect(Rect2(p, Vector2(3, 3) * c), col)
		draw_rect(Rect2(p + Vector2(0.55, 0.55) * c, Vector2(1.9, 1.9) * c), Color.WHITE)
		draw_rect(Rect2(p + Vector2(1, 1) * c, Vector2(1, 1) * c), col)


## 勾号
func check_mark(c: Vector2, s: float, col: Color, w := 5.0) -> void:
	draw_polyline(PackedVector2Array([c + Vector2(-0.6, 0) * s, c + Vector2(-0.15, 0.45) * s, c + Vector2(0.7, -0.5) * s]), col, w, true)


# ---------------------------------------------------------------- 缓动

static func ease_out(x: float) -> float:
	return 1.0 - pow(1.0 - clampf(x, 0.0, 1.0), 3.0)


static func ease_out_back(x: float) -> float:
	var c1 := 1.70158
	var c3 := c1 + 1.0
	return 1.0 + c3 * pow(x - 1.0, 3.0) + c1 * pow(x - 1.0, 2.0)
