class_name CheatMenu
extends CanvasLayer
## Client-side cheat menu.
##   Desktop  : F2 to open/close.
##   Mobile   : small ☠ button top-right (added by this node).
##   VR       : not supported.
##
## Server anticheat is disabled by default (game.js requires MELTIEW_ANTICHEAT=1).

var player: LocalPlayer

var _panel: PanelContainer
var _toggle_btn: Button   # mobile only
var _open := false

var god_mode    := false
var inf_stamina := false
var speed_boost := false
var fly_mode    := false
var noclip      := false
var bhop_mode   := false

const SPEED_BOOST_VAL := 20.0
# Fly: local_player._fly() uses maxf(admin_speed, 24.0).
# Setting admin_speed=0 gives the default 24 m/s base, 38.4 with sprint.
const FLY_ADMIN_SPEED := 0.0

var _orig_walk        := LocalPlayer.MAX_SPEED
var _orig_sprint      := LocalPlayer.SPRINT_SPEED
var _orig_stamina     := 100.0
var _orig_bhop_max    := 24.0
var _orig_admin_speed := 0.0

var _mobile := false


func _ready() -> void:
	layer = 110
	_mobile = Session.phone
	_build_ui()
	_panel.visible = false


func _unhandled_key_input(event: InputEvent) -> void:
	if _mobile:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F2:
			get_viewport().set_input_as_handled()
			_toggle()


func _toggle() -> void:
	_open = not _open
	_panel.visible = _open
	if _toggle_btn:
		_toggle_btn.modulate = Color(1.0, 0.5, 0.5) if _open else Color.WHITE


# ── UI ────────────────────────────────────────────────────────────────────────

func _build_ui() -> void:
	# Mobile toggle button: small skull in the top-right corner.
	if _mobile:
		_toggle_btn = Button.new()
		_toggle_btn.text = "☠"
		_toggle_btn.add_theme_font_size_override("font_size", 22)
		_toggle_btn.flat = true
		_toggle_btn.custom_minimum_size = Vector2(52, 52)
		_toggle_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		_toggle_btn.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		_toggle_btn.offset_left   = -58
		_toggle_btn.offset_right  = -6
		_toggle_btn.offset_top    = 6
		_toggle_btn.offset_bottom = 58
		_toggle_btn.pressed.connect(_toggle)
		add_child(_toggle_btn)

	# Main panel.
	_panel = PanelContainer.new()
	if _mobile:
		# Right side, below the toggle button.
		_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		_panel.grow_vertical = Control.GROW_DIRECTION_END
		_panel.offset_right  = -6
		_panel.offset_top    = 64
	else:
		_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
		_panel.position = Vector2(12, 12)
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)

	if _mobile:
		# Wrap in a scroll container so it fits on small screens.
		var scroll := ScrollContainer.new()
		scroll.custom_minimum_size = Vector2(200, 320)
		_panel.add_child(scroll)
		scroll.add_child(vbox)
	else:
		var title := Label.new()
		title.text = "Cheats  [F2]"
		title.add_theme_font_size_override("font_size", 15)
		vbox.add_child(title)
		vbox.add_child(HSeparator.new())
		_panel.add_child(vbox)

	_make_btn(vbox, "God Mode",    "Block all incoming damage",               _set_god)
	_make_btn(vbox, "Inf Stamina", "No sprint exhaustion",                    _set_stamina)
	_make_btn(vbox, "Speed Boost", "Walk/sprint at 20 m/s",                   _set_speed)
	_make_btn(vbox, "Fly",         "Admin flight  (WASD + E/Q, sprint=fast)", _set_fly)
	_make_btn(vbox, "Noclip",      "Disable own collision locally",           _set_noclip)
	_make_btn(vbox, "Bhop",        "Bunny-hop, no speed cap",                 _set_bhop)


func _make_btn(parent: VBoxContainer, label: String, tip: String, cb: Callable) -> void:
	var btn := CheckButton.new()
	btn.text = label
	btn.tooltip_text = tip
	btn.toggled.connect(cb)
	parent.add_child(btn)


# ── per-frame ─────────────────────────────────────────────────────────────────

func _process(_delta: float) -> void:
	if not player:
		return
	if god_mode and not player.server_health and not player.dead:
		if player.hp < player.max_hp:
			player.hp = player.max_hp
			player.health_changed.emit(player.hp)


# ── cheat setters ─────────────────────────────────────────────────────────────

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
		player.max_stamina = 0.0   # 0 = endless (local_player._update_stamina)
	else:
		player.max_stamina = _orig_stamina


func _set_speed(on: bool) -> void:
	speed_boost = on
	if not player:
		return
	if on:
		_orig_walk   = player.walk_speed
		_orig_sprint = player.sprint_speed
		player.walk_speed   = SPEED_BOOST_VAL
		player.sprint_speed = SPEED_BOOST_VAL
	else:
		player.walk_speed   = _orig_walk
		player.sprint_speed = _orig_sprint


func _set_fly(on: bool) -> void:
	fly_mode = on
	if not player:
		return
	if on:
		_orig_admin_speed  = player.admin_speed
		player.admin_speed = FLY_ADMIN_SPEED
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
		_orig_bhop_max  = player.bhop_max
		player.bhop     = true
		player.bhop_max = 999.0
	else:
		player.bhop     = false
		player.bhop_max = _orig_bhop_max
