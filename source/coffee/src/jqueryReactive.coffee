$ = jQuery

$.fn.reactive = (event, valueExtractor = (jQueryNode, e) -> jQueryNode) ->
	reactiveValue = reactive.new()
	@each -> $(this).on(event, (e) => reactiveValue.reactTo(valueExtractor(this, e)))
	reactiveValue
	
$.fn.createReactiveProperty = (initialValue, event, valueExtractor = (jQueryNode, e) -> jQueryNode) ->
	reactiveProperty = new reactive.property initialValue
	@each -> $(this).on(event, (e) => reactiveProperty.reactTo(valueExtractor(this, e)))
	reactiveProperty

$.fn.setReactiveProperty = (reactiveProperty, event, valueExtractor = (jQueryNode, e) -> jQueryNode) ->
	@each -> $(this).on(event, (e) => reactiveProperty.reactTo(valueExtractor(this, e)))

$.fn.show = (reactiveValue, reactor = (node, newVal) -> $(node).html(newVal)) ->
	@each -> reactiveValue.addReactor((newVal) => reactor(this, newVal))
	this

$.fn.showProperty = (reactiveProperty, reactor = (node, newVal) -> $(node).html(newVal)) ->
	@each -> reactiveProperty.addReactor((newVal) => reactor(this, newVal))
	this
