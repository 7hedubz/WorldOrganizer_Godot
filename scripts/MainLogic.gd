extends MarginContainer
#This will be the main program logic, it needs access to all commands and will issue all orders.

#VARIABLES
var treeitem_lineEditText = ""
var category_lineEditText = ""
var itemDict = {"default" : itemInfo.new()} #FORMAT = { referenceToTreeItem : class, ... }
var currItem
var category
var idx
var list = []

var gSaveID : int
var saveRoot
var dataToSave = []
var prevPath = ""
var lastItemLoaded : TreeItem

#CLASSES
class itemInfo:
	var itemName = ["", ""]
	var categories = [] #List of lists formatted [ [ "Name of Category", "Contents of Category"], ... ]
	var rels = [] #List of lists formatted [ [referenceToTreeItem, "Contents of relationship"], ... ]
	var memory = null
	var saveID = -1
	
#FUNCTIONS
func _ready():
	itemDict["default"].itemName = "Rename Selection Here"

func _input(event):
	if event.is_action_pressed("ui_save"):
		if prevPath:
			saveData(prevPath)
		else:
			openSaveDialog()

func openSaveDialog():
	if saveRoot.get_children() == null:
		return
	$SaveDialog.popup()
func openLoadDialog():
	$loadDialog.popup()

func get_item_length(parent): #returns an int of how many items are in selected item's tree. Starting at 0
	var i = 0 #Our counter to find out what the length is
	var iterItem = parent.get_children()
	
	while iterItem:
		i += 1
		iterItem = iterItem.get_next()
	
	return i

#SAVE FORMAT = [ID NO, PARENT ID || NULL (If no parent), [itemNames], Categories, relationships FORMAT = [ID NO, Contents]] 
func savePass(iterItem, childrenOnly):
	if iterItem.get_children() != null:
		var i = -1
		var a = []
		for each in itemDict[iterItem.get_children()].rels.size():
			i += 1
			a.append([itemDict[itemDict[iterItem.get_children()].rels[i][0]].saveID, itemDict[iterItem.get_children()].rels[i][1]])
		dataToSave.append([itemDict[iterItem.get_children()].saveID, itemDict[iterItem.get_children().get_parent()].saveID, itemDict[iterItem.get_children()].itemName, itemDict[iterItem.get_children()].categories, a])
		savePass(iterItem.get_children(), false)
	if !childrenOnly and iterItem.get_next() != null:
		var i = -1
		var a = []
		for each in itemDict[iterItem.get_next()].rels.size():
			i += 1
			a.append([itemDict[itemDict[iterItem.get_next()].rels[i][0]].saveID, itemDict[iterItem.get_next()].rels[i][1]])
		dataToSave.append([itemDict[iterItem.get_next()].saveID, itemDict[iterItem.get_next().get_parent()].saveID, itemDict[iterItem.get_next()].itemName, itemDict[iterItem.get_next()].categories, a])
		savePass(iterItem.get_next(), false)

func idPass(iterItem):
	if iterItem.get_children() != null:
		itemDict[iterItem.get_children()].saveID = gSaveID
		gSaveID += 1
		idPass(iterItem.get_children())
	if iterItem.get_next() != null:
		itemDict[iterItem.get_next()].saveID = gSaveID
		gSaveID += 1
		idPass(iterItem.get_next())

func saveData(path):
	if saveRoot.get_children() == null:
		return
		
	var save_game = File.new()
	save_game.open(path, File.WRITE)

	gSaveID = 0
	dataToSave = [] #FORMAT = [ID NO, PARENT ID || NULL (If no parent), itemName, Categories, relationships FORMAT = [ID NO, Contents]] 
	var iterItem : TreeItem
	
	idPass(saveRoot)
	
	iterItem = saveRoot.get_children()
	for ea in get_item_length(saveRoot):
		var i = -1
		var a = []
		
		if itemDict[iterItem].rels.size() > 0:
			for each in itemDict[iterItem].rels.size():
				i += 1
				a.append([itemDict[itemDict[iterItem].rels[i][0]].saveID, itemDict[iterItem].rels[i][1]])
		
		dataToSave.append([itemDict[iterItem].saveID, null, itemDict[iterItem].itemName, itemDict[iterItem].categories, a])
		
		savePass(iterItem, true)
		
		iterItem = iterItem.get_next()
		
	save_game.store_line(to_json(dataToSave))
	save_game.close()
	
	prevPath = path
	
