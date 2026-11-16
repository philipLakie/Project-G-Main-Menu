# settings

Player preferences for any game: stores the values, saves and loads them, applies the engine-level ones, and tells the game when something changes. It has no UI.

- **Status:** Experimental (`v0.1.0`)
- **Mount path:** `addons/settings/`
- **Class prefix:** `Setting` / `Settings`
- **Depends on:** nothing
- **Rules:** follow `AGENTS.md`. This file says what to build; that file says how to work.

## What it is for

A game describes each setting with a small Resource (a "definition"). The module keeps the current value of each one, writes them to a file, and reads them back at startup. A separate, optional node applies the settings Godot itself understands (volume, fullscreen, vsync, language). Everything else is announced by signal so the game can react.

## Parts

### Definitions (Resources)

`SettingDef` (base class, not used directly). Fields:

| Field | Type | Meaning |
|---|---|---|
| `key` | `StringName` | Unique id, for example `&"music_volume"` |
| `label` | `String` | Text shown to the player; a translation key |
| `category` | `StringName` | Grouping for UI, for example `&"audio"` |
| `apply_as` | enum | `NONE`, `AUDIO_BUS_VOLUME`, `FULLSCREEN`, `VSYNC`, `LOCALE` |
| `apply_target` | `StringName` | Extra data for `apply_as`; the bus name for `AUDIO_BUS_VOLUME` |

Three subclasses, one per kind of value:

| Class | Extra fields | Stored value |
|---|---|---|
| `SettingToggleDef` | `default_value: bool` | `bool` |
| `SettingSliderDef` | `min_value`, `max_value`, `step`, `default_value` (all `float`) | `float` |
| `SettingOptionsDef` | `values: PackedStringArray`, `labels: PackedStringArray`, `default_value: String` | `String` (one of `values`) |

Slider defaults are `min_value = 0.0`, `max_value = 1.0`, `step = 0.01`; a `step` of 0 turns snapping off.

Every definition also has two methods the store calls. A game that adds its own definition type overrides them:

- `get_default() -> Variant`: the value before the player changes anything
- `sanitize(value: Variant) -> Variant`: the value in the form it is stored, or `null` if it is not allowed

### `SettingsStore` (Node)

Holds the values. It does not touch audio, the window or any other engine system, so it is easy to test.

Exports:

- `definitions: Array[SettingDef]`
- `file_path: String = "user://settings.cfg"`
- `auto_save: bool = true` (save after every change)

Methods:

- `get_value(key: StringName) -> Variant`
- `set_value(key: StringName, value: Variant) -> void`
- `reset(key: StringName) -> void` and `reset_all() -> void`
- `get_definition(key: StringName) -> SettingDef` and `get_definitions() -> Array[SettingDef]`
- `save_to_disk() -> Error` and `load_from_disk() -> Error`

Signals:

- `setting_changed(key: StringName, value: Variant)`
- `settings_loaded`

Behaviour:

- In `_ready` it loads the file, then emits `settings_loaded`. A missing file is not an error; every setting takes its default.
- A key missing from the file takes its default. A value of the wrong type or outside the allowed set takes its default. Keys in the file with no definition are ignored.
- `set_value` on a slider clamps to `min_value`..`max_value` and snaps to `step`.
- `set_value` on an options setting with a value not in `values` changes nothing and reports an error.
- `set_value` or `get_value` with an unknown key changes nothing, reports an error, and `get_value` returns `null`.
- `setting_changed` is emitted only when the stored value really changes.
- Calling `load_from_disk` again later re-reads the file and emits `settings_loaded` again (not `setting_changed`).
- `get_definition` with an unknown key returns `null` without an error.
- Two definitions with the same key is a setup error; report it loudly at startup. The second one is ignored.
- Use Godot's `ConfigFile` for the file.

### `SettingsApplier` (Node, optional)

Applies engine-level settings. A game that wants to apply them itself leaves this node out.

Exports:

- `store: SettingsStore`

Behaviour: when the store has loaded, and whenever a setting changes, it looks at that setting's `apply_as`:

| `apply_as` | Definition type | What it does |
|---|---|---|
| `NONE` | any | Nothing. The game listens to `setting_changed`. |
| `AUDIO_BUS_VOLUME` | slider, 0.0 to 1.0 | Sets the volume of the bus named in `apply_target`. Converts linear to decibels. Mutes the bus at 0. |
| `FULLSCREEN` | toggle | Switches the window between fullscreen and windowed. |
| `VSYNC` | toggle | Turns vsync on or off. |
| `LOCALE` | options; `values` are locale codes such as `"en"` | Sets the game's language. |

If the named audio bus does not exist, or the definition type does not match `apply_as`, it warns once and skips that setting. It must never crash.

## How a game uses it

1. Add a `SettingsStore` node (the game may make it an autoload; the module must not assume that).
2. Create one definition Resource per setting and add them to `definitions`.
3. Optionally add a `SettingsApplier` and point it at the store.
4. For game-specific settings, connect to `setting_changed`. Read current values after `settings_loaded`.

## Out of scope for v0.1

- Key rebinding (planned as its own module)
- Screen resolution lists and window size
- Multiple profiles
- Any UI (see `menu_screens`)

## Demo

`demo/settings_demo.tscn`: a store with one of each definition type plus master volume, fullscreen and vsync, and an applier. Plain controls change each value; a label logs every `setting_changed`. Closing and reopening the scene shows the values were saved.

## Tests it must pass

Tests use their own `file_path` (for example `user://test_settings.cfg`) and delete it afterwards.

1. With no file, every setting returns its default.
2. `set_value` then `get_value` returns the new value.
3. `setting_changed` fires once with the right key and value, and does not fire when the value is unchanged.
4. Slider values are clamped and snapped to `step`.
5. An options value not in `values` is rejected and the old value stays.
6. An unknown key is rejected; `get_value` returns `null`.
7. Save, then load in a new store with the same definitions: all values match.
8. A file containing a wrong-type value, or an unknown key, loads without error and falls back to defaults.
9. `reset` and `reset_all` restore defaults and emit `setting_changed` for the keys that changed.
10. Applier: an `AUDIO_BUS_VOLUME` setting changes the volume of a bus the test creates, and mutes it at 0.

Fullscreen, vsync and language are checked by hand in the demo.
