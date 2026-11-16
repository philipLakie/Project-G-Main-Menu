class_name SettingsApplier
extends Node
## Applies the settings Godot itself understands (volume, fullscreen, vsync,
## language). Optional: a game that applies them itself leaves this node out.

@export var store: SettingsStore

var _warned: Dictionary[StringName, bool] = {}


func _ready() -> void:
	if store == null:
		push_warning("SettingsApplier: no store assigned; nothing will be applied.")
		return
	store.settings_loaded.connect(_apply_all)
	store.setting_changed.connect(_on_setting_changed)
	if store.is_node_ready():
		_apply_all()


func _apply_all() -> void:
	for def in store.get_definitions():
		if def != null and def.apply_as != SettingDef.ApplyAs.NONE:
			_apply(def, store.get_value(def.key))


func _on_setting_changed(key: StringName, value: Variant) -> void:
	_apply(store.get_definition(key), value)


func _apply(def: SettingDef, value: Variant) -> void:
	match def.apply_as:
		SettingDef.ApplyAs.AUDIO_BUS_VOLUME:
			var bus := AudioServer.get_bus_index(def.apply_target)
			if def is not SettingSliderDef:
				_warn_once(def, "AUDIO_BUS_VOLUME needs a slider definition")
			elif bus == -1:
				_warn_once(def, "there is no audio bus named '%s'" % def.apply_target)
			else:
				AudioServer.set_bus_mute(bus, value <= 0.0)
				if value > 0.0:
					AudioServer.set_bus_volume_db(bus, linear_to_db(value))
		SettingDef.ApplyAs.FULLSCREEN:
			if def is SettingToggleDef:
				get_window().mode = Window.MODE_FULLSCREEN if value else Window.MODE_WINDOWED
			else:
				_warn_once(def, "FULLSCREEN needs a toggle definition")
		SettingDef.ApplyAs.VSYNC:
			if def is SettingToggleDef:
				DisplayServer.window_set_vsync_mode(
						DisplayServer.VSYNC_ENABLED if value else DisplayServer.VSYNC_DISABLED)
			else:
				_warn_once(def, "VSYNC needs a toggle definition")
		SettingDef.ApplyAs.LOCALE:
			if def is SettingOptionsDef:
				TranslationServer.set_locale(value)
			else:
				_warn_once(def, "LOCALE needs an options definition")


func _warn_once(def: SettingDef, reason: String) -> void:
	if not _warned.has(def.key):
		_warned[def.key] = true
		push_warning("SettingsApplier: skipping setting '%s': %s." % [def.key, reason])
