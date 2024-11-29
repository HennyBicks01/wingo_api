extends Control

const GRID_SIZE = 5
var bingo_cells = []
var current_page = ""

# List of random Wikipedia pages to use
var wiki_pages = [
	"Dog", "Cat", "Internet", "Wiki", "Tiger",
	"Pizza", "Hamburger", "Sushi", "Pasta", "Ice_cream",
	"Guitar", "Piano", "Drums", "Violin", "Flute",
	"Basketball", "Football", "Tennis", "Baseball", "Golf",
	"Moon", "Sun", "Mars", "Jupiter", "Saturn"
]

func _ready():
	setup_bingo_board()
	$WikiContent/VBoxContainer.page_loaded.connect(_on_page_loaded)
	$WikiContent/VBoxContainer.load_wiki_page("Wikipedia")

func setup_bingo_board():
	var bingo_grid = $BingoBoard
	wiki_pages.shuffle()  # Randomize the pages
	
	# Create 5x5 grid of panels
	for i in range(GRID_SIZE * GRID_SIZE):
		var panel = Panel.new()
		var label = Label.new()
		panel.custom_minimum_size = Vector2(100, 100)
		
		label.text = wiki_pages[i].replace("_", " ")
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_WORD_ELLIPSIS
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		label.custom_minimum_size = Vector2(90, 90)
		
		# Make the panel clickable
		panel.gui_input.connect(_on_panel_clicked.bind(wiki_pages[i]))
		
		panel.add_child(label)
		label.anchor_left = 0
		label.anchor_top = 0
		label.anchor_right = 1
		label.anchor_bottom = 1
		label.offset_left = 5
		label.offset_top = 5
		label.offset_right = -5
		label.offset_bottom = -5
		
		bingo_grid.add_child(panel)
		bingo_cells.append(panel)

func _on_panel_clicked(event: InputEvent, page_name: String):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			$WikiContent/VBoxContainer.load_wiki_page(page_name)

func _on_page_loaded(page_name: String):
	current_page = page_name
	check_page_match(current_page)

func check_page_match(page_name: String):
	print("Checking page name: ", page_name)
	
	# Check if this page matches any of our bingo squares
	for i in range(wiki_pages.size()):
		if wiki_pages[i].to_lower() == page_name.to_lower():
			print("Found match! Marking square ", i)
			bingo_cells[i].modulate = Color(0.5, 1, 0.5)  # Green tint for visited pages
		elif page_name.to_lower().begins_with(wiki_pages[i].to_lower()):
			print("Found partial match! Marking square ", i)
			bingo_cells[i].modulate = Color(0.5, 1, 0.5)  # Green tint for visited pages
