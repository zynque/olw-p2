describe "components", () ->

	describe "box", () ->
		it "is a div with contents", () ->
			box = components.box("expected content")
			expect(box.get(0).tagName).toEqual("DIV")
			expect(box.html()).toEqual("expected content")
	
	describe "arrow", () ->
		it "is a div with a graphic", () ->
			arrow = components.arrow()
			expect(arrow.get(0).tagName).toEqual("DIV")
			expect(arrow.html()).toEqual("=&gt;")
	
	describe "columns", () ->
		it "is a container for ui elements arranged horizontally", () ->
			columns = components.columns("a", "b")
			expect(columns.get(0).tagName).toEqual("DIV")
			contents = columns.contents()
			expect(contents.length).toEqual(2)
			expect(contents[0].nodeValue).toEqual("a")
			expect(contents[1].nodeValue).toEqual("b")
	
	describe "rows", () ->
		it "needs to be tested", () ->
			expect(1).toEqual(1)
	
	describe "label", () ->
		it "displays attached property", () ->
			reactiveProperty = new reactive.property "initial value"
			label = components.label(reactiveProperty)
			expect(label.get(0).tagName).toEqual("SPAN")
			expect(label.html()).toEqual("initial value")
			reactiveProperty.reactTo("new value")
			expect(label.html()).toEqual("new value")

	keypress = (key) -> jQuery.Event("keypress", {which: key.charCodeAt(0)})
	
	describe "textBox", () ->
		it "updates a reactive property on each keypress", () ->
			jasmine.Clock.useMock()
			reactiveProperty = new reactive.property("initial value")
			textBox = components.textBox(reactiveProperty)
			expect(textBox.val()).toEqual("initial value")
			observedValue = "observed value before"
			reactiveProperty.addReactor((val) -> observedValue = val)
			expect(observedValue).toEqual("initial value")
			textBox.val("updated value")
			textBox.trigger(keypress("a"))
			jasmine.Clock.tick(1)
			expect(observedValue).toEqual("updated value")
			
	describe "button", () ->
		it "propagates latest input property state to output property on click", () ->
			label = new reactive.property("click me")
			inputProperty = new reactive.property("initial input")
			outputProperty = new reactive.property("initial output")
			button = components.button(label, inputProperty, outputProperty)
			propagatedValue = undefined
			outputProperty.addReactor((val) -> propagatedValue = val)
			expect(propagatedValue).toEqual("initial output")
			button.trigger("click")
			expect(propagatedValue).toEqual("initial input")
			inputProperty.reactTo("new value")
			expect(propagatedValue).toEqual("initial input")
			button.trigger("click")
			expect(propagatedValue).toEqual("new value")
		
		it "displays observed values on label", () ->
			label = new reactive.property("click me")
			inputProperty = new reactive.property("initial input")
			outputProperty = new reactive.property("initial output")
			button = components.button(label, inputProperty, outputProperty)
			label.reactTo("new value")
			expect(button.html()).toEqual("new value")
	