func loadData(path):
	# Pull the data to be loaded from a user specified file
	var load_game = File.new()
	load_game.open(path, File.READ)
	var loadData = parse_json(load_game.get_as_text())
	load_game.close()
	#Clear the current tree so we can load in the new data
	var iterItem = saveRoot.get_children()
	var a = []
	for ea in get_item_length(saveRoot):
		a.append(iterItem)
		iterItem = iterItem.get_next()
	for ea in a:
		ea.free()
	emit_signal("updateTree")
	emit_signal("updateInfo", null)
	emit_signal("updateSelectionDesc", null, null)
	itemDict = {"default" : itemInfo.new()}
	
	#Load the data, without rels
	for ea in loadData: # Parent, textvalue, null
		if ea[1] == null:
			emit_signal("createChild", null, ea[2], null)
		if ea[1] != null:
			for eac in itemDict.keys():
				if itemDict[eac].saveID == ea[1]:
					emit_signal("createChild", eac, ea[2], null)
					break

		itemDict[lastItemLoaded].saveID = ea[0]
		itemDict[lastItemLoaded].categories = ea[3]
		itemDict[lastItemLoaded].rels = ea[4] #CURRENTLY [ID NO, CONTENTS]
		
	#Now to fix the connections between relationships
	for ea in itemDict.keys(): #Have to go through everything to fix their rels.
		if itemDict[ea].rels == []:
			continue
		else:
			for rel in itemDict[ea].rels: #Have to go through each relationship, they all need fixed
				for each in itemDict.keys(): #Have to go through everyone in oder to find the matching IDno (partner)
					if rel[0] == itemDict[each].saveID:
						rel[0] = each
						break #If we found it and set it, break out of this loop and mvoe onto the next rel


#SIGNALS
signal createChild(textValue) #tell the Tree to create a child in the tree node.
signal createCategory(textValue) #Tell the Category_List to create a new item.
signal updateInfo(itemInfoClass) #Tell the information section to update with new information
signal updateSelectionDesc(Category, idx)
signal categoryMode(categoryMode)
signal changeTree(itemInfoClass)
signal updateTree()

#SIGNAL CONNECTIONS
func _on_itemName_LineEdit_text_entered(_new_text): #User pressed enter while selecting the name box. Same behavior as pressing button.
	emit_signal("createChild", null, [treeitem_lineEditText, ""], null)

func _on_Button_pressed(): #When user presses "Create Item" Button
	emit_signal("createChild", null, [treeitem_lineEditText, ""], null) # check SIGNALS -> then wait for a signal back telling completion _on_Tree_childCreated

func _on_Tree_childCreated(child, textValue, move): #The tree has finished adding the child to the tree. move = item being moved (item to be deleted)
	if !move:
		itemDict[child] = itemInfo.new() #Add thechild to the dictionary
		itemDict[child].itemName = textValue #Set the name within the class to the name of the newly created child.
	else:
		itemDict[child] = itemDict[move]
		for ea in itemDict.values():
			if ea.rels != []:
				for each in ea.rels:
					if each[0] == move:
						each[0] = child
	lastItemLoaded = child

