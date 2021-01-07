extends FileDialog

# Called when the node enters the scene tree for the first time.
func _ready():
	set_filters(PoolStringArray(["*.7wo ; World Organizer Files"]))

