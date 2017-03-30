describe "open language web", () ->
	
	expectDocToMatch = (doc, version, expectedForm) ->
		rootId = doc.versions[version].rootId
		expect(olw.convertStoredDocumentToArray(doc, version)).toEqual(expectedForm)

	describe "in memory immutable document storage", ->
		
		# TODO: a repo aught to be a document itself whose children are the documents in the repo?
		it "can be created with no content", ->
			repo = olw.immutableRepository.create()
			doc0Id = repo.documents.create()
			expect(doc0Id).toEqual(0)
			doc0 = repo.documents[doc0Id]
			expect(doc0.versions.length).toEqual(1)
			expect(doc0.nodes.length).toEqual(1)
			doc0V0 = doc0.versions[0]
			expect(doc0V0.rootId).toEqual(0)
			doc0N0 = doc0.nodes[0]
			expect(doc0N0.data).toBeUndefined()
			expect(doc0N0.children.length).toEqual(0)
			doc1Id = repo.documents.create()
			expect(doc1Id).toEqual(1)
			
		it "can be created with initial content", ->
			repo = olw.immutableRepository.create()
			[documentId, newVersion] = []
			using repo.documents.createWithContent(), ->
				{documentId, newVersion} = @content(@node(@dataNode("a")))
			doc0 = repo.documents[documentId]
			expectedForm = [2, [1, [0, "a"]]]
			expectDocToMatch(doc0, newVersion, expectedForm)
			
		it "can have new versions generated at root", ->
			repo = olw.immutableRepository.create()
			doc = repo.documents[repo.documents.create()]
			newVersion = []
			newPath = []
			using doc.updatePath([0]), ->
				{newVersion, newPath} = @content(@dataNode("a"))
			expect(newVersion).toEqual(1)
			expect(newPath).toEqual([2])
			expectedForm = [2, [1, "a"]]
			expectDocToMatch(doc, newVersion, expectedForm)
			
		it "can have complex subtrees added at root", ->
			repo = olw.immutableRepository.create()
			doc = repo.documents[repo.documents.create()]
			newVersion = []
			newPath = []
			using doc.updatePath([0]), ->
				{newVersion, newPath} = @content(@node(@dataNode("a"), @dataNode("b")))
			expect(newVersion).toEqual(1)
			expect(newPath).toEqual([4])
			expectedForm = [4, [3, [[1, "a"], [2, "b"]]]]
			expectDocToMatch(doc, newVersion, expectedForm)
			
		it "can have new versions generated by replacing data node somewhere in tree", ->
			repo = olw.immutableRepository.create()
			[newVersion, newPath, documentId] = []
			using repo.documents.createWithContent(), ->
				{documentId} = @content(@node(@dataNode("a"), @dataNode("b")))
			formBefore = [3, [2, [[0, "a"], [1, "b"]]]]
			doc = repo.documents[documentId]
			using doc.updatePath([3,2,0]), ->
				{newVersion, newPath} = @updatedData("c")
			expect(newVersion).toEqual(1)
			expect(newPath).toEqual([6,5,4])
			expectedForm = [6, [5, [[4, "c"], [1, "b"]]]]
			expectDocToMatch(doc, newVersion, expectedForm)
			
		it "can have new versions generated by replacing an inner node somewhere in tree", ->
			repo = olw.immutableRepository.create()
			[newVersion, newPath, documentId] = []
			using repo.documents.createWithContent(), ->
				{documentId} = @content(@node(@dataNode("a")), @node(@dataNode("b")))
			formBefore = [4, [[1, [0, "a"]], [3, [2, "b"]]]]
			doc = repo.documents[documentId]
			using doc.updatePath([4,1]), ->
				{newVersion, newPath} = @content(@dataNode("c"))
			expect(newVersion).toEqual(1)
			expect(newPath).toEqual([7,6])
			expectedForm = [7, [[6, [5, "c"]], [3, [2, "b"]]]]
			expectDocToMatch(doc, newVersion, expectedForm)
			
		it "can have new versions generated re-using existing nodes under the new subtree", ->
			repo = olw.immutableRepository.create()
			doc = repo.documents[repo.documents.create()]
			[newVersion, newPath, documentId] = []
			using repo.documents.createWithContent(), ->
				{documentId} = @content(@node(@dataNode("a")), @node(@dataNode("b")))
			formBefore = [4, [[1, [0, "a"]], [3, [2, "b"]]]]
			doc = repo.documents[documentId]
			using doc.updatePath([4,1]), ->
				{newVersion, newPath} = @content(@dataNode("c"), 0)
			expect(newVersion).toEqual(1)
			expect(newPath).toEqual([7,6])
			expectedForm = [7, [[6, [[5, "c"], [0, "a"]]], [3, [2, "b"]]]]
			expectDocToMatch(doc, newVersion, expectedForm)
			
		# TODO: later, updates to old versions will generate new branches in version tree...
		it "updates on old versions cause subsequent versions to be overwritten", ->
			repo = olw.immutableRepository.create()
			[v1, newVersion, newPath, documentId] = []
			v0 = 0
			using repo.documents.createWithContent(), ->
				{documentId} = @content(@node(@dataNode("a")), @node(@dataNode("b")))
			formBefore = [4, [[1, [0, "a"]], [3, [2, "b"]]]]
			doc = repo.documents[documentId]
			using doc.updatePath([4,1]), ->
				{newVersion: v1} = @content(@dataNode("c"), 0)
			formBefore = [7, [6, [5, [0, "a"]], [3, [2, "b"]]]]
			using doc.updatePathFromVersion(v0, [4, 3]), ->
				{newVersion, newPath} = @content(@dataNode("d"))
			expect(newVersion).toEqual(1)
			expect(newPath).toEqual([10,9])
			expectedForm = [10, [[1, [0, "a"]], [9, [8, "d"]]]]
			expectDocToMatch(doc, newVersion, expectedForm)