describe "open language web", () ->

	expectDocumentToMatch = (doc, expectedForm) ->
		expect(olw.convertLiveDocumentToArray(doc)).toEqual(expectedForm)
	
	it "can cache documents by url", ->
		repo = olw.repository.create()
		doc = using repo.documents.createWithContent(), ->
			@content(@dataNode("a"))
		url = "http://www.openlanguageweb.com/example/123"
		olw.documentCache[url] = doc
		expectedForm = [1, [0, "a"]]
		expectDocumentToMatch(olw.documentCache[url], expectedForm)

	describe "live repository", ->
		
		it "can create an empty document", ->
			repo = olw.repository.create()
			doc = repo.documents.create()
			expect(doc.id).toEqual(0)
			expect(doc.version).toEqual(0)
			expect(doc.children.length).toEqual(0)
			doc = using repo.documents.createWithContent(), -> @content()
			expect(doc.id).toEqual(1)
			expect(doc.version).toEqual(0)
			expect(doc.children.length).toEqual(0)
			
		it "can create a document from scratch with content", ->
			repo = olw.repository.create()
			doc = using repo.documents.createWithContent(), ->
				@content(@node(@dataNode("c")), @dataNode("d"))			
			expect(doc.id).toEqual(0)
			expect(doc.version).toEqual(0)
			expect(doc.children).toEqual(doc.documentNode.children)
			expectedForm = [3, [[1, [0, "c"]], [2, "d"]]]
			expectDocumentToMatch(doc, expectedForm)
		
		it "can get the latest version of an existing doc from storage", ->
			repo = olw.repository.create()
			backingStorage = repo.storage			
			{documentId} = using backingStorage.documents.createWithContent(), ->
				@content(@dataNode("a"))
			using backingStorage.documents[documentId].updatePath([]), ->
				@content(@node(@dataNode("b"), @dataNode("c")))
			doc = repo.documents.get(documentId)
			expectedForm = [5, [4, [[2, "b"], [3, "c"]]]]
			expectDocumentToMatch(doc, expectedForm)
		
		it "can get the specified version of an existing doc from storage", ->
			repo = olw.repository.create()
			backingStorage = repo.storage			
			{documentId} = using backingStorage.documents.createWithContent(), ->
				@content(@node(@dataNode("b"), @dataNode("c")))
			using backingStorage.documents[documentId].updatePath([]), ->
				@content(@dataNode("a"))
			doc = repo.documents.get(documentId, 0)
			expectedForm = [3, [2, [[0, "b"], [1, "c"]]]]
			expectDocumentToMatch(doc, expectedForm)
		
		it "can create multiple documents", ->
			repo = olw.repository.create()
			doca = repo.documents.create()
			docb = repo.documents.create()
			expect(doca.id).toEqual(0)
			expect(doca.version).toEqual(0)
			expect(doca.documentNode.id).toEqual(0)
			expect(docb.id).toEqual(1)
			expect(docb.version).toEqual(0)
			expect(docb.documentNode.id).toEqual(0)
		
		it "returns document node when doc node updated", ->
			repo = olw.repository.create()
			doc = using repo.documents.createWithContent(), ->
				@content(@node("a"))
			docNode = doc.documentNode
			returnedNode = using docNode.updateWith(), ->
				@content(@node("b"))
			expect(returnedNode).toEqual(docNode)
							
	describe "a document", ->

		it "provides access to backing document", ->
			repo = olw.repository.create()
			doc = using repo.documents.createWithContent(), ->
				@content(@node(@dataNode("c")))
			expect(doc.children.length).toEqual(1)
			backingDoc = doc.backingDocument
			storedDocumentForm = olw.convertStoredDocumentToArray(backingDoc, doc.version)
			expectDocumentToMatch(doc, storedDocumentForm)
			
		it "can be modified in place", ->
			repo = olw.repository.create()
			doc = using repo.documents.createWithContent(), ->
				@content(@dataNode("b"))
			formBefore = [1, [0, "b"]]
			doc2 = using doc.updateWith(), ->
				@content(@dataNode("c"), @node(@dataNode("d")))
			expectedForm = [5, [[2, "c"], [4, [3, "d"]]]]
			expectDocumentToMatch(doc, expectedForm)
			expect(doc).toEqual(doc2)
	
		it "can have nodes modified re-using old nodes under new structure", ->
			repo = olw.repository.create()
			doc = using repo.documents.createWithContent(), ->
				@content(@dataNode("b"))
			formBefore = [1, [0, "b"]]
			nodeB = doc.documentNode.children[0]
			using doc.updateWith(), ->
				@content(nodeB, @dataNode("d"))
			expectedForm = [3, [[0, "b"], [2, "d"]]]
			expectDocumentToMatch(doc, expectedForm)
		
		it "can be reverted to previous versions", ->
			repo = olw.repository.create()
			doc = using repo.documents.createWithContent(), ->
				@content(@node(@dataNode("a")), @dataNode("b"))
			formBefore = [3, [[1, [0, "a"]], [2, "b"]]]
			nodeB = doc.documentNode.children[1]
			using doc.updateWith(), ->
				@content(nodeB, @dataNode("d"))
			doc.goToVersion(0)
			expectedForm = formBefore
			expectDocumentToMatch(doc, expectedForm)
		
		it "can go forward and back through versions in an optimized way", ->
			[]
		#!TODO
		it "can be updated starting from an old version", ->
			[]
		it "can have new nodes added to the front, middle, and end", ->
			[]
		it "can have nodes removed from the front, middle, and end", ->
			[]
			
	describe "a node", ->
		
		it "provides access to parent", ->
			repo = olw.repository.create()
			doc = using repo.documents.createWithContent(), ->
				@content(@node(@dataNode("c")))
			nodeB = doc.children[0]
			nodeC = nodeB.children[0]
			expect(nodeC.parentNode).toEqual(nodeB)
			
		it "provides access to doc node", ->
			repo = olw.repository.create()
			doc = using repo.documents.createWithContent(), ->
				@content(@node(@dataNode("c")))
			nodeC = doc.children[0].children[0]
			expect(nodeC.getDocumentNode().data).toEqual(doc.documentNode.data)
			
		it "provides access to owning doc object", ->
			repo = olw.repository.create()
			doc = using repo.documents.createWithContent(), ->
				@content(@node(@dataNode("c")))
			nodeC = doc.children[0].children[0]
			expect(nodeC.getDocument()).toEqual(doc)
			
		it "can be modified in place", ->
			repo = olw.repository.create()
			doc = using repo.documents.createWithContent(), ->
				@content(@node(@dataNode("c")))
			formBefore = [2, [1, [0, "c"]]]
			nodeB = doc.children[0]
			updatedNode = using nodeB.updateWith(), ->
				@content(@dataNode("d"), @dataNode("e"))
			expect(updatedNode.id).toEqual(5)
			expect(doc.version).toEqual(1)
			expectedForm = [6, [5, [[3, "d"], [4, "e"]]]]
			expectDocumentToMatch(doc, expectedForm)
		
		it "can be modified in place reusing old nodes", ->
			[]
	
	describe "tying reactive changes to a live document", ->
		repo = olw.repository.create()
		doc = using repo.documents.createWithContent(), ->
			@content(@node(@dataNode("a")))
		
		# reactiveProperty = new reactive.property doc
		# property.reactTo

		# RP for interpretation
		# RP for raw doc
		# how do we figure out deltas?
		# how do we tie to ui?

		# rhs: content(rows(textbox(ref:a), textbox(ref:b)))
		# when a updates, who listens?
		# the save button listens?
		# to what exactly? list with a and b?
		# which then becomes the new doc content?, which is also an RP


	describe "a data node", ->

		#TODO
		it "can be modified in place", ->
			[]

	describe "stuff todo", ->

		it "pushes external changes", ->
			[]
		it "can store name etc about a document", ->
			[]
