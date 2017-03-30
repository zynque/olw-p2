describe "reactive", () ->

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
			
	describe "reactive values", () ->
		it "propigate values to all reactors", () ->
			reactiveValue.addReactor reactor
			reactiveValue.addReactor reactor2
			reactiveValue.reactTo "expected value"
			expect(observedValue).toEqual("expected value")
			expect(observedValue2).toEqual("expected value")
		it "filter values", () ->
			gt5 = reactiveValue.filter (v) -> v > 5
			gt5.addReactor reactor
			reactiveValue.reactTo 2
			expect(observedValue).toEqual("original value")
			reactiveValue.reactTo 6
			expect(observedValue).toEqual(6)
		it "map values", () ->
			plus1 = reactiveValue.map (v) -> v + 1
			plus1.addReactor reactor
			reactiveValue.reactTo 2
			expect(observedValue).toEqual(3)

	describe "reactive property", () ->
		it "sends initial value to reactors as they are added", () ->
			property = new reactive.property "initial value"
			property.addReactor reactor
			expect(observedValue).toEqual("initial value")
			property.addReactor reactor2
			expect(observedValue2).toEqual("initial value")
		it "sends subsequent values to all attached reactors", () ->
			property = new reactive.property "initial value"
			property.addReactor reactor
			property.addReactor reactor2
			property.reactTo "expected value"
			expect(observedValue).toEqual("expected value")
			expect(observedValue2).toEqual("expected value")
			property.reactTo "expected value2"
			expect(observedValue).toEqual("expected value2")
			expect(observedValue2).toEqual("expected value2")
		it "sends latest value to reactors as they are added", () ->
			property = new reactive.property "initial value"
			property.reactTo "expected value"
			property.addReactor reactor
			expect(observedValue).toEqual("expected value")
			property.addReactor reactor2
			expect(observedValue2).toEqual("expected value")

		it "properties can be chained", () ->
			property0 = new reactive.property "initial value 0"
			property1 = new reactive.property "initial value 1"
			property0.addReactor ((v) -> property1.reactTo v)
			property1.addReactor reactor
			property0.reactTo "expected value"
			expect(observedValue).toEqual("expected value")
			
			
		it "can filter values", () ->
			property = new reactive.property 3
			gt5 = property.filter 9, (v) -> v > 5
			gt5.addReactor reactor
			expect(observedValue).toEqual(9)
			property.reactTo 2
			expect(observedValue).toEqual(9)
			property.reactTo 6
			expect(observedValue).toEqual(6)

		it "can map values", () ->
			property = new reactive.property 4
			plus1 = property.map (v) -> v + 1
			plus1.addReactor reactor
			expect(observedValue).toEqual(5)
			property.reactTo 2
			expect(observedValue).toEqual(3)

	describe "reactive combine", () ->
		it "applies combine function against every value of property", () ->
			prop1 = new reactive.property("p1")
			prop2 = new reactive.property("p2")
			combined = reactive.combineProperties ((a,b) -> a + b), prop1, prop2
			combined.addReactor reactor
			expect(observedValue).toEqual("p1p2")
			prop1.reactTo "p1updated"
			expect(observedValue).toEqual("p1updatedp2")
			prop2.reactTo "p2updated"
			expect(observedValue).toEqual("p1updatedp2updated")
			
		it "applies combine function against every value", () ->
			combined = reactive.combine ((a,b) -> a + b), reactiveValue, reactiveValue2
			combined.addReactor reactor
			reactiveValue.reactTo "first"
			expect(observedValue).toEqual("firstundefined")
			reactiveValue2.reactTo "second"
			expect(observedValue).toEqual("firstsecond")
