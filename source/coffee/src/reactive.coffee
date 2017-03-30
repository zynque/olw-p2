
class property
	constructor: (initialValue) ->
		@currentValue = initialValue
		@reactors = []
	addReactor: (reactor) ->
		@reactors.push reactor
		reactor(@currentValue)
	reactTo: (value) ->
		@currentValue = value
		if(!@reactors?)
			alert("whazza: " + @currentValue)
		reactor(value) for reactor in @reactors
	filter: (initialValue, f) ->
		filtered = new reactive.property initialValue
		this.addReactor (val) -> filtered.reactTo(val) if f(val) 
		filtered
	map: (f) ->
		mapped = new reactive.property f(@currentValue)
		this.addReactor (val) -> mapped.reactTo(f(val))
		mapped


reactive = 

	new: ->
		reactors = []
		{
			addReactor: (reactor) -> reactors.push reactor
			reactTo: (newValue) -> reactor(newValue) for reactor in reactors
			map: (f) ->
				reactiveValue = reactive.new()
				this.addReactor ((val) -> reactiveValue.reactTo(f(val)))
				reactiveValue
			filter: (f) ->
				reactiveValue = reactive.new()
				this.addReactor ((val) -> reactiveValue.reactTo(val) if f(val)) 
				reactiveValue
		}

	combine: (combineFunc, reactiveValues...) ->
		observedValues = []
		combinedReactiveValue = reactive.new()
		buildReactor = (i) ->
			(val) ->
				observedValues[i] = val
				result = combineFunc observedValues...
				combinedReactiveValue.reactTo result
		reactiveValue.addReactor buildReactor(index) for reactiveValue, index in reactiveValues
		combinedReactiveValue

	combineProperties: (combineFunc, reactiveProperties...) ->
		observedValues = (prop.currentValue for prop in reactiveProperties)
		initialValue = combineFunc observedValues...
		combinedProperty = new reactive.property initialValue
		buildReactor = (i) -> (val) ->
			observedValues[i] = val
			result = combineFunc observedValues...
			combinedProperty.reactTo result
		for prop, index in reactiveProperties
			prop.addReactor buildReactor(index)
		combinedProperty


reactive.property = property


window.reactive = reactive
