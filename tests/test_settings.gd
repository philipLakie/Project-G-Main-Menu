extends GutTest

const PATH := "user://test_settings.cfg"
const BUS := &"TestSettingsBus"


func after_each() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(PATH)


func _defs() -> Array[SettingDef]:
	var toggle := SettingToggleDef.new()
	toggle.key = &"hints"
	toggle.default_value = true

	var slider := SettingSliderDef.new()
	slider.key = &"volume"
	slider.step = 0.1
	slider.default_value = 0.5
	slider.apply_as = SettingDef.ApplyAs.AUDIO_BUS_VOLUME
	slider.apply_target = BUS

	var options := SettingOptionsDef.new()
	options.key = &"difficulty"
	options.values = ["easy", "normal", "hard"]
	options.default_value = "normal"

	return [toggle, slider, options]


func _store(defs: Array[SettingDef]) -> SettingsStore:
	var store := SettingsStore.new()
	store.definitions = defs
	store.file_path = PATH
	add_child_autofree(store)
	return store


func test_defaults_when_no_file() -> void:
	var store := _store(_defs())
	assert_eq(store.get_value(&"hints"), true)
	assert_eq(store.get_value(&"volume"), 0.5)
	assert_eq(store.get_value(&"difficulty"), "normal")


func test_set_then_get() -> void:
	var store := _store(_defs())
	store.set_value(&"hints", false)
	store.set_value(&"difficulty", "hard")
	assert_eq(store.get_value(&"hints"), false)
	assert_eq(store.get_value(&"difficulty"), "hard")


func test_setting_changed_fires_only_on_real_change() -> void:
	var store := _store(_defs())
	watch_signals(store)
	store.set_value(&"hints", false)
	store.set_value(&"hints", false)
	assert_signal_emit_count(store, "setting_changed", 1)
	assert_signal_emitted_with_parameters(store, "setting_changed", [&"hints", false])


func test_slider_clamps_and_snaps() -> void:
	var store := _store(_defs())
	store.set_value(&"volume", 5.0)
	assert_almost_eq(store.get_value(&"volume"), 1.0, 0.0001)
	store.set_value(&"volume", -3)
	assert_almost_eq(store.get_value(&"volume"), 0.0, 0.0001)
	store.set_value(&"volume", 0.26)
	assert_almost_eq(store.get_value(&"volume"), 0.3, 0.0001)


func test_options_rejects_unlisted_value() -> void:
	var store := _store(_defs())
	watch_signals(store)
	store.set_value(&"difficulty", "nightmare")
	assert_eq(store.get_value(&"difficulty"), "normal")
	assert_signal_not_emitted(store, "setting_changed")
	assert_push_error("not allowed")


func test_unknown_key_is_rejected() -> void:
	var store := _store(_defs())
	store.set_value(&"nope", 1)
	assert_null(store.get_value(&"nope"))
	assert_push_error_count(2)


func test_save_then_load_in_new_store() -> void:
	var first := _store(_defs())
	first.set_value(&"hints", false)
	first.set_value(&"volume", 0.8)
	first.set_value(&"difficulty", "easy")

	var second := _store(_defs())
	assert_eq(second.get_value(&"hints"), false)
	assert_almost_eq(second.get_value(&"volume"), 0.8, 0.0001)
	assert_eq(second.get_value(&"difficulty"), "easy")


func test_bad_file_values_fall_back_to_defaults() -> void:
	var config := ConfigFile.new()
	config.set_value("settings", "hints", "yes")
	config.set_value("settings", "volume", "loud")
	config.set_value("settings", "difficulty", "nightmare")
	config.set_value("settings", "not_a_setting", 42)
	config.save(PATH)

	var store := _store(_defs())
	assert_eq(store.load_from_disk(), OK)
	assert_eq(store.get_value(&"hints"), true)
	assert_eq(store.get_value(&"volume"), 0.5)
	assert_eq(store.get_value(&"difficulty"), "normal")
	assert_push_error_count(0)


func test_reset_and_reset_all() -> void:
	var store := _store(_defs())
	store.set_value(&"hints", false)
	store.set_value(&"difficulty", "hard")
	watch_signals(store)

	store.reset(&"hints")
	assert_eq(store.get_value(&"hints"), true)
	assert_signal_emitted_with_parameters(store, "setting_changed", [&"hints", true])

	store.reset_all()
	assert_eq(store.get_value(&"difficulty"), "normal")
	assert_signal_emitted_with_parameters(store, "setting_changed", [&"difficulty", "normal"])
	# hints once, difficulty once; volume never left its default.
	assert_signal_emit_count(store, "setting_changed", 2)


func test_duplicate_key_is_reported() -> void:
	var defs := _defs()
	defs.append(_defs()[0])
	_store(defs)
	assert_push_error("share the key")


func test_get_definitions_skips_empty_slots_and_duplicates() -> void:
	var defs := _defs()
	var duplicate := SettingToggleDef.new()
	duplicate.key = &"hints"
	defs.insert(1, null)
	defs.append(duplicate)
	var store := _store(defs)
	var listed := store.get_definitions()
	assert_eq(listed.size(), 3)
	assert_false(listed.has(null))
	assert_false(listed.has(duplicate))
	assert_eq(listed[0].key, &"hints", "listed order is kept")
	listed.clear()
	assert_eq(store.get_definitions().size(), 3, "callers cannot change the store's list")
	assert_push_error("share the key")


func test_applier_sets_and_mutes_audio_bus() -> void:
	AudioServer.add_bus()
	var bus := AudioServer.bus_count - 1
	AudioServer.set_bus_name(bus, BUS)

	var store := _store(_defs())
	var applier := SettingsApplier.new()
	applier.store = store
	add_child_autofree(applier)

	assert_almost_eq(AudioServer.get_bus_volume_db(bus), linear_to_db(0.5), 0.001, "applied on load")
	store.set_value(&"volume", 1.0)
	assert_almost_eq(AudioServer.get_bus_volume_db(bus), 0.0, 0.001)
	assert_false(AudioServer.is_bus_mute(bus))
	store.set_value(&"volume", 0.0)
	assert_true(AudioServer.is_bus_mute(bus))

	AudioServer.remove_bus(bus)


func test_applier_skips_missing_bus_without_crashing() -> void:
	var store := _store(_defs())
	var applier := SettingsApplier.new()
	applier.store = store
	add_child_autofree(applier)
	store.set_value(&"volume", 0.2)
	assert_push_warning_count(1)
