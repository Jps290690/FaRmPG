extends Node

# Audio procedural (Fase 8): SFX y música generados por código (sin assets externos).
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

# Sintetiza un WAV de 16 bits a partir de segmentos.
# Cada segmento: {freq, dur, vol, attack (opcional), harmonics: [amplitudes de armónicos 2x, 3x...]}.
func _wav_from(segments: Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	for seg in segments:
		var freq := float(seg.get("freq", 440.0))
		var dur := float(seg.get("dur", 0.1))
		var vol := float(seg.get("vol", 0.5))
		var attack := float(seg.get("attack", 0.01))
		var harmonics: Array = seg.get("harmonics", [])
		var n := int(MIX_RATE * dur)
		var chunk := PackedByteArray()
		chunk.resize(n * 2)
		for i in n:
			var t := float(i) / MIX_RATE
			var env := minf(1.0, t / maxf(attack, 0.001))
			env *= exp(-2.5 * t / dur)
			var s := sin(TAU * freq * t)
			var h_idx := 0
			for amp in harmonics:
				h_idx += 1
				s += float(amp) * sin(TAU * freq * float(h_idx + 1) * t)
			s /= 1.0 + float(harmonics.size()) * 0.5
			var v := clampf(s * env * vol, -1.0, 1.0)
			chunk.encode_s16(i * 2, int(v * 32767.0))
		data.append_array(chunk)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.data = data
	return wav

func _gen_sounds() -> void:
	_sounds["gather"] = _wav_from([
		{"freq": 480.0, "dur": 0.12, "vol": 0.5},
		{"freq": 640.0, "dur": 0.1, "vol": 0.35},
	])
	_sounds["craft"] = _wav_from([
		{"freq": 523.25, "dur": 0.09, "vol": 0.5},
		{"freq": 659.25, "dur": 0.12, "vol": 0.5},
	])
	_sounds["buy"] = _wav_from([
		{"freq": 880.0, "dur": 0.08, "vol": 0.5},
		{"freq": 1174.66, "dur": 0.12, "vol": 0.5},
	])
	_sounds["sell"] = _wav_from([
		{"freq": 1174.66, "dur": 0.08, "vol": 0.5},
		{"freq": 880.0, "dur": 0.12, "vol": 0.5},
	])
	_sounds["attack"] = _wav_from([
		{"freq": 240.0, "dur": 0.08, "vol": 0.45, "harmonics": [0.6, 0.4]},
		{"freq": 160.0, "dur": 0.1, "vol": 0.45, "harmonics": [0.6, 0.4]},
	])
	_sounds["hurt"] = _wav_from([
		{"freq": 130.0, "dur": 0.18, "vol": 0.55, "harmonics": [0.5, 0.35, 0.2]},
	])
	_sounds["death"] = _wav_from([
		{"freq": 330.0, "dur": 0.2, "vol": 0.5},
		{"freq": 262.0, "dur": 0.2, "vol": 0.5},
		{"freq": 196.0, "dur": 0.35, "vol": 0.5},
	])
	_sounds["build"] = _wav_from([
		{"freq": 523.25, "dur": 0.09, "vol": 0.5},
		{"freq": 659.25, "dur": 0.09, "vol": 0.5},
		{"freq": 783.99, "dur": 0.09, "vol": 0.5},
		{"freq": 1046.5, "dur": 0.14, "vol": 0.5},
	])
	_sounds["levelup"] = _wav_from([
		{"freq": 523.25, "dur": 0.12, "vol": 0.5},
		{"freq": 659.25, "dur": 0.12, "vol": 0.5},
		{"freq": 783.99, "dur": 0.12, "vol": 0.5},
		{"freq": 1046.5, "dur": 0.25, "vol": 0.55},
	])
	_sounds["error"] = _wav_from([
		{"freq": 110.0, "dur": 0.15, "vol": 0.4, "harmonics": [0.7]},
	])
	_sounds["respawn"] = _wav_from([
		{"freq": 262.0, "dur": 0.09, "vol": 0.45},
		{"freq": 330.0, "dur": 0.09, "vol": 0.45},
		{"freq": 392.0, "dur": 0.09, "vol": 0.45},
		{"freq": 523.25, "dur": 0.2, "vol": 0.5},
	])

func _gen_music() -> void:
	# Loop calmado de 8s: Am – F – C – G (2s por acorde), senos suaves.
	var chords := [
		[110.0, 130.81, 164.81],
		[87.31, 110.0, 130.81, 174.61],
		[130.81, 164.81, 196.0],
		[98.0, 123.47, 146.83, 196.0],
	]
	var segments := []
	for chord in chords:
		for freq: float in chord:
			segments.append({"freq": freq, "dur": 2.0, "vol": 0.16, "attack": 0.5, "harmonics": [0.35, 0.15]})
	_music_stream = _wav_from(segments)
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