func _on_Tree_selectionChanged(selection):
	if !selection:
		currItem = null
		emit_signal("updateInfo", null)
		emit_signal("updateSelectionDesc", null, null)
	else:
		currItem = selection
		emit_signal("updateInfo", itemDict[currItem])
		if itemDict[currItem].memory:
			emit_signal("updateSelectionDesc", itemDict[currItem].memory[0], itemDict[currItem].memory[1])
		else:
			emit_signal("updateSelectionDesc", null, null)

func _on_LineEdit_text_changed(new_text): #When user changes the text in the creation Line Edit
	treeitem_lineEditText = new_text #Update the variable in the main logic loop

func _on_selectionDesc_TextEdit_textChanged(text):
	if category:
		itemDict[currItem].categories[idx][1] = text
	if !category:
		itemDict[currItem].rels[idx][1] = text
	
func _on_Tree_itemEdited(newText):
	itemDict[currItem].itemName = newText

func _on_createCategory_Button_pressed(): #When User wants to create a new category by pressing button
	if currItem:
		itemDict[currItem].categories.append([category_lineEditText, ""])
		emit_signal("createCategory", category_lineEditText)

func _on_category_LineEdit_text_entered(_TextFromLabel): #When User wants to create a new category by pressing enter on the text box
	if currItem:
		itemDict[currItem].categories.append([category_lineEditText, ""])
		emit_signal("createCategory", category_lineEditText)

func _on_category_LineEdit_text_changed(new_text): #When the lineEdit for the category changes
	category_lineEditText = new_text

func _on_Category_ItemList_item_selected(index): #Selection has been changed in the category list
	category = true
	idx = index
	itemDict[currItem].memory = [category, idx]
	emit_signal("updateSelectionDesc", true, index)
	emit_signal("categoryMode", category)

func _on_Rels_ItemList_item_selected(index): #Selection has been changed in the rels list
	category = false
	idx = index
	itemDict[currItem].memory = [category, idx]
	emit_signal("updateSelectionDesc", false, index)
	emit_signal("categoryMode", category)

func _on_Tree_requestToCreateRelationship(itemToRel, otherRelItem):
	#Do we already have an existing rel between the two?
	for ea in itemDict[itemToRel].rels:
		if ea[0] == otherRelItem:
			return
	itemDict[itemToRel].rels.append([otherRelItem, ""])
	itemDict[otherRelItem].rels.append([itemToRel, ""])
	emit_signal("updateInfo", itemDict[currItem])

func _on_Rels_ItemList_deleteRel(id):
	var a = -1
	print(itemDict[currItem].rels[id][0])
	for ea in itemDict[itemDict[currItem].rels[id][0]].rels: #list of rels in the mirror match
		a += 1
		if ea[0] == currItem:
			itemDict[itemDict[currItem].rels[id][0]].rels.remove(a)
			itemDict[currItem].rels.remove(id)
			itemDict[currItem].memory = null
			emit_signal("updateInfo", itemDict[currItem])
			emit_signal("updateSelectionDesc", null, null)

func _on_Category_ItemList_deleteCat(id):
	itemDict[currItem].categories.remove(id)
	itemDict[currItem].memory = null
	emit_signal("updateInfo", itemDict[currItem])
	emit_signal("updateSelectionDesc", null, null)

func _on_Tree_deleteItem(itemToDelete):
	var a = -1
	for ea in itemDict.values():
		a += 1
		if a == 0:
			continue #In order to handle the default entry we add this.

		for each in ea.rels:
			if each[0] == itemToDelete:
				ea.rels.erase(each)
	emit_signal("updateInfo", null)

func _on_Rels_ItemList_changeTree(id):
	emit_signal("changeTree", itemDict[currItem].rels[id][0])

func _on_save_Button_pressed():
	openSaveDialog()
	
func _on_load_Button_pressed():
	openLoadDialog()

func _on_Tree_rootItem(rootItem):
	saveRoot = rootItem

func _on_FileDialog_file_selected(path):
	saveData(path)
func _on_loadDialog_file_selected(path):
	loadData(path)
