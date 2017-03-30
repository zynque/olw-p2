describe "jqueryReactive", () ->

	observedValue = ""
	observedValue2 = ""
	reactor = (v) -> observedValue = v
	reactor2 = (v) -> observedValue2 = v
	reactiveValue = undefined
	reactiveValue2 = undefined
			
	beforeEach () ->
		observedValue = "original value"
		observedValue2 = "original value2"
		reactiveValue = reactive.new()
		reactiveValue2 = reactive.new()
		
	keypress = (key) -> jQuery.Event("keypress", {which: key.charCodeAt(0)})
	
	toJQuerySelection = (jQueryNodes...) ->
		selection = $([])
		selection = selection.add(node) for node in jQueryNodes
		selection
	
	beforeEach () ->
		observedValue = "original value"
		observedValue2 = "original value2"
		reactiveValue = reactive.new()
		reactiveValue2 = reactive.new()
			
	describe "the reactive extension", () ->
		it "can generate a reactive value from a text input", () ->
			textInput = $("<input type='text' value='a'/>")
			reactiveTextValues = textInput.createReactiveProperty(
				textInput.val(), "keypress", (it, e) ->
					it.value + String.fromCharCode(e.which))
			reactiveTextValues.addReactor reactor			
			expect(observedValue).toEqual("a")
			textInput.trigger(keypress("b"))
			expect(observedValue).toEqual("ab")
			textInput.val(textInput.val() + "b")
			textInput.trigger(keypress("c"))
			expect(observedValue).toEqual("abc")
			
		it "can attach a reactive value to a text input", () ->
			textInput = $("<input type='text' value='a'/>")
			reactiveTextValues = new reactive.property("a")
			textInput.setReactiveProperty(reactiveTextValues, "keypress", (it, e) ->
				it.value + String.fromCharCode(e.which))
			reactiveTextValues.addReactor reactor			
			expect(observedValue).toEqual("a")
			textInput.trigger(keypress("b"))
			expect(observedValue).toEqual("ab")
			textInput.val(textInput.val() + "b")
			textInput.trigger(keypress("c"))
			expect(observedValue).toEqual("abc")

		it "can generate a reactive value from multiple buttons", () ->
			button1 = $("<button id='b1' />")
			button2 = $("<button id='b2' />")
			buttons = toJQuerySelection(button1, button2)
			reactiveClicks = buttons.reactive("click")
			reactiveClicks.addReactor reactor
			button1.trigger("click")
			expect($(observedValue).attr("id")).toEqual("b1")
			button2.trigger("click")
			expect($(observedValue).attr("id")).toEqual("b2")

	describe "the show extension", () ->
		it "can show a reactive value in a span", () ->
			span = $("<span>original value</span>")
			span.show(reactiveValue)
			reactiveValue.reactTo("new value")
			expect(span.html()).toEqual("new value")

		it "can show a reactive property in a span", () ->
			reactiveProperty = new reactive.property "initial value"
			span = $("<span></span>")
			span.showProperty(reactiveProperty)
			expect(span.html()).toEqual("initial value")
			reactiveProperty.reactTo("new value")
			expect(span.html()).toEqual("new value")
			
		it "can show a reactive value in multple divs", () ->
			div1 = $("<div>original value</div>")
			div2 = $("<div>original value</div>")
			divs = toJQuerySelection(div1, div2)
			divs.show(reactiveValue)
			reactiveValue.reactTo("new value")
			expect(div1.html()).toEqual("new value")
			expect(div2.html()).toEqual("new value")
		
		it "can show a reactive value as a textbox's value", () ->
			textInput = $("<input type='text' value='original value' />")
			textInput.show(reactiveValue, (input, v) -> $(input).val(v))
			reactiveValue.reactTo("new value")
			expect(textInput.val()).toEqual("new value")
