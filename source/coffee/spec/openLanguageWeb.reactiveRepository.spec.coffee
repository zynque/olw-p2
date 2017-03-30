describe "open language web", () ->
	
	expectDocToMatch = (doc, expectedForm) ->
		expect(olw.convertLiveDocumentToArray(doc)).toEqual(expectedForm)

	describe "reactive repositories", ->

		it "can be created", ->
			# repo = olw.reactiveRepository.create()
			
			# receivedValue = undefined
			# reactor = (v) -> receivedValue = v
			# repo.reactiveProperty.addReactor(reactor)
			
			# using repo.documents.createWithContent(), ->
			# 	{documentId, v0} = @content(@dataNode("a"))
			
			# expect(receivedValue.documents.size).toEqual(1)

			# doc = receivedValue.documents[0]
			# expectedForm = [1, [0, "a"]]
			# expectDocToMatch(doc, expectedForm)

	describe "reactive documents", ->


			# doc0 = repo.documents[documentId]

			# dataNodeReactiveProperty = doc0.nodes[0].reactiveProperty
			# dataNodeReactiveProperty

			# olw.bindReactivePropertyToDocument(doc0, [1, 0], uiReactiveValue)
			# uiReactiveValue.reactTo "b"

			# expect(doc0.versions.length).toEqual(2)

			# doc0V1 = doc0.versions[1]
			# expect(doc0V1.rootId).toEqual(3)
			# expectedForm = [3, [2, "b"]]
			# expectDocToMatch(doc0, 1, expectedForm)
		
