
olw.standardDocumentHeader = "http://www.openlanguageweb.com/core/standardDocument"
olw.bootstrapDocumentHeader = "http://www.openlanguageweb.com/core/bootstrapDocument"


nodeTypes =
	documentNodeReference: "documentNodeReference"
	nodeReference: "nodeReference"
	int: "int"
	string: "string"
	bootstrap: "bootstrap"


primitiveTypeBuilderObject =
	int: (value) -> {type: nodeTypes.int, value: value}
	string: (value) -> {type: nodeTypes.string, value: value}
	documentNodeReference: -> {type: nodeTypes.documentNodeReference}
	bootstrap: (name, interpretation) ->
		{type: nodeTypes.bootstrap, value: name, interpretation: interpretation}
	nodeReference: (referencedNodeId, referencedNode) ->
		if(referencedNode?)
			{type: nodeTypes.nodeReference, value: referencedNodeId, referencedNode: referencedNode}
		else
			{type: nodeTypes.nodeReference, value: referencedNodeId}


addPrimitiveTypesToBuilder = (docBuilder) ->
	buildDataNodeBuilder = (func) ->
		(values...) -> docBuilder.dataNode(func(values...))
	for own funcName, func of primitiveTypeBuilderObject
		docBuilder[funcName] = buildDataNodeBuilder(func)
	docBuilder


addReferableNodesToBuilder = (docBuilder) ->
	docRefs = {}
	nodeIds = {}
		
	ref = (name, node) ->
		docRefs[name] = node
		nodeIds[name] = node.id
		node

	docBuilder.ref = ref
	contentFunc = docBuilder.content
	docBuilder.content = (children...) ->
		# todo: add to nodeIds
		{document: doc, nodeIds: nodeIds2, url: url} = contentFunc(children...)
		{document: doc, nodeIds: nodeIds, url: url}
		# {document: doc, nodeIds: nodeIds.append nodeIds2, url: url}

	docBuilder


createDependencies = (docBuilder, referencedDocuments...) ->
	nodeReferencesByName = {}
	dependencyNodes = (
		for referencedDocument in referencedDocuments
			using docBuilder, ->
				urlNode = @string(referencedDocument.url)
				dependencyNodeContent = [urlNode]
				for own name, id of referencedDocument.nodeIds
					node = using docBuilder, -> @node(
						@documentNodeReference(),
						@nodeReference(urlNode.id, urlNode),
						@int(id)
					)
					nodeReferencesByName[name] = {referencedNodeId: node.id, referencedNode: node}
					dependencyNodeContent.push(node)
				@node(dependencyNodeContent...)
	)
	{
		dependencyNodes: dependencyNodes
		nodeReferencesByName: nodeReferencesByName
	}


addReferencesToDocBuilder = (docBuilder, referencedDocuments...) ->
	{dependencyNodes: dependencyNodes, nodeReferencesByName: nodeReferencesByName} =
		createDependencies(docBuilder, referencedDocuments...)
	contentBuilder = docBuilder.content
	docBuilder.content = (children...) ->
		docNodes = [docBuilder.string(olw.standardDocumentHeader)]
		dependencyNodes = dependencyNodes
		docNodes.push(docBuilder.node(dependencyNodes...))
		docNodes.push(docBuilder.node(children...))
		contentBuilder(docNodes...)
	buildBootstrapNodeBuilder = (name, id) -> (children...) ->
		nodeReference = nodeReferencesByName[name]
		refNode = docBuilder.nodeReference(nodeReference.referencedNodeId)
		refNode.data.referencedNode = nodeReference.referencedNode
		children.unshift(refNode)
		docBuilder.node(children...)
	for referencedDocument in referencedDocuments
		for own name, id of referencedDocument.nodeIds
			docBuilder[name] = buildBootstrapNodeBuilder(name, id)
	docBuilder


olw.withBuilders = (repo) ->

	addUrlToBuilder = (docBuilder, url) ->
		contentBuilder = docBuilder.content
		docBuilder.content = (children...) ->
			{document: doc, nodeIds: nodeIds} = contentBuilder(children...)
			olw.documentCache[url] = doc
			{document: doc, nodeIds: nodeIds, url: url}
		docBuilder

	extendedDocBuilderFor = (repo) ->
		docBuilder = repo.documents.createWithContent()
		contentBuilder = docBuilder.content
		docBuilder.content = (children...) ->
			doc = contentBuilder(children...)
			{document: doc, nodeIds: {}}
		addPrimitiveTypesToBuilder(docBuilder)
		addReferableNodesToBuilder(docBuilder)
		docBuilder.withUrl = (url) -> addUrlToBuilder(docBuilder, url)
		docBuilder.referencing = (refs...) -> addReferencesToDocBuilder(docBuilder, refs...)
		docBuilder
	
	repo.standardDocument = -> extendedDocBuilderFor(repo)
	repo.documents.bootstrap = (obj, url) -> bootstrapFromJsObject(repo, obj, url)
	repo


bootstrapFromJsObject = (repo, jsObj, url) -> 
	nodeIds = {}
	docBuilder = repo.documents.createWithContent()
	addPrimitiveTypesToBuilder(docBuilder)
	doc = using docBuilder, ->
		children = [@string(olw.bootstrapDocumentHeader)]
		for own funcName, func of jsObj
			node = @bootstrap(funcName, func)
			nodeIds[funcName] = node.id
			children.push(node)
		@content(children...)
	olw.documentCache[url] = doc
	bootstrap =
		document: doc
		nodeIds: nodeIds
		url: url
	bootstrap
