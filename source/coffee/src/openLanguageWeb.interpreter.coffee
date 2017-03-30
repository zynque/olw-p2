
olw.interpreter = {}

malformedHeaderMessage = "Malformed Document Header"
malformedDocumentMessage = "Malformed Document (undefined or no children)"
malformedStandardDocumentMessage = "Malformed Standard Document"
unknownHeaderMessage = "Unknown Document Header Url"

olw.interpreter.interpretStoredDoc = (repo, docId, docVersion) ->
	doc = repo.documents.get(docId, docVersion)
	olw.interpreter.interpret(doc)

olw.interpreter.interpret = (doc) ->
	if(!doc? or !doc.children?)
		return malformedDocumentMessage
	if(doc.children.length < 1)
		return []
	header = doc.children[0]
	if(!header.data? or !header.data.type is "string" or !header.data.value?)
		return malformedHeaderMessage
	headerUrl = header.data.value
	interpret = getInterpreterFor(headerUrl)
	interpret(doc)


getInterpreterFor = (headerUrl) ->
	if(headerUrl is olw.standardDocumentHeader)
		standardDocumentInterpreter
	else if(headerUrl is olw.bootstrapDocumentHeader)
		bootstrapDocumentInterpreter
	else
		(doc) -> unknownHeaderMessage + ": " + headerUrl


bootstrapDocumentInterpreter =
	(doc) -> "not implemented"


standardDocumentInterpreter = (doc) ->
	if(doc.children.length != 3)
		return malformedStandardDocumentMessage
	contentNode = doc.children[2]
	interpretation = interpretContent(contentNode)
	interpretation


interpretContent = (contentNode) ->
	for child in contentNode.children
		interpretNode(child)


trace = ""


interpretNode = (node) ->
	trace += "interpreting node: " + node.id + " "
	if(!node.interpretation?)
		if(node.data?)
			node.interpretation = interpretNodeData(node.data)
		else if(node.children.length == 0)
			node.interpretation = []
		else
			nochildren = false
			func = interpretNode(node.children[0])
			args = (interpretNode(child) for child in node.children[1..])
			if !func? or nochildren
				interpretNode(node.children[0])
			# Should we be using type markers to indicate whether a func or val?
			# or is this the most natural way in javascript?
			# perhaps we postpone this question until we introduce a type system
			if(func.apply?)
				node.interpretation = func(args...)
			else
				node.interpretation = func
	node.interpretation


interpretBackingNode = (doc, nodeId) ->
	node = doc.nodes[nodeId]
	trace += "interpreting backing node: " + nodeId + " "
	if(!node.interpretation?)
		if(node.data?)
			node.interpretation = interpretBackingNodeData(node.data)
		else if(node.children.length == 0)
			node.interpretation = []
		else
			func = interpretBackingNode(doc, node.children[0])
			args = (interpretBackingNode(doc, child) for child in node.children[1..])
			node.interpretation = func(args...)
	node.interpretation


documentNodeReferenceFunc = (docUrl, nodeId) ->
	doc = olw.documentCache[docUrl]
	if(!doc?)
		["document could not be found: " + docUrl]
	else
		interpretBackingNode(doc.backingDocument, nodeId)



interpretNodeData = (nodeData) ->
	if(nodeData.interpretation)
		nodeData.interpretation
	else
		if(nodeData.type == "documentNodeReference")
			documentNodeReferenceFunc
			#interpretNode(nodeData.referencedNode)
		else if(nodeData.type == "nodeReference")
			if(nodeData.referencedNode?)
				interpretNode(nodeData.referencedNode)
			else
				"Unfinished"
		else
			nodeData.value


interpretBackingNodeData = (nodeData) ->
	if(nodeData.interpretation)
		nodeData.interpretation
	else
		if(nodeData.type == "documentNodeReference")
			documentNodeReferenceFunc
			#interpretNode(nodeData.referencedNode)
		else if(nodeData.type == "nodeReference")
			if(nodeData.referencedNode?)
				interpretBackingNode(nodeData.referencedNode.getDocument().backingDocument, nodeData.referencedNode.id)
			else
				"Unfinished"
		else
			nodeData.value
