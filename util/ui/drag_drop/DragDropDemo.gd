# DragDropDemo.gd
# Example usage of DragDropContainer
extends Control

func _ready() -> void:
	setup_vertical_example()
	setup_horizontal_example()

func setup_vertical_example() -> void:
	# Create main layout
	var main_vbox = HBoxContainer.new()
	main_vbox.position = Vector2(20, 20)
	add_child(main_vbox)
	
	# Title
	var title = Label.new()
	title.text = "Vertical Drag & Drop List"
	title.add_theme_font_size_override("font_size", 20)
	main_vbox.add_child(title)
	
	# Create drag-drop container
	var drag_container = DragDropContainer.new()
	drag_container.orientation = DragDropContainer.Orientation.VERTICAL
	drag_container.spacing = 8
	drag_container.custom_minimum_size = Vector2(300, 0)
	drag_container.items_reordered.connect(_on_vertical_items_reordered)
	main_vbox.add_child(drag_container)
	
	# Add some items
	for i in range(5):
		var item = create_list_item("Item " + str(i + 1))
		drag_container.add_child(item)
	
	# Add button to add new items
	var add_button = Button.new()
	add_button.text = "Add Item"
	add_button.pressed.connect(_on_add_vertical_item.bind(drag_container))
	main_vbox.add_child(add_button)

func setup_horizontal_example() -> void:
	# Create main layout
	var main_vbox = VBoxContainer.new()
	main_vbox.position = Vector2(20, 550)
	add_child(main_vbox)
	
	# Title
	var title = Label.new()
	title.text = "Horizontal Drag & Drop List"
	title.add_theme_font_size_override("font_size", 20)
	main_vbox.add_child(title)
	
	# Create drag-drop container
	var drag_container = DragDropContainer.new()
	drag_container.orientation = DragDropContainer.Orientation.HORIZONTAL
	drag_container.spacing = 8
	drag_container.custom_minimum_size = Vector2(0, 100)
	drag_container.items_reordered.connect(_on_horizontal_items_reordered)
	main_vbox.add_child(drag_container)
	
	# Add some items
	for i in range(5):
		var item = create_horizontal_item("Tab " + str(i + 1))
		drag_container.add_child(item)

func create_list_item(text: String) -> Panel:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(280, 50)
	
	var hbox = HBoxContainer.new()
	hbox.position = Vector2(10, 10)
	panel.add_child(hbox)
	
	var label = Label.new()
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(label)
	
	return panel

func create_horizontal_item(text: String) -> Panel:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(100, 80)
	
	var label = Label.new()
	label.text = text
	label.position = Vector2(10, 10)
	panel.add_child(label)
	
	return panel

func _on_add_vertical_item(container: DragDropContainer) -> void:
	var new_item = create_list_item("Item " + str(container.get_child_count() + 1))
	container.add_child(new_item)

func _on_vertical_items_reordered(new_order: Array[Node]) -> void:
	print("Vertical list reordered:")
	for i in range(new_order.size()):
		var item = new_order[i]
		var label_text = _get_label_text(item)
		print("  " + str(i + 1) + ". " + label_text)

func _on_horizontal_items_reordered(new_order: Array[Node]) -> void:
	print("Horizontal list reordered:")
	for i in range(new_order.size()):
		var item = new_order[i]
		var label_text = _get_label_text(item)
		print("  " + str(i + 1) + ". " + label_text)

func _get_label_text(item: Node) -> String:
	var label_text = ""
	
	# Find the label in the item
	if item.get_child_count() > 0:
		var first_child = item.get_child(0)
		if first_child is HBoxContainer and first_child.get_child_count() > 0:
			var label = first_child.get_child(0)
			if label is Label:
				label_text = label.text
		elif first_child is Label:
			label_text = first_child.text
	
	return label_text
