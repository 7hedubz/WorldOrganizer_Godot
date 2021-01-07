extends Tree
#The tree is the users visual representation of their world. They should be able to re-arrange it at anytime,
#Easily rename, and select anything inside of it

#VARIABLES
var root
var currItem
var itemToCopy
var itemToRel
var relMode = false

var contextMenu = PopupMenu.new()
var moveContextMenu = PopupMenu.new()

var mouseInside = false
var lastLMBClick = 0

var timeToClick = 1 #Time in seconds the user has for a series of clicks to be counted as double

#CLASSES

#FUNCTIONS
func _ready(): # Called when the node enters the scene tree for the first time.
	#Setup the root
	root = create_item()
	set_hide_root(true)
	
	#Setup the popupMenu
	add_child(contextMenu)
	moveContextMenu.name = "moveContextMenu"
	
	moveContextMenu.add_item("Move This") #Functionality complete
	moveContextMenu.add_item("Move Above") #Functionality complete
	moveContextMenu.add_item("Move Below") #Functionality complete
	moveContextMenu.add_item("Child To") #Functionality complete
	
	contextMenu.add_child(moveContextMenu)
	contextMenu.add_submenu_item("MOVE!", "moveContextMenu")
	contextMenu.add_item("Create Relationship With ...") #Functionality complete
	contextMenu.add_item("Unselect Item") #Functionality complete
	contextMenu.add_item("Delete") #Functionality complete
	
	contextMenu.connect("id_pressed", self, "_on_contextMenu_id_pressed")
	moveContextMenu.connect("id_pressed", self, "_on_moveContextMenu_id_pressed")
	
	emit_signal("rootItem", root)

func _input(event):
	if event.is_action_pressed("ui_click") and mouseInside: #Used to determine if there is a double click on screen (inside of the Tree item)
		if OS.get_ticks_msec() - lastLMBClick < timeToClick*1000: #If the user clicks within a certain timeframe, we should make the item editable on click
			emit_signal("doubleClicked")
		lastLMBClick = OS.get_ticks_msec()

func get_children_list(item : TreeItem):
	var a = []
	var iterItem = item.get_children()
	while iterItem:
		a.append(iterItem)
		iterItem = iterItem.get_next()
	return a

func get_item_index(): #Returns the index of selected item (within it's first immediate parent)
	var i = 0 #Our counter to find out what the index is
	var parent = currItem.get_parent()
	var iterItem = parent.get_children()
	
	while iterItem != currItem:
		i += 1
		iterItem = iterItem.get_next()
	
	return i

func get_item_length(): #returns an int of how many items are in selected item's tree. Starting at 0
	var i = 0 #Our counter to find out what the length is
	var parent = currItem.get_parent()
	var iterItem = parent.get_children()
	
	while iterItem:
		i += 1
		iterItem = iterItem.get_next()
	
	return i

func makeCopy(where): #anytime we want to move an item this is called.
	var a
	#ID - 1 - MOVE ABOVE
	#ID - 2 - MOVE BELOW
	#ID - 3 - CHILD TO
	if where == 1:
		if !currItem.get_prev(): #If there is nothing before this
			a = _on_GUI_createChild(currItem.get_parent(), [itemToCopy.get_text(0),itemToCopy.get_text(1)], 0, itemToCopy) #then we need to make it top level to this parent. 
		else: #Otherwise then we need to find out *where* the currItem object is so that we can add the item in question before it.
			a = _on_GUI_createChild(currItem.get_parent(), [itemToCopy.get_text(0),itemToCopy.get_text(1)], get_item_index(), itemToCopy)
	elif where == 2:
		if !currItem.get_next():
			a = _on_GUI_createChild(currItem.get_parent(), [itemToCopy.get_text(0),itemToCopy.get_text(1)], get_item_length(), itemToCopy) #then we need to make it bottom level to this parent. 
		else: #Otherwise then we need to find out *where* the currItem object is so that we can add the item in question before it.
			a = _on_GUI_createChild(currItem.get_parent(), [itemToCopy.get_text(0),itemToCopy.get_text(1)], get_item_index()+1, itemToCopy)
	elif where == 3:
		a = _on_GUI_createChild(currItem, [itemToCopy.get_text(0),itemToCopy.get_text(1)], null, itemToCopy)
	makeCopies(itemToCopy, a, true)
	itemToCopy.free()
	update()

