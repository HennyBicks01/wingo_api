extends VBoxContainer

const WIKI_API_ENDPOINT = "https://en.wikipedia.org/w/api.php"

signal page_loaded(page_name: String)

var content_label: RichTextLabel
var loading_label: Label

func _ready():
	setup_wiki_display()
	
func setup_wiki_display():
	# Create RichTextLabel for wiki content
	content_label = RichTextLabel.new()
	content_label.name = "WikiContent"
	content_label.bbcode_enabled = true
	content_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_label.custom_minimum_size = Vector2(600, 500)
	content_label.add_theme_color_override("default_color", Color.BLACK)
	content_label.meta_clicked.connect(_on_link_clicked)
	content_label.selection_enabled = true  # Enable text selection
	add_child(content_label)
	
	# Add a loading label
	loading_label = Label.new()
	loading_label.name = "LoadingLabel"
	loading_label.text = "Loading..."
	loading_label.visible = false
	loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_label.add_theme_color_override("font_color", Color.BLACK)
	add_child(loading_label)

func load_wiki_page(page_name: String):
	loading_label.visible = true
	content_label.text = ""
	
	# Create HTTP request
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_wiki_request_completed)
	
	# Prepare API request
	var query = {
		"action": "query",
		"format": "json",
		"formatversion": "2",
		"titles": page_name.replace(" ", "_"),
		"prop": "extracts|links|redirects|info",
		"pllimit": "max",
		"redirects": "1",
		"origin": "*"
	}
	
	var url = WIKI_API_ENDPOINT + "?" + _dict_to_query_string(query)
	print("Requesting URL: ", url)
	http_request.request(url)

func _dict_to_query_string(dict: Dictionary) -> String:
	var query = []
	for key in dict:
		var value = str(dict[key])
		if key == "titles":
			query.append(key + "=" + value)
		else:
			query.append(key + "=" + value.uri_encode())
	return "&".join(query)

func _on_wiki_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	loading_label.visible = false
	
	if result != HTTPRequest.RESULT_SUCCESS:
		content_label.text = "[color=red]Error loading page: HTTP request failed[/color]"
		print("HTTP Request failed with result: ", result)
		return
		
	if response_code != 200:
		content_label.text = "[color=red]Error loading page: Server returned " + str(response_code) + "[/color]"
		print("Server returned non-200 status code: ", response_code)
		return
	
	var json_string = body.get_string_from_utf8()
	print("Received response length: ", json_string.length())
	
	var json = JSON.new()
	var error = json.parse(json_string)
	
	if error != OK:
		content_label.text = "[color=red]Error parsing JSON: " + json.get_error_message() + " at line " + str(json.get_error_line()) + "[/color]"
		print("JSON Error: ", json.get_error_message(), " at line ", json.get_error_line())
		print("JSON string: ", json_string)
		return
		
	var data = json.get_data()
	
	if not data is Dictionary or not "query" in data:
		content_label.text = "[color=red]Invalid API response format[/color]"
		print("Invalid API response format: ", data)
		return
	
	var pages = data.query.pages
	if pages.size() == 0:
		content_label.text = "[color=red]Page not found[/color]"
		return
		
	var page_data = pages[0]
	var current_page = page_data.title
	
	# Check if we were redirected
	if "redirects" in data.query:
		var redirect = data.query.redirects[0]
		print("Redirected from ", redirect.from, " to ", redirect.to)
		current_page = redirect.to
	
	if "missing" in page_data:
		content_label.text = "[color=red]Page not found[/color]"
		return
	
	if not "extract" in page_data or page_data.extract.strip_edges() == "":
		# Check if there are any alternative links we can suggest
		var alternative_link = ""
		if "links" in page_data and page_data.links.size() > 0:
			for link in page_data.links:
				if not ":" in link.title:  # Skip special pages
					alternative_link = link.title
					break
		
		var message = "[center][b]" + page_data.title + "[/b][/center]\n\n"
		message += "[color=red]This page exists but has no content."
		if alternative_link != "":
			message += "\n\nYou might be looking for: [url=" + alternative_link + "]" + alternative_link.replace("_", " ") + "[/url]"
		content_label.text = message
		return
	
	var content = "[center][b]" + page_data.title + "[/b][/center]\n\n"
	content += _process_wiki_content(page_data)
	
	content_label.text = content
	page_loaded.emit(current_page)

func _process_wiki_content(page_data: Dictionary) -> String:
	if not "extract" in page_data:
		return "[color=red]No content available[/color]"
		
	var content = page_data.extract
	
	# Process links if available
	if "links" in page_data:
		for link in page_data.links:
			if not "title" in link:
				continue
				
			var title = link.title
			# Skip special pages and other namespaces
			if ":" in title:
				continue
			# Replace the text with a BBCode link, using the original title for display
			var display_title = title.replace("_", " ")
			var regex = RegEx.new()
			regex.compile("\\b" + display_title + "\\b")
			content = regex.sub(content, "[url=" + title + "]" + display_title + "[/url]", true)
	
	return content

func _on_link_clicked(meta):
	# Meta will be the page title (with underscores)
	var page_name = str(meta).replace("_", " ")  # Convert underscores back to spaces for display
	load_wiki_page(page_name)
