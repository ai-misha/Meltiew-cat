class_name CheatMenu
extends CanvasLayer
## Client-side cheat menu. Toggle with F2 (not F1 — that's used by Godot debug).
## Anticheat notes (playground, server-side):
##   - Horizontal speed flagged if > ~25 m/s over 1 s, ~60 m/s over 3 s.
##   - Fly is NOT checked on playground (grounded=undefined → check skipped).
##   - Ceiling at 90 m (fly up, then stop before it).
##   - Studio places DO check fly — enable with caution there.

var player: LocalPlayer

var _panel: PanelContainer
var _open := false

var god_mode := false
var inf_stamina := false
var speed_boost := false
var fly_mode := false
var noclip := false
var bhop_mode := false

const BOOST_WALK := 14.0    # horizontal: 14 m/s well under 25.25 m/s 1-sec limit
const BOOST_SPRINT := 16.5  # same for sprint; fly uses maxf(admin_speed, 24) so set it lower
const FLY_SPEED := 14.0     # admin_speed for fly; actual = 14 * 1.6 sprint = 22.4 — safe

var _orig_walk := LocalPlayer.MAX_SPEED
var _orig_sprint := LocalPlayer.SPRINT_SPEED
var _orig_stamina := 100.0
var _orig_bhop_max := 24.0

var _btns: Dictionary = {}  # cheat name → CheckButton


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

	var sep := HSeparator.new()
	vbox.add_child(sep)

	_make_btn(vbox, "God Mode", "Infinite HP (client health only)", _set_god)
	_make_btn(vbox, "Inf Stamina", "No sprint exhaustion", _set_stamina)
	_make_btn(vbox, "Speed Boost", "Walk/sprint at safe max (~16 m/s)", _set_speed)
	_make_btn(vbox, "Fly", "Admin flight (safe on playground)", _set_fly)
	_make_btn(vbox, "Noclip", "Disable own collision locally", _set_noclip)
	_make_btn(vbox, "Bhop", "Bunny-hop with boosted cap", _set_bhop)

	var hint := Label.new()
	hint.text = "Fly: stay below 90 m on playground"
	hint.add_theme_font_size_override("font_size", 10)
	hint.modulate = Color(0.7, 0.7, 0.7)
	vbox.add_child(hint)


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
	if not player:
		return
	player.god_mode = on


func _set_stamina(on: bool) -> void:
	inf_stamina = on
	if not player:
		return
	if on:
		_orig_stamina = player.max_stamina
		player.max_stamina = 0.0  # 0 = endless (see local_player.gd _update_stamina)
	else:
		player.max_stamina = _orig_stamina


func _set_speed(on: bool) -> void:
	speed_boost = on
	if not player:
		return
	if on:
		_orig_walk = player.walk_speed
		_orig_sprint = player.sprint_speed
		player.walk_speed = BOOST_WALK
		player.sprint_speed = BOOST_SPRINT
	else:
		player.walk_speed = _orig_walk
		player.sprint_speed = _orig_sprint


func _set_fly(on: bool) -> void:
	fly_mode = on
	if not player:
		return
	if on:
		player.admin_speed = FLY_SPEED
	else:
		player.admin_speed = 0.0
	player.flying = on


func _set_noclip(on: bool) -> void:
	noclip = on
	if not player:
		return
	player._collision.disabled = on


func _set_bhop(on: bool) -> void:
	bhop_mode = on
	if not player:
		return
	if on:
		_orig_bhop_max = player.bhop_max
		player.bhop = true
		player.bhop_max = 30.0  # safe: horizontal ~25 m/s still within 1-sec window
	else:
		player.bhop = false
		player.bhop_max = _orig_bhop_max
