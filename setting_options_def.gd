class_name SettingOptionsDef
extends SettingDef
## One choice from a fixed list. Stored as String (one of values).

## The allowed stored values, for example locale codes.
@export var values: PackedStringArray
## Text shown for each value, in the same order; translation keys.
@export var labels: PackedStringArray
@export var default_value: String


func get_default() -> Variant:
	return default_value


func sanitize(value: Variant) -> Variant:
	return value if value is String and value in values else null