func makeCopies(itemToTraverse : TreeItem, itemToCopyTo, onlyChildren): #Goes through all items in children in order to assure all items are copied correctly.
	if itemToTraverse.get_children() != null: #check down one.  If we have one below us, make it.
		var a = _on_GUI_createChild(itemToCopyTo, [itemToTraverse.get_children().get_text(0), itemToTraverse.get_children().get_text(1)], null, itemToTraverse.get_children())
		makeCopies(itemToTraverse.get_children(), a, false) #Then, we need to see if it has any under or in front of it. 
	if !onlyChildren and itemToTraverse.get_next() != null: #Now we check one in front, If it has one in front, make it.
		var a = _on_GUI_createChild(itemToCopyTo.get_parent(), [itemToTraverse.get_next().get_text(0), itemToTraverse.get_next().get_text(1)], null, itemToTraverse.get_next())
		makeCopies(itemToTraverse.get_next(), a, false)

func setMoveOptions(boolean : bool):
	moveContextMenu.set_item_disabled(1, boolean) # As above
	moveContextMenu.set_item_disabled(2, boolean) # As above
	moveContextMenu.set_item_disabled(3, boolean) # As above

func setRelMode(boolean : bool):
	if boolean:
		itemToRel = currItem
		contextMenu.set_item_text(1, "Stop Relationship Creation")
		get_parent().get_node("Label").set_visible(true)
	else:
		itemToRel = null
		contextMenu.set_item_text(1, "Create Relationship With ...")		
		get_parent().get_node("Label").set_visible(false)
	
	relMode = !relMode
		
func deleteItem():
	emit_signal("deleteItem", currItem)
	currItem.free()
	update()
	if !itemToRel:
		setRelMode(false)

#SIGNALS
signal childCreated(child, textValue, move) #Telling the main logic loop we have completed completing the child in the Tree.
signal selectionChanged(selection) #Tell the MLL the user has selected a new item.
signal itemEdited(newText)
signal doubleClicked()
signal requestToCreateRelationship(itemToRel, currItem)
signal deleteItem(currItem)
signal rootItem(rootItem)

#SIGNAL CONNECTIONS
func _on_GUI_createChild(parent, textValue, index, move = null): #the main logic loop is telling us to create a new child.
	var a
	if parent: #If this is called outside of the "Create Item" button and we want to specify the parent and placement.
		if index != null:
			a = create_item(parent, index)
		else:
			a = create_item(parent)
	else: #Otherwise, create with current item selected
		a = create_item(currItem)	
	a.set_text(0,textValue[0])
	a.set_text(1,textValue[1])
	a.set_text_align(1, 1)
	if !move:
		emit_signal("childCreated", a, textValue, null) #Tell the main logic loop that we have completed creation of a new item
	else:
		emit_signal("childCreated", a, textValue, move) #Tell the main logic loop that we have completed creation of a moved item, a = new item
	return a

func _on_Tree_item_selected(): #The user has selected an item in the Tree
	if currItem:
		currItem.set_editable(0, false)
		currItem.set_editable(1, false)
	currItem = get_selected() #The item selected is stored within currItem
	if currItem == root:
		currItem = null
	emit_signal("selectionChanged", currItem)

func _on_Tree_nothing_selected(): #The user has clicked on empty space, he would like to unselect the treeitem.
	root.select(0)

func _on_Tree_item_rmb_selected(_position): #The user right clicked an object. Select it and open context menu
	_on_Tree_item_selected() #Select item,
	var a = currItem
	if (!itemToCopy) or (currItem == itemToCopy): #If there's nothing to move, or you re-selected what you want to move, then we can't move to.
		setMoveOptions(true)
	elif moveContextMenu.is_item_disabled(1): #Otherwise, we need to make sure that you can select the move to option!
		setMoveOptions(false)
	while a != root:
		if a.get_parent() == itemToCopy:
			setMoveOptions(true)
		a = a.get_parent()
		
		contextMenu.popup(Rect2(get_global_mouse_position() + Vector2(0,0), Vector2(100,20)))

func _on_contextMenu_id_pressed(id):
	if id == 1:
		setRelMode(!relMode)
	if id == 2:
		_on_Tree_nothing_selected()
	elif id == 3:
		deleteItem()

func _on_moveContextMenu_id_pressed(id):
	if id == 0:
		itemToCopy = currItem
	elif id == 1:
		makeCopy(1)
	elif id == 2:
		makeCopy(2)
	elif id == 3:
		makeCopy(3)

func _on_Tree_item_edited():
	emit_signal("itemEdited", [currItem.get_text(0), currItem.get_text(1)])

func _on_Tree_mouse_entered():
	mouseInside = true
func _on_Tree_mouse_exited():
	mouseInside = false

func _on_Tree_doubleClicked():
	if itemToRel:
		if currItem == itemToRel:
			return
		elif currItem == null:
			return
		else:
			emit_signal("requestToCreateRelationship", itemToRel, currItem)
			setRelMode(false)

	elif currItem: #Juuust to make sure we have an item selected.
		currItem.set_editable(0, true) # Make this on click, so on release will make it editable.
		currItem.set_editable(1, true)

func _on_GUI_changeTree(itemToSelect):
	itemToSelect.select(0)


func _on_GUI_updateTree():
	update()
