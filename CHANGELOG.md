# Changelog

## Unreleased (will be v0.1.0)

- Added `SettingDef`, `SettingToggleDef`, `SettingSliderDef` and `SettingOptionsDef`.
- Added `SettingsStore`: holds values, saves and loads them with `ConfigFile`.
- Added `SettingsApplier`: applies audio bus volume, fullscreen, vsync and locale.
- Added `demo/settings_demo.tscn` and the tests in `tests/`.
- `get_definitions()` now skips empty slots and duplicate keys and returns a copy.
