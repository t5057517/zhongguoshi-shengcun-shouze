extends LevelBase
## 第四关：回T退订
## 游戏内短信页。输入框已预填“T”，只能点“发送”(56x44)；每次发送后自动重新填入“T”。
## 回复每条间隔 0.4 秒：
##   第1次：退订成功 / 感谢关注 / 新品上架，回T查看
##   第2次：已为您查看新品 / 回T订阅会员日提醒
##   第3次：您已订阅全部服务（发送按钮置灰）
## 判定：发送 1 次后等待 5 秒 → once；发送 3 次 → all_in；判定后停留 1.5 秒
## （补充：发送 2 次后等待 5 秒 → reminder）

@export var reply_gap := 0.4
@export var idle_wait := 5.0
@export var end_hold := 1.5
@export var sender := "1069 0888 0001"

const SEND_RECT := Rect2(305, 540, 56, 44)
const INPUT_RECT := Rect2(14, 540, 283, 44)
const LIST_TOP := 70.0
const LIST_BOTTOM := 522.0
const ROW_H := 50.0
const REPLIES := [
	["退订成功", "感谢关注", "新品上架，回T查看"],
	["已为您查看新品", "回T订阅会员日提醒"],
	["您已订阅全部服务"],
]

var msgs: Array = []         ## [{me, text, born}]
var sends := 0
var busy := false
var input_text := "T"
var last_send := -1.0
var judged := false
var scroll := 0.0


func _ready() -> void:
	msgs.append({"me": false, "text": "【省省乐】会员日全场5折", "born": -1.0})
	msgs.append({"me": false, "text": "回T退订", "born": -1.0})


func _tick(delta: float) -> void:
	var content := 34.0 + msgs.size() * ROW_H
	var target := maxf(0.0, content - (LIST_BOTTOM - LIST_TOP))
	scroll = move_toward(scroll, target, delta * 300.0)
	if not judged and not busy and sends > 0 and sends < 3 and t - last_send >= idle_wait:
		_judge("once" if sends == 1 else "reminder")


func _judge(id: String) -> void:
	judged = true
	input_locked = true
	later(end_hold, finish.bind(id))


func _send() -> void:
	if busy or judged or sends >= 3 or input_text == "":
		return
	busy = true
	sends += 1
	last_send = t
	msgs.append({"me": true, "text": input_text, "born": t})
	input_text = ""
	Sfx.play("send", 0.0)
	var replies: Array = REPLIES[sends - 1]
	for i in replies.size():
		later(reply_gap * (i + 1), _reply.bind(replies[i]))
	later(reply_gap * replies.size() + 0.15, _after_replies)


func _reply(s: String) -> void:
	msgs.append({"me": false, "text": s, "born": t})
	Sfx.play("ding", 0.05)


func _after_replies() -> void:
	busy = false
	if sends >= 3:
		Sfx.play("bad", 0.0)
		_judge("all_in")
	else:
		input_text = "T"


func _on_press(p: Vector2) -> void:
	if SEND_RECT.grow(4).has_point(p):
		_send()


func _draw() -> void:
	fill_screen(Color("ededed"))
	# 消息
	var y := LIST_TOP + 20.0 - scroll
	if y > LIST_TOP - 10:
		text("今天 10:24", Vector2(W / 2, y), 14, SOFT, false)
	y += 24.0
	for m in msgs:
		var s: String = m["text"]
		var w := text_w(s, 15, false) + 28.0
		var age: float = t - float(m["born"])
		var k := 1.0 if float(m["born"]) < 0.0 else ease_out_back(clampf(age / 0.2, 0.0, 1.0))
		if y + 40 > LIST_TOP - 20 and y < LIST_BOTTOM + 10:
			if m["me"]:
				var r := Rect2(W - 16 - w, y, w, 40)
				draw_set_transform(Vector2(r.end.x, r.position.y + 20) * (1.0 - k), 0.0, Vector2(k, k))
				box(r, Color("9be07a"), 12.0, 2.0)
				text(s, r.get_center(), 15, INK, false)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			else:
				circle(Vector2(34, y + 20), 17, RED, 2.0)
				text("省", Vector2(34, y + 20), 15, Color.WHITE)
				var r2 := Rect2(60, y, w, 40)
				draw_set_transform(Vector2(r2.position.x, r2.position.y + 20) * (1.0 - k), 0.0, Vector2(k, k))
				box(r2, Color.WHITE, 12.0, 2.0)
				text(s, r2.get_center(), 15, INK, false)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		y += ROW_H
	# 顶栏（盖住滚上去的消息）
	draw_rect(Rect2(0, view_top, W, 62 - view_top), Color("f8f8f8"))
	line(Vector2(0, 62), Vector2(W, 62), Color("d6d6d6"), 1.5)
	draw_polyline(PackedVector2Array([Vector2(28, 22), Vector2(18, 32), Vector2(28, 42)]), INK, 3.0, true)
	text(sender, Vector2(W / 2, 24), 16, INK)
	text("营销短信", Vector2(W / 2, 46), 14, SOFT, false)
	# 输入栏
	draw_rect(Rect2(0, 528, W, view_bottom - 528), Color("f8f8f8"))
	line(Vector2(0, 528), Vector2(W, 528), Color("d6d6d6"), 1.5)
	box(INPUT_RECT, Color.WHITE, 22.0, 1.5, Color("cfcfcf"))
	if input_text != "":
		text(input_text, INPUT_RECT.position + Vector2(18, 22), 17, INK, false, HORIZONTAL_ALIGNMENT_LEFT)
	var cx := INPUT_RECT.position.x + 18.0 + text_w(input_text, 17, false) + 2.0
	if not judged and fmod(t, 1.0) < 0.5:
		line(Vector2(cx, 552), Vector2(cx, 572), Color("3d7be0"), 2.0)
	var enabled := sends < 3 and not busy and input_text != "" and not judged
	var greyed := sends >= 3
	box_shadow(SEND_RECT, Color("cfcfcf") if greyed else GREEN, 22.0, 0.0 if greyed else 3.0)
	text("发送", SEND_RECT.get_center(), 15, Color("f4f4f4") if greyed else Color(1, 1, 1, 1.0 if enabled else 0.75))
	draw_bubbles()
