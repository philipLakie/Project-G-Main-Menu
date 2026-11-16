extends Label
## Placeholder for the game itself: counts seconds, and stops while the tree is
## paused, so pausing can be seen.

var _elapsed := 0.0


func _ready() -> void:
	visibility_changed.connect(func() -> void: _elapsed = 0.0)


func _process(delta: float) -> void:
	_elapsed += delta
	text = tr("Playing: %.1f s. Press Esc to pause.") % _elapsed
