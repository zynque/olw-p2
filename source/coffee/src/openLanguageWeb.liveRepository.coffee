
# todo compare performance of node as object vs a class base approach
createNewNode = (storage, parentNode, id, data) ->
	node =
		parentNode: parentNode
		children: []
		id: id
		data: data
		getDocumentNode: () ->
			if @parentNode? then @parentNode.getDocumentNode() else this
		getDocument: () ->
			@getDocumentNode().document
		getPathToRoot: () ->
			path = []
			n = this
			until !n?
				path.push(n.id)
				n = n.parentNode
			path
	node.updateWith = () -> createNodeUpdateBuilder(storage, node)
	node


updateNodeVersion = (storage, backingDocument, parent, nodeId) ->
	backingNode = backingDocument.nodes[nodeId]
	node = createNewNode(storage, parent, nodeId, backingNode.data)
	if(backingNode.children?)
		node.children.push(updateNodeVersion(storage, backingDocument, backingNode, cid)) for cid in backingNode.children
	node


createGoToVersion = (storage, doc) -> (version) ->
	backingDocument = storage.documents[doc.id]
	rootId = backingDocument.versions[version].rootId
	newDocumentNode = updateNodeVersion(storage, backingDocument, undefined, rootId)
	newDocumentNode.document = doc
	doc.documentNode = newDocumentNode
	doc.documentNode.id = rootId
	doc.children = newDocumentNode.children


createNewDocument = (storage) -> (id) ->
	documentNode = createNewNode(storage, undefined, 0)
	doc =
		id: id
		version: 0
		documentNode: documentNode
		children: documentNode.children
	doc.updateWith = () ->
		docNodeUpdateWith = documentNode.updateWith()
		docUpdateWith =
			node: docNodeUpdateWith.node
			dataNode: docNodeUpdateWith.dataNode
			content: (children...) ->
				docNodeUpdateWith.content(children...)
				doc
			record: docNodeUpdateWith.record
		docUpdateWith
	doc.goToVersion = createGoToVersion(storage, doc)
	documentNode.document = doc
	doc


createNodeBuilderBase = (storage, storageBuilder) ->
	liveDocBuilder = {}
	liveDocBuilder.node = (children...) ->
		childIds = (child.id for child in children)
		storedNodeId = storageBuilder.node(childIds...)
		node = createNewNode(storage, undefined, storedNodeId)
		child.parentNode = node for child in children
		node.children.push(child) for child in children
		node
	liveDocBuilder.dataNode = (data) ->
		storedNodeId = storageBuilder.dataNode(data)
		node = createNewNode(storage, undefined, storedNodeId, data)
		node.data = data
		node
	liveDocBuilder.record = (node, recorded) ->
		recorded.id = node.id
		node
	liveDocBuilder


createNodeUpdateBuilder = (storage, nodeToUpdate) ->
	updateNodeIds = (updatedNode, newPathFromRoot) ->
		node = updatedNode
		while node? and newPathFromRoot.length > 0
			node.id = newPathFromRoot.pop()
			node = node.parentNode
	doc = nodeToUpdate.getDocument()
	backingDoc = doc.backingDocument
	docId = doc.id
	pathToRoot = nodeToUpdate.getPathToRoot()
	storageBuilder = backingDoc.updatePath(pathToRoot)
	liveDocBuilder = createNodeBuilderBase(storage, storageBuilder)
	liveDocBuilder.content = (children...) ->
		nodeToUpdate.children = []
		nodeToUpdate.children.push(child) for child in children
		child.parentNode = nodeToUpdate for child in children
		childIds = (child.id for child in children)
		{documentId, newVersion, newPath} = storageBuilder.content(childIds...) 
		updateNodeIds(nodeToUpdate, newPath)
		doc.version = newVersion
		if(nodeToUpdate.document?)
			nodeToUpdate.document.children = nodeToUpdate.children
		nodeToUpdate
	liveDocBuilder


createDocBuilder = (storage, doc) ->
	storageBuilder = storage.documents.createWithContent()
	liveDocBuilder = createNodeBuilderBase(storage, storageBuilder)
	liveDocBuilder.content = (children...) ->
		childIds = (child.id for child in children)
		{documentId, newVersion} = storageBuilder.content(childIds...) 
		child.parentNode = doc.documentNode for child in children
		doc.documentNode.children.push(child) for child in children
		doc.documentNode.document = doc
		doc.id = documentId
		rootId = storage.documents[documentId].versions[newVersion].rootId
		doc.documentNode.id = rootId
		doc.backingDocument = storage.documents[documentId]
		doc.version = newVersion
		doc
	liveDocBuilder


createLiveDocumentFromStorage = (storage, storedDoc, rootId) ->
	doc = createNewDocument(storage)(undefined)
	newDocumentNode = updateNodeVersion(storage, storedDoc, undefined, rootId)
	newDocumentNode.document = doc
	doc.documentNode = newDocumentNode
	doc.documentNode.id = rootId
	doc.children = newDocumentNode.children
	doc


createNewRepository = (immutableDataStore) ->
	storage = immutableDataStore
	repo =
		documents: {}
		storage: storage
	repo.documents.get = (id, version) ->
		storedDoc = storage.documents[id]
		version = if(version?) then version else storedDoc.versions.length - 1
		root = storedDoc.versions[version].rootId
		createLiveDocumentFromStorage(storage, storedDoc, root)
	repo.documents.createWithContent = () ->
		doc = (createNewDocument(storage))(undefined)
		createDocBuilder(storage, doc)
	repo.documents.create = () -> using repo.documents.createWithContent(), () -> @content()
	repo


olw.repository =
	create: -> createNewRepository(olw.immutableRepository.create())


olw.documentCache = {}
