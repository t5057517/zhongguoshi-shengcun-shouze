extends Node
## 音效（自动加载，全局名 Sfx）
## 所有音效都是启动时用程序合成的，不需要音频文件。
## 用法：Sfx.play("pop")
## 想换成真实音效：把 .wav/.ogg 放进工程，在 _ready() 里用 _streams["pop"] = load("res://xxx.wav") 覆盖即可。

const RATE := 22050

var muted := false
var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	# 每个音符：[起始频率, 时长, 波形, 音量, 延迟, 结束频率(0=不滑音)]
	_streams["pop"] = _make([[720.0, 0.07, "tri", 0.45, 0.0, 0.0]])
	_streams["tap"] = _make([[460.0, 0.05, "square", 0.12, 0.0, 0.0]])
	_streams["ok"] = _make([[660.0, 0.12, "tri", 0.5, 0.0, 0.0], [990.0, 0.22, "tri", 0.5, 0.11, 0.0]])
	_streams["bad"] = _make([[330.0, 0.18, "square", 0.13, 0.0, 220.0], [220.0, 0.32, "square", 0.13, 0.16, 140.0]])
	_streams["cash"] = _make([[1320.0, 0.1, "sine", 0.55, 0.0, 0.0], [1760.0, 0.3, "sine", 0.55, 0.09, 0.0]])
	_streams["thud"] = _make([[130.0, 0.16, "sine", 0.8, 0.0, 60.0]])
	_streams["scan"] = _make([[1250.0, 0.03, "sine", 0.18, 0.0, 0.0]])
	_streams["fanfare"] = _make([[523.0, 0.16, "square", 0.12, 0.0, 0.0], [659.0, 0.16, "square", 0.12, 0.1, 0.0], [784.0, 0.16, "square", 0.12, 0.2, 0.0], [1047.0, 0.3, "square", 0.12, 0.3, 0.0]])
	_streams["ding"] = _make([[988.0, 0.18, "sine", 0.45, 0.0, 0.0], [1319.0, 0.25, "sine", 0.35, 0.06, 0.0]])
	_streams["buzz"] = _make([[160.0, 0.14, "square", 0.12, 0.0, 120.0]])
	_streams["whoosh"] = _make([[300.0, 0.22, "tri", 0.35, 0.0, 1200.0]])
	_streams["send"] = _make([[520.0, 0.08, "tri", 0.4, 0.0, 880.0]])


## 播放音效。pitch_jitter > 0 时随机微调音高，避免重复感。
func play(sound: String, pitch_jitter := 0.08) -> void:
	if muted or not _streams.has(sound):
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _streams[sound]
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	p.play()


func _make(notes: Array) -> AudioStreamWAV:
	var total := 0.0
	for n in notes:
		total = maxf(total, float(n[4]) + float(n[1]))
	var count := int((total + 0.03) * RATE)
	var buf := PackedFloat32Array()
	buf.resize(count)
	for n in notes:
		var f0: float = n[0]
		var dur: float = n[1]
		var wave: String = n[2]
		var vol: float = n[3]
		var start := int(float(n[4]) * RATE)
		var f1: float = n[5] if float(n[5]) > 0.0 else f0
		var length := int(dur * RATE)
		var phase := 0.0
		for i in length:
			var u := float(i) / float(length)
			var f := f0 * pow(f1 / f0, u)
			phase += f / RATE
			var ph := fposmod(phase, 1.0)
			var s := 0.0
			match wave:
				"sine":
					s = sin(ph * TAU)
				"tri":
					s = 4.0 * absf(ph - 0.5) - 1.0
				_:
					s = 1.0 if ph < 0.5 else -1.0
			var env := exp(-4.5 * u) * minf(1.0, float(i) / (RATE * 0.003))
			var idx := start + i
			if idx < count:
				buf[idx] += s * vol * env
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for i in count:
		bytes.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	return w
