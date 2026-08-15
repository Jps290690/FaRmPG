extends Node

# Audio procedural (Fase 10 pulido): sintetizador multicapa con ruido filtrado,
# envolventes ADSR, deslizamiento de tono y música con bajo/pad/arpegio/percusión.
# Accesible globalmente como autoload "Audio".

const SFX_COUNT := 8
const MIX_RATE := 22050

var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _music_player: AudioStreamPlayer
var _sounds := {}

func _ready() -> void:
	_gen_sounds()
	_gen_music()
	for i in SFX_COUNT:
		var p := AudioStreamPlayer.new()
		p.name = "Sfx%d" % i
		add_child(p)
		_players.append(p)
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "Music"
	add_child(_music_player)
	_music_player.stream = _music_stream
	apply_settings()
	if Settings.music_enabled:
		_music_player.play()

# Sintetiza un WAV de 16 bits mezclando capas de eventos.
# Cada capa es un Array de eventos; cada evento:
#   {start, freq, slide, dur, vol, attack, decay, harmonics, noise, noise_lp, shape}
func _synth(layers: Array) -> AudioStreamWAV:
	var mix := PackedFloat32Array()
	for layer in layers:
		var buf := _render_layer(layer)
		if mix.size() == 0:
			mix = buf
			continue
		var n := mini(mix.size(), buf.size())
		for i in n:
			mix[i] += buf[i]
	var peak := 0.001
	for v in mix:
		peak = maxf(peak, absf(v))
	var gain := 0.92 / peak if peak > 0.0 else 1.0
	var data := PackedByteArray()
	data.resize(mix.size() * 2)
	for i in mix.size():
		data.encode_s16(i * 2, int(clampf(mix[i] * gain, -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.data = data
	return wav

func _render_layer(events: Array) -> PackedFloat32Array:
	var total := 0.0
	for e in events:
		total = maxf(total, float(e.get("start", 0.0)) + float(e.get("dur", 0.1)))
	var buf := PackedFloat32Array()
	buf.resize(int(total * MIX_RATE) + 1)
	var rng_state := 12345
	for e in events:
		rng_state = _render_event(buf, e, rng_state)
	return buf

func _render_event(buf: PackedFloat32Array, e: Dictionary, rng_state: int) -> int:
	var start := float(e.get("start", 0.0))
	var freq := float(e.get("freq", 440.0))
	var slide := float(e.get("slide", freq))
	var dur := float(e.get("dur", 0.1))
	var vol := float(e.get("vol", 0.5))
	var attack := float(e.get("attack", 0.005))
	var decay := float(e.get("decay", 3.0))
	var harmonics: Array = e.get("harmonics", [])
	var noise_amt := float(e.get("noise", 0.0))
	var noise_lp := float(e.get("noise_lp", 0.4))
	var shape := String(e.get("shape", "sine"))
	var i0 := int(start * MIX_RATE)
	var n := int(dur * MIX_RATE)
	var lp := 0.0
	var state := rng_state
	for i in n:
		var idx := i0 + i
		if idx >= buf.size():
			break
		var t := float(i) / MIX_RATE
		var p := t / maxf(dur, 0.001)
		var env := minf(1.0, t / maxf(attack, 0.0005))
		env *= exp(-decay * p)
		var f := lerpf(freq, slide, minf(1.0, t / maxf(dur, 0.001)))
		var s := _osc(shape, TAU * f * t)
		var h_idx := 0
		for amp in harmonics:
			h_idx += 1
			s += float(amp) * _osc(shape, TAU * f * float(h_idx + 1) * t)
		s /= 1.0 + float(harmonics.size()) * 0.5
		if noise_amt > 0.0:
			state = (state * 1103515245 + 12345) & 0x7FFFFFFF
			var nn := float(state) / 0x7FFFFFFF * 2.0 - 1.0
			lp += noise_lp * (nn - lp)
			s = s * (1.0 - noise_amt) + lp * noise_amt
		buf[idx] += s * env * vol
	return state

func _osc(shape: String, phase: float) -> float:
	match shape:
		"tri":
			return 2.0 * absf(2.0 * (phase / TAU - floorf(phase / TAU + 0.5))) - 1.0
		"square":
			return 1.0 if fmod(phase, TAU) < TAU * 0.5 else -1.0
	return sin(phase)

func _gen_sounds() -> void:
	# Recolectar: golpe seco de madera + roce.
	_sounds["gather"] = _synth([
		[
			{"start": 0.0, "freq": 130.0, "slide": 90.0, "dur": 0.09, "vol": 0.5, "attack": 0.004, "harmonics": [0.5, 0.25]},
			{"start": 0.08, "freq": 210.0, "slide": 160.0, "dur": 0.07, "vol": 0.3, "attack": 0.004, "harmonics": [0.4]},
		],
		[
			{"start": 0.0, "freq": 300.0, "dur": 0.12, "vol": 0.16, "attack": 0.01, "noise": 1.0, "noise_lp": 0.25},
		],
	])
	# Craftear: dos martillazos + brillo metálico.
	_sounds["craft"] = _synth([
		[
			{"start": 0.0, "freq": 420.0, "dur": 0.05, "vol": 0.3, "attack": 0.002, "harmonics": [0.7, 0.4], "shape": "square"},
			{"start": 0.0, "freq": 180.0, "slide": 120.0, "dur": 0.08, "vol": 0.4, "attack": 0.002, "harmonics": [0.5]},
			{"start": 0.14, "freq": 420.0, "dur": 0.05, "vol": 0.3, "attack": 0.002, "harmonics": [0.7, 0.4], "shape": "square"},
			{"start": 0.14, "freq": 180.0, "slide": 120.0, "dur": 0.08, "vol": 0.4, "attack": 0.002, "harmonics": [0.5]},
			{"start": 0.32, "freq": 620.0, "dur": 0.14, "vol": 0.26, "attack": 0.003, "harmonics": [0.5, 0.3]},
		],
	])
	# Comprar/vender: timbre de moneda.
	_sounds["buy"] = _synth([
		[
			{"start": 0.0, "freq": 987.77, "dur": 0.12, "vol": 0.3, "attack": 0.003, "harmonics": [0.5, 0.3, 0.15]},
			{"start": 0.09, "freq": 1318.51, "dur": 0.24, "vol": 0.32, "attack": 0.003, "harmonics": [0.5, 0.3, 0.15]},
		],
	])
	_sounds["sell"] = _synth([
		[
			{"start": 0.0, "freq": 1318.51, "dur": 0.12, "vol": 0.3, "attack": 0.003, "harmonics": [0.5, 0.3, 0.15]},
			{"start": 0.09, "freq": 987.77, "dur": 0.24, "vol": 0.32, "attack": 0.003, "harmonics": [0.5, 0.3, 0.15]},
		],
	])
	# Atacar: whoosh + golpe.
	_sounds["attack"] = _synth([
		[
			{"start": 0.0, "freq": 220.0, "slide": 520.0, "dur": 0.16, "vol": 0.28, "attack": 0.02, "noise": 0.9, "noise_lp": 0.5},
			{"start": 0.0, "freq": 160.0, "slide": 90.0, "dur": 0.12, "vol": 0.4, "attack": 0.003, "harmonics": [0.6, 0.3]},
		],
	])
	# Recibir daño: golpe grave con crujido.
	_sounds["hurt"] = _synth([
		[
			{"start": 0.0, "freq": 220.0, "slide": 90.0, "dur": 0.22, "vol": 0.55, "attack": 0.004, "harmonics": [0.5, 0.3, 0.2], "noise": 0.35, "noise_lp": 0.2},
		],
	])
	# Muerte: descenso grave en tres pasos.
	_sounds["death"] = _synth([
		[
			{"start": 0.0, "freq": 330.0, "slide": 262.0, "dur": 0.2, "vol": 0.45, "attack": 0.005, "harmonics": [0.4]},
			{"start": 0.22, "freq": 262.0, "slide": 196.0, "dur": 0.22, "vol": 0.45, "attack": 0.005, "harmonics": [0.4]},
			{"start": 0.46, "freq": 196.0, "slide": 110.0, "dur": 0.42, "vol": 0.5, "attack": 0.005, "harmonics": [0.5, 0.3]},
		],
	])
	# Construir: martillos ascendentes + acorde final.
	_sounds["build"] = _synth([
		[
			{"start": 0.0, "freq": 180.0, "slide": 130.0, "dur": 0.08, "vol": 0.4, "attack": 0.003, "harmonics": [0.5]},
			{"start": 0.14, "freq": 200.0, "slide": 145.0, "dur": 0.08, "vol": 0.4, "attack": 0.003, "harmonics": [0.5]},
			{"start": 0.28, "freq": 230.0, "slide": 165.0, "dur": 0.08, "vol": 0.4, "attack": 0.003, "harmonics": [0.5]},
			{"start": 0.44, "freq": 523.25, "dur": 0.14, "vol": 0.3, "attack": 0.004, "harmonics": [0.4, 0.2]},
			{"start": 0.44, "freq": 659.25, "dur": 0.14, "vol": 0.26, "attack": 0.004, "harmonics": [0.4, 0.2]},
			{"start": 0.44, "freq": 783.99, "dur": 0.14, "vol": 0.26, "attack": 0.004, "harmonics": [0.4, 0.2]},
		],
	])
	# Subir de nivel: arpegio brillante.
	_sounds["levelup"] = _synth([
		[
			{"start": 0.0, "freq": 523.25, "dur": 0.14, "vol": 0.32, "attack": 0.004, "harmonics": [0.5, 0.3]},
			{"start": 0.1, "freq": 659.25, "dur": 0.14, "vol": 0.32, "attack": 0.004, "harmonics": [0.5, 0.3]},
			{"start": 0.2, "freq": 783.99, "dur": 0.14, "vol": 0.32, "attack": 0.004, "harmonics": [0.5, 0.3]},
			{"start": 0.3, "freq": 1046.5, "dur": 0.34, "vol": 0.4, "attack": 0.004, "harmonics": [0.5, 0.3, 0.15]},
			{"start": 0.0, "freq": 261.63, "dur": 0.6, "vol": 0.12, "attack": 0.1, "harmonics": [0.3, 0.1]},
		],
	])
	# Error: zumbido grave.
	_sounds["error"] = _synth([
		[
			{"start": 0.0, "freq": 120.0, "slide": 100.0, "dur": 0.2, "vol": 0.4, "attack": 0.01, "harmonics": [0.6, 0.35], "shape": "square"},
		],
	])
	# Reaparecer: ascenso suave.
	_sounds["respawn"] = _synth([
		[
			{"start": 0.0, "freq": 262.0, "dur": 0.1, "vol": 0.34, "attack": 0.006, "harmonics": [0.4, 0.2]},
			{"start": 0.1, "freq": 330.0, "dur": 0.1, "vol": 0.34, "attack": 0.006, "harmonics": [0.4, 0.2]},
			{"start": 0.2, "freq": 392.0, "dur": 0.1, "vol": 0.34, "attack": 0.006, "harmonics": [0.4, 0.2]},
			{"start": 0.3, "freq": 523.25, "dur": 0.34, "vol": 0.4, "attack": 0.006, "harmonics": [0.4, 0.2, 0.1]},
			{"start": 0.0, "freq": 130.81, "dur": 0.7, "vol": 0.1, "attack": 0.3, "harmonics": [0.3]},
		],
	])

func _gen_music() -> void:
	# Loop de 12s: Am – F – C – G. Bajo + pad + arpegio + percusión suave.
	var chords := [
		{"root": 110.0, "third": 130.81, "fifth": 164.81},
		{"root": 87.31, "third": 110.0, "fifth": 130.81},
		{"root": 130.81, "third": 164.81, "fifth": 196.0},
		{"root": 98.0, "third": 123.47, "fifth": 146.83},
	]
	var bass := []
	var pads := []
	var arp := []
	var perc := []
	var beat := 0.75
	for ci in 4:
		var t0 := float(ci) * 3.0
		var ch: Dictionary = chords[ci]
		bass.append({"start": t0, "freq": ch.root, "dur": 3.0, "vol": 0.22, "attack": 0.03, "decay": 0.4, "harmonics": [0.3]})
		for note in [ch.root * 2.0, ch.third * 2.0, ch.fifth * 2.0]:
			pads.append({"start": t0, "freq": note, "dur": 3.0, "vol": 0.09, "attack": 0.9, "decay": 0.3, "harmonics": [0.25, 0.1], "shape": "tri"})
		var notes := [ch.root, ch.third, ch.fifth, ch.root * 2.0]
		var seq := [0, 1, 2, 1, 2, 1, 0, 1]
		for i in 8:
			arp.append({"start": t0 + i * beat, "freq": notes[seq[i]], "dur": 0.32, "vol": 0.1, "attack": 0.004, "decay": 4.0, "harmonics": [0.3, 0.12], "shape": "tri"})
		for b in 4:
			perc.append({"start": t0 + b * beat, "freq": 2000.0, "dur": 0.05, "vol": 0.035, "attack": 0.002, "noise": 1.0, "noise_lp": 0.75})
		if ci == 0:
			perc.append({"start": t0, "freq": 55.0, "slide": 40.0, "dur": 0.28, "vol": 0.28, "attack": 0.004, "decay": 6.0, "harmonics": [0.4]})
	_music_stream = _synth([bass, pads, arp, perc])
	_music_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_music_stream.loop_begin = 0
	_music_stream.loop_end = _music_stream.data.size()

var _music_stream: AudioStreamWAV

func play_sfx(name: String) -> void:
	if not Settings.sfx_enabled or not _sounds.has(name):
		return
	var p: AudioStreamPlayer = _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _sounds[name]
	p.volume_db = linear_to_db(clampf(Settings.sfx_volume, 0.0, 1.0))
	p.play()

func apply_settings() -> void:
	if _music_player == null:
		return
	_music_player.volume_db = linear_to_db(clampf(Settings.music_volume, 0.0, 1.0))
	if Settings.music_enabled and not _music_player.playing:
		_music_player.play()
	elif not Settings.music_enabled and _music_player.playing:
		_music_player.stop()

func debug_state() -> String:
	return "music=%s sfx=%s playing=%s" % [Settings.music_enabled, Settings.sfx_enabled, _music_player.playing]