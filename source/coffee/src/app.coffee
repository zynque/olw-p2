
reactiveOperators =
	createProperty: (initialValue) -> new reactive.property(initialValue)
	rPlus: (rva, rvb) -> reactive.combine(((a,b)->a+b), rva, rvb)
	rpPlus: (rva, rvb) -> reactive.combineProperties(((a,b)->a+b), rva, rvb)
	rVal: (component) -> component.reactiveValue
	rShow: (component, rValue) -> component.show(rValue)
	intValues: (prop, initialValue) ->
		prop.filter(initialValue, (v) -> !isNaN(v)).map((v) -> (+v))
	
createExampleWithButtons = () -> using components, ->
	p = new reactive.property "initial"
	pb = new reactive.property "initial button"
	blp = new reactive.property "push!"
	b = @button(blp, p, pb)
	lt = @textBox(blp)
	t = @textBox(p)
	l1 = @label(p)
	l2 = @label(pb)
	@columns(lt, b, t, @rows(l1, l2))

createExample0 = () -> using components, ->
	v1 = new reactive.property 1
	v1int = reactiveOperators.intValues(v1, 1)
	v2 = new reactive.property 2
	v2int = reactiveOperators.intValues(v2, 2)
	vAdded = reactiveOperators.rpPlus(v1int, v2int)
	txt1 = @textBox(v1)
	txt2 = @textBox(v2)
	label = @label(vAdded)
	@columns(txt1, txt2, label)

createExample1 = () ->
	repo = olw.withBuilders(olw.repository.create())
	componentsBootstrap = repo.documents.bootstrap(components, "componentsUrl")
	opsBootstrap = repo.documents.bootstrap(reactiveOperators, "reactiveOpsUrl")
	{document: doc} = using repo.standardDocument().referencing(componentsBootstrap, opsBootstrap), ->
			@content(@columns(
				@box(@label(@createProperty(@string("abc")))),
				@arrow(),
				@box(@label(@createProperty(@string("defg"))))
			))
	olw.interpreter.interpret(doc)

createExample2 = () ->
	repo = olw.withBuilders(olw.repository.create())
	componentsBootstrap = repo.documents.bootstrap(components, "componentsUrl")
	opsBootstrap = repo.documents.bootstrap(reactiveOperators, "reactiveOpsUrl")

	valuesDoc = using repo.standardDocument().withUrl("exampleurl").referencing(opsBootstrap), ->
			@content(
				@ref("p1", @createProperty(@int("42"))),
				@ref("p2", @createProperty(@int("53")))
			)
	
	# exploration of how to manage document changes
	# goal: persist change on button click
	{document: doc} = using repo.standardDocument().referencing(componentsBootstrap, opsBootstrap, valuesDoc), ->
			plusVal = @rpPlus(@intValues(@p1(), @int("42")), @intValues(@p2(), @int("53")))
			tb1 = @textBox(@p1())
			tb2 = @textBox(@p2())
			lbl = @label(plusVal)

			# p = @createProperty(@docProperty("exampleurl"))
			# pb = new reactive.property "initial button"
			# blp = new reactive.property "save!"
			# bttn = @button(blp, p, pb)

			# @content(@rows(@columns(tb1, tb2, lbl) bttn))
			@content(@rows(@columns(tb1, tb2, lbl)))
	
	bootstrapDocAsText = olw.convertLiveDocumentToFriendlyText(opsBootstrap.document)
	valuesDocAsText = olw.convertLiveDocumentToFriendlyText(valuesDoc.document)
	docAsText = olw.convertLiveDocumentToFriendlyText(doc)
	interpreted = olw.interpreter.interpret(doc)
	components.rows(
		interpreted,
		components.label(new reactive.property bootstrapDocAsText),
		"------------------------------",
		components.label(new reactive.property valuesDocAsText),
		"------------------------------",
		components.label(new reactive.property docAsText)
	)


createExample3 = () ->
	repo = olw.withBuilders(olw.repository.create())
	componentsBootstrap = repo.documents.bootstrap(components, "componentsUrl")
	opsBootstrap = repo.documents.bootstrap(reactiveOperators, "reactiveOpsUrl")

	{document: valuesDoc} = using repo.standardDocument().withUrl("example3url").referencing(), ->
			@content(@int("42"))

	# valuesDoc2 = using valuesDoc.updateWith(), ->
		# @content(@int("43"))

	# valuesDoc3 = using valuesDoc.updateWith(), ->
		# @content(@int("44"))

	# {document: doc} = using repo.standardDocument()
		# .referencing(componentsBootstrap, opsBootstrap), ->
			# versions = @map(@docVersions("example3url"))
			# @content(@rows(@columns(versions)))
			# @content(@label(@int(3))
	
	interpreted = '3' #olw.interpreter.interpret(doc)
	components.rows(
		interpreted
	)


app = () ->
	e0 = createExample0()
	e1 = createExample1()
	e2 = createExample2()
	e3 = createExample3()
	eb = createExampleWithButtons()
	components.rows(eb, e0, e1, e2, e3)


window.application = app
