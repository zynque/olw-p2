describe "reactive", () ->
	
	exampleObject =
		exampleFunction: (input) -> "got: " + input

	exampleObject2 =
		exampleFunction2: (input) -> "hello " + input

		
	describe "using", () ->
		it "pulls functions on an object in as properties on a closure", () ->
			result = "original value"
			using exampleObject, ->
				result = @exampleFunction("this")
			expect(result).toEqual("got: this")
	
	describe "funcContainer", () ->
		it "pulls functions from an object onto itself", () ->
			container = funcContainer.new()
			container.addFuncsFrom(exampleObject)
			container.addFuncsFrom(exampleObject2)
			expect(container.exampleFunction("a")).toEqual("got: a")
			expect(container.exampleFunction2("world")).toEqual("hello world")