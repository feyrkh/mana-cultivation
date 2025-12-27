# ToolbarItem.gd
# Base class for toolbar items
class_name ToolbarItem
extends PanelContainer

signal item_activated()
signal item_selected()

@export var icon: Texture2D
@export var item_text: String = ""
@export var tooltip_id: String = ""  # Reference to tooltip content
@export var item_id: String = ""  # Unique identifier for this item

var is_hovered: bool = false
var is_selected: bool = false

@onready var icon_rect: TextureRect
@onready var label: Label
@onready var selection_indicator: Panel

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)
	
	_setup_ui()

func _setup_ui() -> void:
	# Create visual elements
	var container = VBoxContainer.new()
	container.anchor_right = 1.0
	container.anchor_bottom = 1.0
	add_child(container)
	
	# Selection indicator (background highlight)
	selection_indicator = Panel.new()
	selection_indicator.anchor_right = 1.0
	selection_indicator.anchor_bottom = 1.0
	selection_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selection_indicator.visible = false
	add_child(selection_indicator)
	move_child(selection_indicator, 0)  # Behind everything
	
	# Icon
	if icon != null:
		icon_rect = TextureRect.new()
		icon_rect.texture = icon
		icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.custom_minimum_size = Vector2(32, 32)
		container.add_child(icon_rect)
	
	# Label
	if not item_text.is_empty():
		label = Label.new()
		label.text = item_text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 10)
		container.add_child(label)

func _on_mouse_entered() -> void:
	is_hovered = true
	_update_visual_state()
	_notify_toolbar_hover_start()

func _on_mouse_exited() -> void:
	is_hovered = false
	_update_visual_state()
	_notify_toolbar_hover_end()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_on_clicked()

func _on_clicked() -> void:
	# Override in subclasses
	pass

func set_selected(selected: bool) -> void:
	is_selected = selected
	_update_visual_state()

func _update_visual_state() -> void:
	if selection_indicator != null:
		selection_indicator.visible = is_selected
		
		# Visual feedback for hover
		if is_hovered:
			modulate = Color(1.2, 1.2, 1.2)
		else:
			modulate = Color.WHITE

func _notify_toolbar_hover_start() -> void:
	var toolbar = _get_parent_toolbar()
	if toolbar != null and not tooltip_id.is_empty():
		toolbar._on_item_hover_start(self)

func _notify_toolbar_hover_end() -> void:
	var toolbar = _get_parent_toolbar()
	if toolbar != null:
		toolbar._on_item_hover_end(self)

func _get_parent_toolbar():
	var parent = get_parent()
	while parent != null:
		if parent is Toolbar:
			return parent
		parent = parent.get_parent()
	return null
