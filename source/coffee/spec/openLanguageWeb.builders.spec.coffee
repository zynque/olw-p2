describe "open language web", () ->

	expectDocumentToMatch = (doc, expectedForm) ->
		docForm = olw.convertLiveDocumentToArray(doc)
		expect(docForm).toEqual(expectedForm)

	exampleObj =
		f0: () -> "content"
		f1: (txt) -> "(" + txt + ")"
		f2: (a, b) -> a + b

	funcObj = (name) -> {type: "bootstrap", value: name, interpretation: exampleObj[name]}
	[f0, f1, f2] = (funcObj(name) for own name of exampleObj)
	
	exampleUrl = "http://www.openlanguageweb.com/examples/012"
		
	it "has the standard document header url", () ->
		expect(olw.standardDocumentHeader)
			.toEqual("http://www.openlanguageweb.com/core/standardDocument")
	
	it "has the bootstrap document header url", () ->
		expect(olw.bootstrapDocumentHeader)
			.toEqual("http://www.openlanguageweb.com/core/bootstrapDocument")
	
	it "can create a live doc from a js object for bootstrapping", () ->		
		repo = olw.withBuilders(olw.repository.create())
		bootstrap = repo.documents.bootstrap(exampleObj, exampleUrl)
		expect(bootstrap.url).toEqual(exampleUrl)
		doc = bootstrap.document
		expectedForm = [4,
			[
				[0, {type: "string", value: olw.bootstrapDocumentHeader}]
				[1, f0], [2, f1], [3, f2]
			]
		]
		expectDocumentToMatch(doc, expectedForm)
		expectDocumentToMatch(olw.documentCache[exampleUrl], expectedForm)
		
	it "can create a doc with a boostrapped dependency", ->
		repo = olw.withBuilders(olw.repository.create())
		bootstrap = repo.documents.bootstrap(exampleObj, exampleUrl)
		nodeIds = bootstrap.nodeIds
		
		bootstrapReferences = {}
		{document: doc} = using repo.standardDocument().referencing(bootstrap), ->
			bootstrapReferences = @bootstrapReferencesByName
			@content(@f2(@f0(), @f1(@f0())))

		f0ref = {type: "nodeReference", value: 4, referencedNode: {referenceToNode: 4}}
		f1ref = {type: "nodeReference", value: 8, referencedNode: {referenceToNode: 8}}
		f2ref = {type: "nodeReference", value: 12, referencedNode: {referenceToNode: 12}}
		
		expectedForm = [25, [
			[22, {type: "string", value: olw.standardDocumentHeader}],
			[23,
				[13, [
					[0, {type: "string", value: exampleUrl}],
					[4, [
						[1, {type: "documentNodeReference"}],
						[2, {type: "nodeReference", value: 0, referencedNode: {referenceToNode: 0}}],
						[3, {type: "int", value: nodeIds.f0}]
					]],
					[8, [
						[5, {type: "documentNodeReference"}],
						[6, {type: "nodeReference", value: 0, referencedNode: {referenceToNode: 0}}],
						[7, {type: "int", value: nodeIds.f1}]
					]],
					[12, [
						[9, {type: "documentNodeReference"}],
						[10, {type: "nodeReference", value: 0, referencedNode: {referenceToNode: 0}}],
						[11, {type: "int", value: nodeIds.f2}]
					]]
				]]
			],
			[24, 
				[21, [[20, f2ref], [15, [14, f0ref]], [19, [[18, f1ref], [17, [16, f0ref]]]]]]
			]
		]]
		
		expectDocumentToMatch(doc, expectedForm)

	it "can create a doc with multiple boostrapped dependencies", ->
		o1 = {a: -> "a"}
		o2 = {b: -> "b"}
		url1 = "url1"
		url2 = "url2"
		repo = olw.withBuilders(olw.repository.create())		
		bootstrap1 = repo.documents.bootstrap(o1, url1)
		bootstrap2 = repo.documents.bootstrap(o2, url2)
		
		{document: doc} =
			using repo.standardDocument().referencing(bootstrap1, bootstrap2), ->
				@content(@a(), @b())

		aRef = {type: "nodeReference", value: 4, referencedNode: {referenceToNode: 4}}
		bRef = {type: "nodeReference", value: 10, referencedNode: {referenceToNode: 10}}
		
		expectedForm = [19, [
			[16, {type: "string", value: olw.standardDocumentHeader}],
			[17, [
				[5,	[
					[0, {type: "string", value: url1}],
					[4, [
						[1, {type: "documentNodeReference"}],
						[2, {type: "nodeReference", value: 0, referencedNode: {referenceToNode: 0}}],
						[3, {type: "int", value: bootstrap1.nodeIds.a}]
					]],
				]],
				[11,	[
					[6, {type: "string", value: url2}],
					[10, [
						[7, {type: "documentNodeReference"}],
						[8, {type: "nodeReference", value: 6, referencedNode: {referenceToNode: 6}}],
						[9, {type: "int", value: bootstrap2.nodeIds.b}]
					]],
				]]
			]],
			[18,
				[[13, [12, aRef]], [15, [14, bRef]]]
			]
		]]
		
		expectDocumentToMatch(doc, expectedForm)

	it "can create a doc with dependencies built from primitive types", ->
		repo = olw.withBuilders(olw.repository.create())		
		{document: doc} = using repo.standardDocument(), ->
			@content(@int(5), @node(@string("a")))
		expectedForm = [3, [
			[0, {type: "int", value: 5}],
			[2, [1, {type: "string", value: "a"}]]]
		]
		expectDocumentToMatch(doc, expectedForm)

	it "can safely reference another doc containing no refs", ->
		repo = olw.withBuilders(olw.repository.create())
		url = "otherDoc.com"

		doc1 = using repo.standardDocument().withUrl(url), ->
			@content()

		doc2 = using repo.standardDocument().referencing(doc1), ->
			@content()

		expectedForm =
			[5, [
				[2, { type : 'string', value : olw.standardDocumentHeader }],
				[3, [1, [0, { type : 'string', value : 'otherDoc.com' }]]],
				[4, []]
			]]

		expectDocumentToMatch(doc2.document, expectedForm)

	it "can create a doc referencing nodes from other created docs", ->
		repo = olw.withBuilders(olw.repository.create())
		url1 = "otherDoc.com"
		url2 = "otherDoc2.com"

		doc1 = using repo.standardDocument().withUrl(url1), ->
			@content(@ref("four", @int(4)), @ref("cat", @string("cat")))

		doc2 = using repo.standardDocument().withUrl(url2), ->
			@content(@int(5), @int(6), @int(7), @ref("eight", @int(8)))

		doc3 = using repo.standardDocument().referencing(doc1, doc2), ->
			@content(@four(), @node(@cat()), @eight())
		
		expectedForm = [26, [
			[23, {type: "string", value: olw.standardDocumentHeader}],
			[24, [ 
				[9,	[
					[0, {type: "string", value: url1}],
					[4, [
						[1, {type: "documentNodeReference"}],
						[2, {type: "nodeReference", value: 0, referencedNode: {referenceToNode: 0}}],
						[3, {type: "int", value: 0}]
					]],
					[8, [
						[5, {type: "documentNodeReference"}],
						[6, {type: "nodeReference", value: 0, referencedNode: {referenceToNode: 0}}],
						[7, {type: "int", value: 1}]
					]]
				]],
				[15, [
					[10, {type: "string", value: url2}],
					[14, [
						[11, {type: "documentNodeReference"}],
						[12, {type: "nodeReference", value: 10, referencedNode: {referenceToNode: 10}}],
						[13, {type: "int", value: 3}]
					]]
				]]
			]],
			[25, [
				[17,
					[16, {type: "nodeReference", value: 4, referencedNode: {referenceToNode: 4}}]
				],
				[20,
					[19, [18, {type: "nodeReference", value: 8, referencedNode: {referenceToNode: 8}}]]
				],
				[22,
					[21, {type: "nodeReference", value: 14, referencedNode: {referenceToNode: 14}}]
				]
			]]
		]]

		expectDocumentToMatch(doc3.document, expectedForm)
