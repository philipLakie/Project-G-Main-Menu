class_name SettingDef
extends Resource
## Describes one setting. Use a subclass; this base class holds no value.

enum ApplyAs { NONE, AUDIO_BUS_VOLUME, FULLSCREEN, VSYNC, LOCALE }

## Unique id, for example &"music_volume".
@export var key: StringName
## Text shown to the player; a translation key.
@export var label: String
## Grouping for UI, for example &"audio".
@export var category: StringName
## Which engine system SettingsApplier drives with this setting.
@export var apply_as: ApplyAs = ApplyAs.NONE
## Extra data for apply_as; the bus name for AUDIO_BUS_VOLUME.
@export var apply_target: StringName


## The value a setting has until the player changes it.
func get_default() -> Variant:
	return null


## Returns the value in the form it is stored, or null if it is not allowed.
func sanitize(_value: Variant) -> Variant:
	return null
