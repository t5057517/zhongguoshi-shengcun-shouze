class_name Screens
extends LevelBase
## 非关卡画面：标题 / 黑屏 / 关卡标题卡 / 生存报告 / “请竖屏游玩”遮罩
## 由 game.gd 控制，点击后通过 action 信号通知 game.gd。

signal action(action_name: String, arg: int)

var game = null            ## game.gd（动态访问 results / LEVELS / verdict）
var mode := "none"           ## none / title / black / card / summary
var mode_t := 0.0
var portrait_warning := false
var card := {}
var _buttons: Array = []     ## [Rect2, action, arg]


func set_mode(m: String) -> void:
	mode = m
	mode_t = t
	_pressing = false


func show_card(no: String, title: String, result: String, quote: String, grade: String) -> void:
	card = {"no": no, "title": title, "result": result, "quote": quote, "grade": grade}
	set_mode("card")
	Sfx.play("thud")


func _on_press(p: Vector2) -> void:
	if portrait_warning:
		return
	if mode == "card":
		if t - mode_t > 0.35:
			Sfx.play("tap")
			set_mode("black")
			action.emit("continue", 0)
		return
	if mode == "title" or mode == "summary":
		for b in _buttons:
			var r: Rect2 = b[0]
			if r.has_point(p):
				Sfx.play("tap")
				get_viewport().set_input_as_handled()
				action.emit(b[1], b[2])
				return


func _btn(r: Rect2, label: String, act: String, arg := 0, accent := false, size := 20) -> void:
	_buttons.append([r, act, arg])
	box_shadow(r, RED if accent else PAPER, 14.0, 4.0)
	text(label, r.get_center(), size, Color.WHITE if accent else INK)


func _draw() -> void:
	_buttons.clear()
	match mode:
		"title":
			_draw_title()
		"black":
			fill_screen(Color.BLACK)
		"card":
			_draw_card()
		"summary":
			_draw_summary()
	if portrait_warning:
		_draw_portrait_warning()


