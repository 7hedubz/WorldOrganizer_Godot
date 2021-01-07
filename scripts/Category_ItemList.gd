extends ItemList

#VARIABLES
var contextMenu = PopupMenu.new()

#CLASSES

#FUNCTIONS
func _ready():
	add_child(contextMenu)
	
	contextMenu.add_item("Delete")
	set_allow_rmb_select(true)
	
	contextMenu.connect("id_pressed", self, "_on_contextMenu_id_pressed")
	
#SIGNALS
signal deleteCat(id)

func _on_GUI_createCategory(textValue):
	add_item(textValue)

func _on_GUI_updateInfo(itemInfoClass):
	clear()
	if itemInfoClass:
		for ea in itemInfoClass.categories:
			add_item(ea[0])

		if itemInfoClass.memory:
			if itemInfoClass.memory[0]:
				select(itemInfoClass.memory[1])

func _on_GUI_categoryMode(categoryMode):
	if !categoryMode:
		unselect_all()

func _on_contextMenu_id_pressed(id):
	if !id:
		emit_signal("deleteCat", get_selected_items()[0])

func _on_Category_ItemList_item_rmb_selected(_index, _at_position):
		contextMenu.popup(Rect2(get_global_mouse_position() + Vector2(0,0), Vector2(100,20)))
