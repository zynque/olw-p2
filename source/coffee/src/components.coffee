components =
	
	box: (content) ->
		style = "margin: 10px;padding: 5px;border-style: solid;border: 2px solid black;display: inline;"
		box = $("<div class='box_round' style='" + style + "'></div>")
		box.append(content)
		box
	
	arrow: () -> $("<div style='font-size:160%; display: inline;'>=&gt</div>")

	columns: (cols...) ->
		columns = $("<div></div>")
		columns.append(col) for col in cols
		columns

	rows: (rows...) ->
		wrapper = $("<div></div>")
		addRow = (r) ->
			wrapper.append(r)
			wrapper.append($("<br></br>"))
		addRow(row) for row in rows
		wrapper
		
	label: (reactiveProperty) ->
		span = $("<span></span>")
		span.html(reactiveProperty.currentValue)
		span.showProperty(reactiveProperty)
		span
		
	# inputProperty & outputProperty?
	textBox: (reactiveProperty) ->
		textBox = $("<input type='text' value='" + reactiveProperty.currentValue + "' />")
		delayedTrigger = (it, e) ->
			setTimeout((->reactiveProperty.reactTo(textBox.val())), 0)
		textBox.on("keypress", delayedTrigger)
		textBox.on("keydown", delayedTrigger)
		textBox.on("cut", delayedTrigger)
		textBox.on("paste", delayedTrigger)
		textBox
	
	button: (labelProperty, inputProperty, outputProperty) ->
		currentValue = inputProperty.currentValue
		button = $("<button>" + labelProperty.currentValue + "</button>")
		labelProperty.addReactor((label) -> button.text(label))
		inputProperty.addReactor((newValue) -> currentValue = newValue)
		button.on("click", (->outputProperty.reactTo(currentValue)))
		button
			 
window.components = components
