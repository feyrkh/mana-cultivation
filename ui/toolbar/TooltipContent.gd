# TooltipContent.gd
# Defines the content for a tooltip, including text and links to nested tooltips
class_name TooltipContent
extends VBoxContainer

signal link_clicked(tooltip_id: String)

var tooltip_id: String = ""
var title_text: String = ""
var body_text: String = ""
var links: Array[Dictionary] = []  # Array of {text: String, tooltip_id: String}

func _ready() -> void:
	_build_content()

func set_data(p_tooltip_id: String, p_title: String, p_body: String, p_links: Array[Dictionary] = []) -> void:
	tooltip_id = p_tooltip_id
	title_text = p_title
	body_text = p_body
	links = p_links
	
	if is_inside_tree():
		_build_content()

func _build_content() -> void:
	# Clear existing children
	for child in get_children():
		child.queue_free()
	
	# Title
	if not title_text.is_empty():
		var title = Label.new()
		title.text = title_text
		title.add_theme_font_size_override("font_size", 14)
		title.add_theme_color_override("font_color", Color(1, 1, 0.8))
		add_child(title)
		
		var separator = HSeparator.new()
		add_child(separator)
	
	# Body
	if not body_text.is_empty():
		var body = Label.new()
		body.text = body_text
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.custom_minimum_size = Vector2(200, 0)
		add_child(body)
	
	# Links
	if not links.is_empty():
		add_child(HSeparator.new())
		
		var links_label = Label.new()
		links_label.text = "See also:"
		links_label.add_theme_font_size_override("font_size", 10)
		add_child(links_label)
		
		for link in links:
			var link_button = Button.new()
			link_button.text = "→ " + link.text
			link_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			link_button.pressed.connect(_on_link_pressed.bind(link.tooltip_id))
			add_child(link_button)

func _on_link_pressed(target_tooltip_id: String) -> void:
	link_clicked.emit(target_tooltip_id)
