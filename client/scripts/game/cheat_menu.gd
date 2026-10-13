class_name CheatMenu
extends CanvasLayer
## Client-side cheat menu. Toggle with F2.
##
## Anticheat is disabled by default on the server (game.js:218):
##   this.anticheat = process.env.MELTIEW_ANTICHEAT === '1';
## So all positions are accepted unconditionally unless the server sets
## MELTIEW_ANTICHEAT=1. Fly, speed and noclip are fully free.

var player: LocalPlayer

var _panel: PanelContainer
var _open := false

var god_mode := false
var inf_stamina := false
var speed_boost := false
var fly_mode := false
var noclip := false
var bhop_mode := false

# Fly: local_player._fly() uses maxf(admin_speed, 24.0) — set above 24 to go faster.
# Set to 0 when off so it doesn't interfere with admin panels.
const FLY_ADMIN_SPEED := 0.0   # 0 → maxf(0, 24) = 24 m/s base, 38.4 with sprint
const SPEED_BOOST_WALK := 20.0
const SPEED_BOOST_SPRINT := 20.0

var _orig_walk := LocalPlayer.MAX_SPEED
var _orig_sprint := LocalPlayer.SPRINT_SPEED
var _orig_stamina := 100.0
var _orig_bhop_max := 24.0
var _orig_admin_speed := 0.0

var _btns: Dictionary = {}


func _ready() -> void:
	layer = 110
	_build_ui()
	_panel.visible = false


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F2:
			get_viewport().set_input_as_handled()
			_toggle()


func _toggle() -> void:
	_open = not _open
	_panel.visible = _open


func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_panel.position = Vector2(12, 12)
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	_panel.add_child(vbox)

	var title := Label.new()
	title.text = "Cheats  [F2]"
	title.add_theme_font_size_override("font_size", 15)
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	_make_btn(vbox, "God Mode",     "Block all incoming damage",      _set_god)
	_make_btn(vbox, "Inf Stamina",  "No sprint exhaustion ever",      _set_stamina)
	_make_btn(vbox, "Speed Boost",  "Walk/sprint at 20 m/s",          _set_speed)
	_make_btn(vbox, "Fly",          "Admin flight (Q/E up-down, sprint to go faster)", _set_fly)
	_make_btn(vbox, "Noclip",       "Disable own collision locally",  _set_noclip)
	_make_btn(vbox, "Bhop",         "Bunny-hop with no speed cap",    _set_bhop)

	vbox.add_child(HSeparator.new())
	var note := Label.new()
	note.text = "Anticheat: OFF by default\n(needs MELTIEW_ANTICHEAT=1)"
	note.add_theme_font_size_override("font_size", 10)
	note.modulate = Color(0.55, 1.0, 0.55)
	vbox.add_child(note)


func _make_btn(parent: VBoxContainer, label: String, tip: String, cb: Callable) -> void:
	var btn := CheckButton.new()
	btn.text = label
	btn.tooltip_text = tip
	btn.toggled.connect(cb)
	parent.add_child(btn)
	_btns[label] = btn


func _process(_delta: float) -> void:
	if not player:
		return
	if god_mode and not player.server_health and not player.dead:
		if player.hp < player.max_hp:
			player.hp = player.max_hp
			player.health_changed.emit(player.hp)


# ── cheat setters ──────────────────────────────────────────────────────────────

func _set_god(on: bool) -> void:
	god_mode = on
	if player:
		player.god_mode = on


func _set_stamina(on: bool) -> void:
	inf_stamina = on
	if not player:
		return
	if on:
		_orig_stamina = player.max_stamina
		player.max_stamina = 0.0  # 0 = endless (local_player.gd _update_stamina)
	else:
		player.max_stamina = _orig_stamina


func _set_speed(on: bool) -> void:
	speed_boost = on
	if not player:
		return
	if on:
		_orig_walk = player.walk_speed
		_orig_sprint = player.sprint_speed
		player.walk_speed = SPEED_BOOST_WALK
		player.sprint_speed = SPEED_BOOST_SPRINT
	else:
		player.walk_speed = _orig_walk
		player.sprint_speed = _orig_sprint


func _set_fly(on: bool) -> void:
	fly_mode = on
	if not player:
		return
	if on:
		_orig_admin_speed = player.admin_speed
		player.admin_speed = FLY_ADMIN_SPEED  # 0 → uses 24 m/s floor in _fly()
	else:
		player.admin_speed = _orig_admin_speed
	player.flying = on


func _set_noclip(on: bool) -> void:
	noclip = on
	if player:
		player._collision.disabled = on


func _set_bhop(on: bool) -> void:
	bhop_mode = on
	if not player:
		return
	if on:
		_orig_bhop_max = player.bhop_max
		player.bhop = true
		player.bhop_max = 999.0  # no cap — anticheat is off
	else:
		player.bhop = false
		player.bhop_max = _orig_bhop_max
