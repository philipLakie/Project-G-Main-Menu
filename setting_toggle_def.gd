class_name SettingToggleDef
extends SettingDef
## An on/off setting. Stored as bool.

@export var default_value: bool = false


func get_default() -> Variant:
	return default_value


func sanitize(value: Variant) -> Variant:
	return value if value is bool else null
