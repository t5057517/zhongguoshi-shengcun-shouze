extends Node2D
## 游戏主流程（主场景 res://game/Main.tscn）
##
## 标题 → 第1~4关 → 每关结束：黑屏 0.5 秒 → 关卡标题卡（点击任意处继续）→ 下一关 → 生存报告
##
## ● 关卡顺序、标题：改 LEVELS
## ● 每个结果在标题卡上显示的文字：改 RESULTS
## ● 每关的结果会写进 user://results.json（result_id）
##
## 开发快捷键：Esc 回标题 / R 重开本关 / 标题画面按 1~4 直接进关

const LEVELS := [
	{"key": "L1", "scene": "res://game/levels/L1_Haircut.tscn", "no": "第一关", "title": "只剪一次"},
	{"key": "L2", "scene": "res://game/levels/L2_CloseAd.tscn", "no": "第二关", "title": "我只是想关掉它"},
	{"key": "L3", "scene": "res://game/levels/L3_Captcha.tscn", "no": "第三关", "title": "验证码"},
	{"key": "L4", "scene": "res://game/levels/L4_Unsubscribe.tscn", "no": "第四关", "title": "回T退订"},
]

## result_id → [标题卡上的结果, 一句调侃, 类型 good/bad/mid]
const RESULTS := {
	"single": ["支付成功", "Tony 的笑容，下班了。", "good"],
	"card": ["尊贵会员", "剪头发结束了，充值才刚刚开始。", "bad"],
	"uninstalled": ["卸载成功", "它换了个图标，又回来了。", "good"],
	"converted": ["已被转化", "你只是想关掉它。", "bad"],
	"login": ["登录成功", "下一步：请完成实名认证。", "good"],
	"locked": ["操作频繁", "请明日再试。", "bad"],
	"once": ["退订成功", "见好就收。", "good"],
	"reminder": ["订阅了提醒", "退订了一半，又订回来一半。", "mid"],
	"all_in": ["全部订阅", "你回的每一个 T，都被认真对待了。", "bad"],
}

const SAVE_PATH := "user://results.json"
const CORE_H := 600.0
## 横屏时显示“请竖屏游玩”遮罩（PC 上调试横屏可改成 false）
const REQUIRE_PORTRAIT := true

var stage: Node2D
var screens: Screens
var level: LevelBase = null
var level_index := -1
var results := {}
var history: Array = []


func _ready() -> void:
	stage = Node2D.new()
	stage.name = "Stage"
	add_child(stage)
	screens = Screens.new()
	screens.name = "Screens"
	screens.z_index = 100
	screens.game = self
	add_child(screens)
	screens.action.connect(_on_screen_action)
	_load()
	_layout()
	show_title()


func _process(_delta: float) -> void:
	_layout()


## 核心区 375x600 在可见高度内垂直居中，背景向上下延伸
func _layout() -> void:
	var vs := get_viewport_rect().size
	var core_y := roundf((vs.y - CORE_H) / 2.0)
	stage.position = Vector2(0, core_y)
	screens.position = Vector2(0, core_y)
	screens.view_top = -core_y
	screens.view_bottom = vs.y - core_y
	if level:
		level.view_top = -core_y
		level.view_bottom = vs.y - core_y
	var ws := get_window().size
	var landscape := REQUIRE_PORTRAIT and ws.x > ws.y
	screens.portrait_warning = landscape
	if level and not level.done:
		level.process_mode = Node.PROCESS_MODE_DISABLED if landscape else Node.PROCESS_MODE_INHERIT


func show_title() -> void:
	_free_level()
	level_index = -1
	screens.set_mode("title")


func start_level(i: int) -> void:
	_free_level()
	level_index = i
	var packed: PackedScene = load(LEVELS[i]["scene"])
	level = packed.instantiate() as LevelBase
	stage.add_child(level)
	level.finished.connect(_on_level_finished)
	screens.set_mode("none")
	_layout()


func _free_level() -> void:
	if level:
		level.queue_free()
		level = null


func _on_level_finished(result_id: String) -> void:
	var key: String = LEVELS[level_index]["key"]
	results[key] = result_id
	history.append({"level": key, "result_id": result_id, "time": Time.get_datetime_string_from_system()})
	if history.size() > 100:
		history = history.slice(history.size() - 100)
	_save()
	print("[结果] ", key, " result_id=", result_id)
	# 黑屏 0.5 秒 → 关卡标题卡
	screens.set_mode("black")
	screens.later(0.5, _show_result_card.bind(result_id))


func _show_result_card(result_id: String) -> void:
	_free_level()
	var info: Array = RESULTS.get(result_id, [result_id, "", "mid"])
	screens.show_card(LEVELS[level_index]["no"], LEVELS[level_index]["title"], info[0], info[1], info[2])


func _on_screen_action(action: String, arg: int) -> void:
	match action:
		"start":
			results.clear()
			start_level.call_deferred(0)
		"level":
			start_level.call_deferred(arg)
		"continue":
			if level_index < LEVELS.size() - 1:
				start_level.call_deferred(level_index + 1)
			else:
				level_index = -1
				screens.set_mode("summary")
				Sfx.play("ok")
		"title":
			show_title.call_deferred()


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var k: Key = (event as InputEventKey).keycode
	if k == KEY_ESCAPE:
		show_title()
	elif k == KEY_R and level_index >= 0 and level:
		start_level(level_index)
	elif screens.mode == "title" and k >= KEY_1 and k <= KEY_4:
		start_level(int(k - KEY_1))


## 生存报告的总评
func verdict() -> String:
	var good := 0
	var bad := 0
	for l in LEVELS:
		var id: String = results.get(l["key"], "")
		if id == "":
			return "报告不完整：还有场面没经历过。"
		var g: String = RESULTS.get(id, ["", "", "mid"])[2]
		if g == "good":
			good += 1
		elif g == "bad":
			bad += 1
	if good == LEVELS.size():
		return "套路全看穿了，人也确实累了。"
	if bad >= 3:
		return "你是每个运营最喜欢的用户。"
	if good >= 2:
		return "该关的关了，该跑的跑了。"
	return "一半清醒，一半被安排。"


func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"results": results, "history": history}, "\t"))


func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return
	var data: Variant = JSON.parse_string(f.get_as_text())
	if data is Dictionary:
		var r: Variant = (data as Dictionary).get("results", {})
		if r is Dictionary:
			results = r
		var h: Variant = (data as Dictionary).get("history", [])
		if h is Array:
			history = h
