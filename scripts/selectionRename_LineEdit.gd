extends LineEdit
#VARIABLES
#CLASSES
#FUNCTIONS
#SIGNALS
#SIGNAL CONNECTIONS
func _on_GUI_updateInfo(itemInfoClass):
	set_placeholder(itemInfoClass.itemName)
