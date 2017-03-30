window.using = (obj, func) -> func.apply(obj)

window.funcContainer =
	new: ->
		addFuncsFrom: (sourceObj) ->
			this[funcName] = func for own funcName, func of sourceObj
