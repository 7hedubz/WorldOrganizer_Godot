extends TextEdit

#VARIABLES
var currentClass

#CLASSES

#FUNCTIONS

#SIGNALS
signal textChanged(text)

#SIGNAL CONNECTIONS

func _on_selectionDesc_TextEdit_text_changed():
	emit_signal("textChanged", get_text())

func _on_GUI_updateInfo(itemInfoClass):
	currentClass = itemInfoClass

func _on_GUI_updateSelectionDesc(Category, idx):
	if Category == null:
		set_text("")
		set_readonly(true)
	elif Category:
		set_text(currentClass.categories[idx][1])
		set_readonly(false)
	elif !Category:
		set_text(currentClass.rels[idx][1])
		set_readonly(false)