func _draw_title() -> void:
	fill_screen(BG)
	var y := view_top + 14.0
	while y < view_bottom:
		var x := 14.0
		while x < W:
			draw_circle(Vector2(x, y), 1.6, Color(0, 0, 0, 0.05))
			x += 30.0
		y += 30.0
	text("中国式", Vector2(W / 2, 72), 24)
	draw_set_transform(Vector2(W / 2, 135), -0.025, Vector2.ONE)
	box_shadow(Rect2(-140, -42, 280, 84), RED, 14.0, 5.0, 3.0)
	text("生存守则", Vector2(0, 2), 52, Color("fff6ea"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	text("四个关于“套路”的小场面", Vector2(W / 2, 205), 15, SOFT, false)
	var heads := [[72.0, "办张卡？", Color("f7f7f4"), GOLD], [187.5, "确定卸载？", Color("c9668a"), Color("5a3466")], [303.0, "回T退订", Color("4a78b8"), INK]]
	for i in heads.size():
		var h: Array = heads[i]
		var x: float = h[0]
		var bob := sin(t * 2.0 + i * 1.3) * 3.0
		box(Rect2(x - 24, 318, 48, 44), h[2], 18.0)
		circle(Vector2(x, 300), 20, SKIN)
		var cap := PackedVector2Array()
		for k in range(19):
			var a := PI + PI * float(k) / 18.0
			cap.append(Vector2(x, 300) + Vector2(cos(a), sin(a)) * 21.0)
		cap.append_array(bez2(Vector2(x + 21, 300), Vector2(x, 292), Vector2(x - 21, 300), 8))
		shape(cap, h[3])
		circle(Vector2(x - 7, 304), 2.4, INK, 0)
		circle(Vector2(x + 7, 304), 2.4, INK, 0)
		bubble(Vector2(x, 248 + bob), h[1], 15, Vector2(x, 278))
	_btn(Rect2(87.5, 385, 200, 56), "开始", "start", 0, true, 26)
	for i in 4:
		_btn(Rect2(24 + i * 84, 462, 72, 46), "第%d关" % (i + 1), "level", i, false, 15)
	var n := 0
	if game:
		n = game.results.size()
	text("已记录结果 %d / 4" % n, Vector2(W / 2, 535), 14, SOFT, false)
	text("Esc 回标题 · R 重开本关", Vector2(W / 2, 565), 14, Color(SOFT, 0.7), false)


func _draw_card() -> void:
	fill_screen(Color.BLACK)
	var a := clampf((t - mode_t) / 0.3, 0.0, 1.0)
	var lift := (1.0 - ease_out(a)) * 14.0
	var white := Color(1, 1, 1, a)
	text(card.get("no", ""), Vector2(W / 2, 185 + lift), 16, Color(0.6, 0.58, 0.55, a), false)
	text(card.get("title", ""), Vector2(W / 2, 232 + lift), 32, white)
	draw_line(Vector2(W / 2 - 40, 272 + lift), Vector2(W / 2 + 40, 272 + lift), Color(1, 1, 1, 0.25 * a), 2.0)
	var col := GOLD
	if card.get("grade", "") == "bad":
		col = Color("ff7a6a")
	elif card.get("grade", "") == "good":
		col = Color("7fd6a2")
	text(card.get("result", ""), Vector2(W / 2, 310 + lift), 26, Color(col, a))
	text(card.get("quote", ""), Vector2(W / 2, 352 + lift), 15, Color(0.85, 0.82, 0.78, a), false)
	var blink := 0.45 + 0.45 * sin((t - mode_t) * 4.0)
	if t - mode_t > 0.35:
		text("点击任意处继续", Vector2(W / 2, 480), 14, Color(1, 1, 1, blink), false)


func _draw_summary() -> void:
	fill_screen(BG)
	text("今日生存报告", Vector2(W / 2, 44), 28)
	if game == null:
		return
	var levels: Array = game.LEVELS
	var res: Dictionary = game.results
	var info: Dictionary = game.RESULTS
	for i in levels.size():
		var l: Dictionary = levels[i]
		var r := Rect2(20, 80 + i * 98, 335, 88)
		box(r, PAPER, 14.0)
		text("%s · %s" % [l["no"], l["title"]], Vector2(36, r.position.y + 20), 14, SOFT, false, HORIZONTAL_ALIGNMENT_LEFT)
		var id: String = res.get(l["key"], "")
		if id == "":
			text("（未游玩）", Vector2(36, r.position.y + 54), 18, Color("bdb4a8"), true, HORIZONTAL_ALIGNMENT_LEFT)
			continue
		var it: Array = info.get(id, [id, "", "mid"])
		text(it[0], Vector2(36, r.position.y + 48), 20, INK, true, HORIZONTAL_ALIGNMENT_LEFT)
		text(it[1], Vector2(36, r.position.y + 72), 14, RED, false, HORIZONTAL_ALIGNMENT_LEFT)
		text("result_id: " + id, Vector2(340, r.position.y + 20), 14, Color(SOFT, 0.7), false, HORIZONTAL_ALIGNMENT_RIGHT)
	text(game.verdict(), Vector2(W / 2, 485), 17, INK)
	_btn(Rect2(24, 520, 156, 54), "再来一次", "start", 0, true, 20)
	_btn(Rect2(195, 520, 156, 54), "返回标题", "title", 0, false, 20)


func _draw_portrait_warning() -> void:
	fill_screen(Color(0.08, 0.07, 0.06, 0.96))
	var c := Vector2(W / 2, (view_top + view_bottom) / 2.0 - 30)
	var ang := sin(t * 2.0) * 0.5 - 0.5
	draw_set_transform(c, ang, Vector2.ONE)
	box(Rect2(-22, -38, 44, 76), Color(0, 0, 0, 0), 8.0, 3.0, Color.WHITE)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	text("请竖屏游玩", c + Vector2(0, 70), 18, Color.WHITE)
