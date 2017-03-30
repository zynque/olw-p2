
convertStoredNodeToArray = (doc, nodeId, recordedNodes) ->
	node = doc.nodes[nodeId]	
	if(node.data?)
		[nodeId, node.data]
	else if(node.children.length == 1)
		[nodeId, convertStoredNodeToArray(doc, node.children[0], recordedNodes)]
	else
		childrenAsArray = (convertStoredNodeToArray(doc, childId, recordedNodes) for childId in node.children)
		[nodeId, childrenAsArray]
	

olw.convertStoredNodeToArray = convertStoredNodeToArray

olw.convertStoredDocumentToArray = (doc, version) ->
	convertStoredNodeToArray(doc, doc.versions[version].rootId, [])


removeNodeRefsFromData = (data) ->
	if typeof data is 'object'
		convertedData = {}
		for own name, value of data
			if(value? and value.id? and (value.children? or value.data?))
				convertedData[name] = {referenceToNode: value.id}
			else
				convertedData[name] = value
		convertedData
	else
		data
	
convertNodeToArray = (node) ->
	if(!node?)
		["undefined node"]
	else if(node.data?)
		[node.id, removeNodeRefsFromData(node.data)]
	else if(!node.children?)
		["malformed node - no data or children"]
	else if(node.children.length == 1)
		[node.id, convertNodeToArray(node.children[0])]
	else
		[node.id, (convertNodeToArray(child) for child in node.children)]

olw.convertNodeToArray = convertNodeToArray

olw.convertLiveDocumentToArray = (doc) ->
	convertNodeToArray(doc.documentNode)


convertNodeToArrayWithNoIds = (node) ->
	if(node.data?)
		[node.data]
	else if(node.children.length == 1)
		[convertNodeToArrayWithNoIds(node.children[0])]
	else
		[(convertNodeToArrayWithNoIds(child) for child in node.children)]

olw.convertLiveDocumentToArrayWithNoIds = (doc) ->
	convertNodeToArrayWithNoIds(doc.documentNode)


generateTabs = (tabs) ->
	result = ""
	atab = "&nbsp&nbsp"
	for i in [0 .. tabs]
		result += atab
	result
	
olw.generateTabs = generateTabs

convertObjectToFriendlyText = (obj) ->
	result = "{"
	for own property, value of obj
		result += property + ":" + value + ", "
	result + "}"

convertNodeToFriendlyText = (node, tabs) ->
	if(!node?)
		generateTabs(tabs) + "(malformed node - undefined)"
	else if(node.data?)
		dataAsText = convertObjectToFriendlyText(removeNodeRefsFromData(node.data))
		generateTabs(tabs) + node.id + ": " + dataAsText + "<br>"
	else if(!node.children?)
		generateTabs(tabs) + node.id + ": " + "(malformed node - no data or children)"
#	else if(node.children.length == 1)
#		[node.id, convertNodeToArray(node.children[0])]
	else
		childrenText = ""
		for child in node.children
			childrenText += convertNodeToFriendlyText(child, tabs + 1)
		generateTabs(tabs) + node.id + ":<br>" + childrenText

olw.convertNodeToFriendlyText = convertNodeToFriendlyText

olw.convertLiveDocumentToFriendlyText = (doc) ->
	convertNodeToFriendlyText(doc.documentNode, 0)
