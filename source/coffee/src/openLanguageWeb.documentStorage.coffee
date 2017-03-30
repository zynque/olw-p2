
createNewDocumentVersion = (rootId) ->
	rootId: rootId

createNewNode = (children) ->
	children: children

createNewDataNode = (data) ->
	data: data


replaceNode = (nodes, path, replacementId) ->
	if(path.length < 2)
		[replacementId]
	else
		replacedNodeId = path.pop()
		parentId = path[path.length-1]
		parentNode = nodes[parentId]
		replaceChild = (c) -> if c == replacedNodeId then replacementId else c
		newChildren = (replaceChild(child) for child in parentNode.children)			
		newParentId = nodes.length
		nodes.push(createNewNode(newChildren))
		newPath = replaceNode(nodes, path, newParentId)
		newPath.push(replacementId)
		newPath


createNewPathUpdateContext = (documentId, nodes) -> (path) ->
	content: (children...) ->
		replacementId = nodes.length
		nodes.push(createNewNode(children))
		newPath = replaceNode(nodes, path, replacementId)
		newRootId = newPath[0]
		{newRootId: newRootId, newPath: newPath, documentId: documentId}
	updatedData: (data) ->
		replacementId = nodes.length
		nodes.push(createNewDataNode(data))
		newPath = replaceNode(nodes, path, replacementId)
		newRootId = newPath[0]
		{newRootId: newRootId, newPath: newPath}
	node: (children...) ->
		nodeId = nodes.length
		nodes.push(createNewNode(children))
		nodeId
	dataNode: (data) ->
		nodeId = nodes.length
		nodes.push(createNewDataNode(data))
		nodeId


createNewVersionedPathUpdateContext = (createUnversionedContext, versions) -> (path) ->
	unversionedContext = createUnversionedContext(path)
	versionedContext =
		content: (children...) ->
			{newRootId, newPath, documentId} = unversionedContext.content(children...)
			version = versions.length
			versions.push(createNewDocumentVersion(newRootId))
			{newVersion: version, newPath: newPath, documentId: documentId}			
		updatedData: (data) ->
			{newRootId, newPath} = unversionedContext.updatedData(data)
			version = versions.length
			versions.push(createNewDocumentVersion(newRootId))
			{newVersion: version, newPath: newPath}			
		node: (children...) ->
			unversionedContext.node(children...)
		dataNode: (data) ->
			unversionedContext.dataNode(data)
	versionedContext


createNewUnversionedDocument = (id) ->
	nodes = []
	document =
		root: undefined
		nodes: nodes
		updatePath: createNewPathUpdateContext(id, nodes)
	document


createNewDocument = (id) ->
	versions = []
	document = createNewUnversionedDocument(id)
	unversionedUpdatePath = document.updatePath
	document.versions = versions
	document.updatePath = createNewVersionedPathUpdateContext(unversionedUpdatePath, versions)
	document.updatePathFromVersion = (version, path) ->
		versions.splice(version + 1, versions.length - (version + 1))
		document.updatePath(path)
	document


createNewRepository = () ->
	documents = []
	repo =
		documents: documents
	documents.createWithContent = () ->
		documentId = documents.length
		document = createNewDocument(documentId)
		documents.push(document)
		document.updatePath([])
	documents.create = () ->
		documentId = []
		using documents.createWithContent(), () ->
			{documentId} = @content()
		documentId
	repo


olw.immutableRepository =
	create: -> createNewRepository()
