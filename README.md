# menu_screens

Plain, ready-made menu screens for any game: main menu, pause menu and settings screen. They are deliberately unstyled. Each game supplies its own Theme and decides what the buttons do.

- **Status:** Experimental (`v0.1.0`)
- **Built so far:** `MenuMainScreen` only. The pause menu and settings screen are not implemented yet.
- **Mount path:** `addons/menu_screens/`
- **Class prefix:** `Menu`
- **Depends on:** `settings` `v0.1.0` or newer (the settings screen reads its definitions and store)
- **Works with, but does not need:** `screen_nav`
- **Rules:** follow `AGENTS.md`. This file says what to build; that file says how to work.

## What it is for

Every game needs these three screens. This module provides their layout and behaviour, and nothing else. Screens show state and emit signals; they contain no game rules and never change scenes, quit the game or save anything themselves.

## Rules specific to this module

- Build screens only from containers and standard controls. No images, no custom drawing.
- No colours, fonts or sizes in scripts, and no per-node theme overrides. All appearance comes from the Theme.
- Every visible string goes through `tr()`.
- Every screen works with keyboard or gamepad only. Each screen has a `get_initial_focus() -> Control` method that returns the control to focus first.
- Lay out with containers and anchors so the screens resize cleanly.

## Theming

The module ships `default_theme.tres`, a plain theme, used only by the demo. Screens use these theme type variations:

| Variation | Based on | Used for |
|---|---|---|
| `MenuTitle` | `Label` | The heading of each screen |
| `MenuPanel` | `PanelContainer` | The box around a screen's content |
| `MenuItemButton` | `Button` | Main and pause menu buttons |
| `MenuSettingLabel` | `Label` | The name of a setting in a row |
| `MenuCategoryLabel` | `Label` | A category heading on the settings screen |

A game restyles everything by assigning its own Theme to the UI root and defining these five variations in it. Anything not defined falls back to the game's normal `Label`, `Button` and `PanelContainer` styles.

## Parts

### `MenuMainScreen` (`main_menu.tscn`)

Exports:

- `title_text: String` (empty hides the title)
- `show_continue: bool = false`
- `show_quit: bool = true` (a game hides this on web and mobile)

Signals: `start_pressed`, `continue_pressed`, `settings_pressed`, `quit_pressed`

Method: `get_initial_focus() -> Control` returns Continue when it is shown, otherwise Start. The screen does not grab focus itself; whoever shows it does. If a change hides the button that has focus, focus moves to `get_initial_focus()`.

Scene-unique nodes, for tests and for games that need to reach them: `%Title`, `%ContinueButton`, `%StartButton`, `%SettingsButton`, `%QuitButton`.

### `MenuPauseScreen` (`pause_menu.tscn`)

Exports:

- `show_quit: bool = true`

Signals: `resume_pressed`, `settings_pressed`, `main_menu_pressed`, `quit_pressed`, `back_requested`

Pressing Resume emits both `resume_pressed` and `back_requested`.

### `MenuSettingsScreen` (`settings_screen.tscn`)

Method:

- `setup(store: SettingsStore) -> void`: builds the screen from the store. Rows are built here, not in `_ready`, because the game calls `setup` after adding the screen.

Signals: `back_requested`

Behaviour:

- One row per definition in the store, grouped under a heading per `category`, in the order the definitions are listed.
- The control depends on the definition type: toggle gives a `CheckButton`, slider gives an `HSlider` using the definition's min, max and step, options gives an `OptionButton` showing `labels`.
- Changing a control calls `store.set_value` straight away. There is no Apply button.
- The screen listens to `store.setting_changed` and updates its controls, so it stays correct if a value changes elsewhere or is rejected.
- A "Reset to defaults" button calls `store.reset_all()`.
- A "Back" button emits `back_requested`.
- A definition type the screen does not recognise is skipped with a warning.
- A new definition added by the game appears with no change to this module.

## How a game uses it

This wiring lives in the game, not in any module:

```gdscript
# game/menus.gd
extends Node

@export var stack: ScreenStack
@export var store: SettingsStore
@export var main_menu_scene: PackedScene
@export var settings_scene: PackedScene


func _ready() -> void:
	var main := stack.push(main_menu_scene) as MenuMainScreen
	main.start_pressed.connect(_start_game)
	main.settings_pressed.connect(_open_settings)
	main.quit_pressed.connect(get_tree().quit)


func _open_settings() -> void:
	var screen := stack.push(settings_scene) as MenuSettingsScreen
	screen.setup(store)


func _start_game() -> void:
	pass  # the game decides what starting means
```

Because the screens have `back_requested` and `get_initial_focus()`, `screen_nav` handles Back and focus for them with no extra code.

## Out of scope for v0.1

- Key rebinding screen
- Save slot or load game screens
- Credits screen
- Animations and sound effects

## Demo

**Currently:** the demo shows the main menu only, with toggles for `show_continue` and `show_quit` and a log of every signal. The parts below arrive with the other screens.

`demo/menu_screens_demo.tscn` uses only this module and `settings`:

- Buttons to show each of the three screens, and a log label that prints every signal a screen emits.
- The settings screen is connected to a demo store with one of each definition type plus master volume and fullscreen.
- A "Swap theme" button switches between `default_theme.tres` and a second, clearly different demo theme while the screen is open. Everything must restyle with no script changes.

## Tests it must pass

1. Each main menu and pause menu button emits its signal once when pressed.
2. `show_continue` and `show_quit` hide and show their buttons.
3. `get_initial_focus()` returns a visible, focusable control on every screen.
4. After `setup`, the settings screen has one row per definition, with the right control type for each.
5. Changing a row's control changes the value in the store.
6. Changing a value in the store updates the row's control.
7. "Reset to defaults" restores every default in the store and in the controls.
8. "Back" emits `back_requested`.
9. Calling `setup` twice does not create duplicate rows.

Checked by hand in the demo: theme swap, resizing the window, and using every screen with keyboard or gamepad only.
