# ActionItem.gd
# Toolbar item that triggers an immediate callback when clicked
class_name ActionItem
extends ToolbarItem

signal action_triggered(item_id: String)

func _on_clicked() -> void:
	item_activated.emit()
	action_triggered.emit(item_id)
	
	var toolbar = _get_parent_toolbar()
	if toolbar != null:
		toolbar._on_action_item_clicked(self)
