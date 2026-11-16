class_name SettingSliderDef
extends SettingDef
## A number in a range. Stored as float.

@export var min_value: float = 0.0
@export var max_value: float = 1.0
## Values snap to multiples of this, counted from min_value. 0 means no snapping.
@export var step: float = 0.01
@export var default_value: float = 0.0


func get_default() -> Variant:
	return default_value


func sanitize(value: Variant) -> Variant:
	if value is not float and value is not int:
		return null
	var number: float = value
	if step > 0.0:
		number = min_value + snappedf(number - min_value, step)
	return clampf(number, min_value, max_value)
