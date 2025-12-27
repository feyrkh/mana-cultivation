# SelectionItem.gd
# Toolbar item that can be marked as selected
class_name SelectionItem
extends ToolbarItem

signal selection_changed(item_id: String, selected: bool)

func _on_clicked() -> void:
	var toolbar = _get_parent_toolbar()
	if toolbar != null:
		toolbar._on_selection_item_clicked(self)
	
	item_selected.emit()
	selection_changed.emit(item_id, is_selected)
