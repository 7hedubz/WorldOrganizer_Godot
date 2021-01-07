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
signal deleteRel(idx)
signal changeTree(idx)

#SIGNAL CONNECTIONS
func _on_GUI_updateInfo(itemInfoClass):
	clear()
	
	if itemInfoClass:
		for ea in itemInfoClass.rels:
			add_item(ea[0].get_text(0))
	
		if itemInfoClass.memory:
			if !itemInfoClass.memory[0]:
				select(itemInfoClass.memory[1])

func _on_GUI_categoryMode(categoryMode):
	if categoryMode:
		unselect_all()

func _on_Rels_ItemList_item_rmb_selected(_index, _position):
	contextMenu.popup(Rect2(get_global_mouse_position() + Vector2(0,0), Vector2(100,20)))

func _on_contextMenu_id_pressed(idx):
	if !idx:
		emit_signal("deleteRel", get_selected_items()[0])

func _on_Rels_ItemList_item_activated(index):
	emit_signal("changeTree", index)
