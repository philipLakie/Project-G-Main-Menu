# Changelog

## Unreleased (will be v0.1.0)

- Repository created with the v0.1.0 spec as README.
- Added `MenuMainScreen` (`main_menu.tscn`), `default_theme.tres` and the demo scene.
- Added `MenuSettingsScreen` (`settings_screen.tscn`) and the `MenuSettingLabel` / `MenuCategoryLabel` theme variations; the demo now opens it.
- Settings screen: the list follows focus, so keyboard and gamepad reach every row; sliders with `step = 0` move by `free_slider_presses` steps.
- Added `MenuPauseScreen` (`pause_menu.tscn`).
- Settings screen runs while the tree is paused, so it works when opened from the pause menu.
