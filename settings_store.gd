class_name SettingsStore
extends Node
## Holds the current value of every setting and saves them to a file.
## It does not touch any engine system; see SettingsApplier for that.

signal setting_changed(key: StringName, value: Variant)
signal settings_loaded

const _SECTION := "settings"

@export var definitions: Array[SettingDef] = []
@export var file_path: String = "user://settings.cfg"
## Save after every change.
@export var auto_save: bool = true

var _defs: Dictionary[StringName, SettingDef] = {}
var _ordered: Array[SettingDef] = []
var _values: Dictionary[StringName, Variant] = {}


func _ready() -> void:
	load_from_disk()


func get_value(key: StringName) -> Variant:
	return _values[key] if _find(key) != null else null


func set_value(key: StringName, value: Variant) -> void:
	var def := _find(key)
	if def == null:
		return
	var clean: Variant = def.sanitize(value)
	if clean == null:
		push_error("SettingsStore: value %s is not allowed for setting '%s'." % [value, key])
		return
	if _store(key, clean) and auto_save:
		save_to_disk()


func reset(key: StringName) -> void:
	var def := _find(key)
	if def != null and _store(key, def.get_default()) and auto_save:
		save_to_disk()


func reset_all() -> void:
	var changed := false
	for key: StringName in _defs:
		changed = _store(key, _defs[key].get_default()) or changed
	if changed and auto_save:
		save_to_disk()


## Returns null, without an error, if there is no such setting.
func get_definition(key: StringName) -> SettingDef:
	return _defs.get(key)


## The definitions in use, in the order they are listed: a copy, without
## empty slots or ignored duplicates.
func get_definitions() -> Array[SettingDef]:
	return _ordered.duplicate()


func save_to_disk() -> Error:
	var config := ConfigFile.new()
	for key: StringName in _values:
		config.set_value(_SECTION, key, _values[key])
	var err := config.save(file_path)
	if err != OK:
		push_error("SettingsStore: could not save '%s' (%s)." % [file_path, error_string(err)])
	return err


## Reads the file and emits settings_loaded. A missing file is not an error.
## Anything missing or invalid in the file takes its default.
func load_from_disk() -> Error:
	_index_definitions()
	var config := ConfigFile.new()
	var err := OK
	if FileAccess.file_exists(file_path):
		err = config.load(file_path)
		if err != OK:
			push_error("SettingsStore: could not read '%s' (%s)." % [file_path, error_string(err)])
	_values.clear()
	for key: StringName in _defs:
		var clean: Variant = null
		if config.has_section_key(_SECTION, key):
			clean = _defs[key].sanitize(config.get_value(_SECTION, key))
		_values[key] = clean if clean != null else _defs[key].get_default()
	settings_loaded.emit()
	return err


func _index_definitions() -> void:
	_defs.clear()
	_ordered.clear()
	for def in definitions:
		if def == null:
			continue
		if _defs.has(def.key):
			push_error("SettingsStore: two definitions share the key '%s'. The second is ignored." % def.key)
			continue
		_defs[def.key] = def
		_ordered.append(def)


func _find(key: StringName) -> SettingDef:
	var def: SettingDef = _defs.get(key)
	if def == null:
		push_error("SettingsStore: unknown setting '%s'." % key)
	return def


## Stores an already sanitized value. Returns true if it changed.
func _store(key: StringName, value: Variant) -> bool:
	if _values[key] == value:
		return false
	_values[key] = value
	setting_changed.emit(key, value)
	return true
