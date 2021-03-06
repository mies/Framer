{_} = require "./Underscore"

Utils = require "./Utils"

{Config} = require "./Config"
{Defaults} = require "./Defaults"
{BaseClass} = require "./BaseClass"
{EventEmitter} = require "./EventEmitter"
{Animation} = require "./Animation"
{Frame} = require "./Frame"
{LayerStyle} = require "./LayerStyle"
{LayerStates} = require "./LayerStates"
{LayerDraggable} = require "./LayerDraggable"

layerValueTypeError = (name, value) ->
	throw new Error("Layer.#{name}: value '#{value}' of type '#{typeof(value)}'' is not valid")

layerProperty = (obj, name, cssProperty, fallback, validator, set) ->
	result = 
		exportable: true
		default: fallback
		get: -> 
			@_properties[name]

		set: (value) ->

			if value and validator and not validator(value)
				layerValueTypeError(name, value)

			@_properties[name] = value
			@_element.style[cssProperty] = LayerStyle[cssProperty](@)

			# @_dirtyStyle[cssProperty] = LayerStyle[cssProperty](@)
			# @_setNeedsRender()

			set?(@, value)
			@emit("change:#{name}", value)




class exports.Layer extends BaseClass

	# _setNeedsRender: ->
	# 	if @_needsRender is false
	# 		Framer.Loop.once "render", @_render
	# 		@_needsRender = true

	# _render: =>
	# 	@style = @_dirtyStyle
	# 	# console.log "_render"
	# 	@_dirtyStyle = {}
	# 	@_needsRender = false

	constructor: (options={}) ->

		@_properties = {}
		@_style = {}
		@_dirtyStyle = {}
		@_needsRender = false
		# @_classList = []

		# Special power setting for 2d rendering path. Only enable this
		# if you know what you are doing. See LayerStyle for more info.
		@_prefer2d = false
		@_cacheImage = false

		# We have to create the element before we set the defaults
		@_createElement()
		# @_setDefaultCSS()

		if options.hasOwnProperty "frame"
			options = _.extend(options, options.frame)

		options = Defaults.getDefaults "Layer", options

		super options

		# Add this layer to the current context
		@_context._layerList.push(@)

		@_id = @_context._layerList.length

		# Keep track of the default values
		# @_defaultValues = options._defaultValues

		# We need to explicitly set the element id again, becuase it was made by the super
		# @_element.id = "FramerLayer-#{@id}"

		for k in ["minX", "midX", "maxX", "minY", "midY", "maxY"]
			if options.hasOwnProperty k
				@[k] = options[k]

		# Insert the layer into the dom or the superLayer element
		if not options.superLayer
			@_insertElement() if not options.shadow
		else
			@superLayer = options.superLayer

		# Set needed private variables
		@_subLayers = []

		@_context.emit("layer:create", @)

	##############################################################
	# Properties

	# Css properties
	@define "width",  layerProperty @, "width",  "width", 100, _.isNumber
	@define "height", layerProperty @, "height", "height", 100, _.isNumber

	@define "visible", layerProperty @, "visible", "display", true, _.isBool
	@define "opacity", layerProperty @, "opacity", "opacity", 1, _.isNumber
	@define "index", layerProperty @, "index", "zIndex", 0, _.isNumber
	@define "clip", layerProperty @, "clip", "overflow", true, _.isBool
	
	@define "scrollHorizontal", layerProperty @, "scrollHorizontal", "overflowX", false, _.isBool, (layer, value) ->
		layer.ignoreEvents = false if value is true
	
	@define "scrollVertical", layerProperty @, "scrollVertical", "overflowY", false, _.isBool, (layer, value) ->
		layer.ignoreEvents = false if value is true

	@define "scroll",
		exportable: true
		get: -> @scrollHorizontal is true or @scrollVertical is true
		set: (value) -> @scrollHorizontal = @scrollVertical = value

	# Behaviour properties
	@define "ignoreEvents", layerProperty @, "ignoreEvents", "pointerEvents", true, _.isBool

	# Matrix properties
	@define "x", layerProperty @, "x", "webkitTransform", 0, _.isNumber
	@define "y", layerProperty @, "y", "webkitTransform", 0, _.isNumber
	@define "z", layerProperty @, "z", "webkitTransform", 0, _.isNumber

	@define "scaleX", layerProperty @, "scaleX", "webkitTransform", 1, _.isNumber
	@define "scaleY", layerProperty @, "scaleY", "webkitTransform", 1, _.isNumber
	@define "scaleZ", layerProperty @, "scaleZ", "webkitTransform", 1, _.isNumber
	@define "scale", layerProperty @, "scale", "webkitTransform", 1, _.isNumber

	@define "skewX", layerProperty @, "skewX", "webkitTransform", 0, _.isNumber
	@define "skewY", layerProperty @, "skewY", "webkitTransform", 0, _.isNumber
	@define "skew", layerProperty @, "skew", "webkitTransform", 0, _.isNumber

	# @define "scale",
	# 	get: -> (@scaleX + @scaleY + @scaleZ) / 3.0
	# 	set: (value) -> @scaleX = @scaleY = @scaleZ = value

	@define "originX", layerProperty @, "originX", "webkitTransformOrigin", 0.5, _.isNumber
	@define "originY", layerProperty @, "originY", "webkitTransformOrigin", 0.5, _.isNumber
	# @define "originZ", layerProperty @, "originZ", "WebkitTransformOrigin", 0.5

	@define "perspective", layerProperty @, "perspective", "webkitPerspective", 0, _.isNumber

	@define "rotationX", layerProperty @, "rotationX", "webkitTransform", 0, _.isNumber
	@define "rotationY", layerProperty @, "rotationY", "webkitTransform", 0, _.isNumber
	@define "rotationZ", layerProperty @, "rotationZ", "webkitTransform", 0, _.isNumber
	@define "rotation", layerProperty @, "rotationZ", "webkitTransform", 0, _.isNumber
	set_rotation: (value) -> @set_rotationZ(value)

	# Filter properties
	@define "blur", layerProperty @, "blur", "webkitFilter", 0, _.isNumber
	@define "brightness", layerProperty @, "brightness", "webkitFilter", 100, _.isNumber
	@define "saturate", layerProperty @, "saturate", "webkitFilter", 100, _.isNumber
	@define "hueRotate", layerProperty @, "hueRotate", "webkitFilter", 0, _.isNumber
	@define "contrast", layerProperty @, "contrast", "webkitFilter", 100, _.isNumber
	@define "invert", layerProperty @, "invert", "webkitFilter", 0, _.isNumber
	@define "grayscale", layerProperty @, "grayscale", "webkitFilter", 0, _.isNumber
	@define "sepia", layerProperty @, "sepia", "webkitFilter", 0, _.isNumber

	# Shadow properties
	@define "shadowX", layerProperty @, "shadowX", "boxShadow", 0, _.isNumber
	@define "shadowY", layerProperty @, "shadowY", "boxShadow", 0, _.isNumber
	@define "shadowBlur", layerProperty @, "shadowBlur", "boxShadow", 0, _.isNumber
	@define "shadowSpread", layerProperty @, "shadowSpread", "boxShadow", 0, _.isNumber
	@define "shadowColor", layerProperty @, "shadowColor", "boxShadow", ""

	# Color properties
	@define "backgroundColor", layerProperty @, "backgroundColor", "backgroundColor", null, _.isString
	@define "color", layerProperty @, "color", "color", null, _.isString

	# Border properties
	# Todo: make this default, for compat we still allow strings but throw a warning
	# @define "borderRadius", layerProperty @, "borderRadius", "borderRadius", 0, _.isNumber
	@define "borderColor", layerProperty @, "borderColor", "border", null, _.isString
	@define "borderWidth", layerProperty @, "borderWidth", "border", 0, _.isNumber

	@define "force2d", layerProperty @, "force2d", "webkitTransform", false, _.isBool

	##############################################################
	# Identity

	@define "name",
		exportable: true
		default: ""
		get: -> 
			@_getPropertyValue "name"
		set: (value) ->
			@_setPropertyValue "name", value
			# Set the name attribute of the dom element too
			# See: https://github.com/koenbok/Framer/issues/63
			@_element.setAttribute "name", value

	##############################################################
	# Border radius compatibility

	@define "borderRadius",
		exportable: true
		default: 0
		get: -> 
			@_properties["borderRadius"]

		set: (value) ->

			if value and not _.isNumber(value)
				console.warn "Layer.borderRadius should be a numeric property, not type #{typeof(value)}"

			@_properties["borderRadius"] = value
			@_element.style["borderRadius"] = LayerStyle["borderRadius"](@)

			@emit("change:borderRadius", value)

	##############################################################
	# Geometry

	@define "point",
		get: -> _.pick(@, ["x", "y"])
		set: (point) ->
			return if not point
			for k in ["x", "y"]
				@[k] = point[k] if point.hasOwnProperty(k)
					

	@define "frame",
		get: -> _.pick(@, ["x", "y", "width", "height"])
		set: (frame) ->
			return if not frame
			for k in ["x", "y", "width", "height"]
				@[k] = frame[k] if frame.hasOwnProperty(k)

	@define "minX",
		get: -> @x
		set: (value) -> @x = value

	@define "midX",
		get: -> Utils.frameGetMidX @
		set: (value) -> Utils.frameSetMidX @, value

	@define "maxX",
		get: -> Utils.frameGetMaxX @
		set: (value) -> Utils.frameSetMaxX @, value

	@define "minY",
		get: -> @y
		set: (value) -> @y = value

	@define "midY",
		get: -> Utils.frameGetMidY @
		set: (value) -> Utils.frameSetMidY @, value

	@define "maxY",
		get: -> Utils.frameGetMaxY @
		set: (value) -> Utils.frameSetMaxY @, value

	convertPoint: (point) ->
		# Convert a point on screen to this views coordinate system
		# TODO: needs tests
		Utils.convertPoint point, null, @

	@define "screenFrame",
		get: ->
			Utils.convertPoint(@frame, @, null)
		set: (frame) ->
			if not @superLayer
				@frame = frame
			else
				@frame = Utils.convertPoint(frame, null, @superLayer)

	contentFrame: ->
		Utils.frameMerge(_.pluck(@subLayers, "frame"))

	centerFrame: ->
		# Get the centered frame for its superLayer
		if @superLayer
			frame = @frame
			Utils.frameSetMidX(frame, parseInt(@superLayer.width  / 2.0))
			Utils.frameSetMidY(frame, parseInt(@superLayer.height / 2.0))
			return frame
		else if @_context._parentLayer
			frame = @frame
			Utils.frameSetMidX(frame, parseInt(@_context._parentLayer.width  / 2.0))
			Utils.frameSetMidY(frame, parseInt(@_context._parentLayer.height / 2.0))
			return frame
		else
			frame = @frame
			Utils.frameSetMidX(frame, parseInt(window.innerWidth  / 2.0))
			Utils.frameSetMidY(frame, parseInt(window.innerHeight / 2.0))
			return frame

	center: ->
		@frame = @centerFrame() # Center  in superLayer
		@
	
	centerX: (offset=0) ->
		@x = @centerFrame().x + offset # Center x in superLayer
		@
	
	centerY: (offset=0) ->
		@y = @centerFrame().y + offset # Center y in superLayer
		@

	pixelAlign: ->
		@x = parseInt @x
		@y = parseInt @y


	##############################################################
	# SCREEN GEOMETRY

	# TODO: Rotation/Skew

	# screenOriginX = ->
	# 	if @_superOrParentLayer()
	# 		return @_superOrParentLayer().screenOriginX()
	# 	return @originX
	
	# screenOriginY = ->
	# 	if @_superOrParentLayer()
	# 		return @_superOrParentLayer().screenOriginY()
	# 	return @originY

	screenScaleX: ->
		scale = @scale * @scaleX
		for superLayer in @superLayers(context=true)
			scale = scale * superLayer.scale * superLayer.scaleX
		return scale

	screenScaleY: ->
		scale = @scale * @scaleY
		for superLayer in @superLayers(context=true)
			scale = scale * superLayer.scale * superLayer.scaleY
		return scale

	screenScaledFrame: ->
		frame =
			x: 0
			y: 0
			width:  @width  * @screenScaleX()
			height: @height * @screenScaleY()
		
		layers = @superLayers(context=true)
		layers.push(@)
		layers.reverse()
		
		for superLayer in layers
			factorX = if superLayer._superOrParentLayer() then superLayer._superOrParentLayer().screenScaleX() else 1
			factorY = if superLayer._superOrParentLayer() then superLayer._superOrParentLayer().screenScaleY() else 1
			layerScaledFrame = superLayer.scaledFrame()
			frame.x += layerScaledFrame.x * factorX
			frame.y += layerScaledFrame.y * factorY

		return frame

	scaledFrame: ->

		# Get the scaled frame for a layer, taking into account 
		# the transform origins.

		frame = @frame
		scaleX = @scale * @scaleX
		scaleY = @scale * @scaleY

		frame.width  *= scaleX
		frame.height *= scaleY
		frame.x += (1 - scaleX) * @originX * @width
		frame.y += (1 - scaleY) * @originY * @height
		
		return frame

	##############################################################
	# CSS

	@define "style",
		get: -> @_element.style
		set: (value) ->
			_.extend @_element.style, value
			@emit "change:style"

	computedStyle: ->
		# This is an expensive operation

		getComputedStyle  = document.defaultView.getComputedStyle
		getComputedStyle ?= window.getComputedStyle
		
		return getComputedStyle(@_element)

	@define "classList",
		get: -> @_element.classList

	##############################################################
	# DOM ELEMENTS

	_createElement: ->
		return if @_element?
		@_element = document.createElement "div"
		@_element.classList.add("framerLayer")

	_insertElement: ->
		@bringToFront()
		@_context.getRootElement().appendChild(@_element)

	@define "html",
		get: ->
			@_elementHTML?.innerHTML

		set: (value) ->

			# Insert some html directly into this layer. We actually create
			# a child node to insert it in, so it won't mess with Framers
			# layer hierarchy.

			if not @_elementHTML
				@_elementHTML = document.createElement "div"
				@_element.appendChild @_elementHTML

			@_elementHTML.innerHTML = value

			# If the contents contains something else than plain text
			# then we turn off ignoreEvents so buttons etc will work.

			# if not (
			# 	@_elementHTML.childNodes.length == 1 and
			# 	@_elementHTML.childNodes[0].nodeName == "#text")
			# 	@ignoreEvents = false

			@emit "change:html"

	querySelector: (query) -> @_element.querySelector(query)
	querySelectorAll: (query) -> @_element.querySelectorAll(query)

	destroy: ->
		
		# Todo: check this

		if @superLayer
			@superLayer._subLayers = _.without @superLayer._subLayers, @

		@_element.parentNode?.removeChild @_element
		@removeAllListeners()
		
		@_context._layerList = _.without @_context._layerList, @

		@_context.emit("layer:destroy", @)


	##############################################################
	## COPYING

	copy: ->

		# Todo: what about events, states, etc.

		layer = @copySingle()

		for subLayer in @subLayers
			copiedSublayer = subLayer.copy()
			copiedSublayer.superLayer = layer

		layer

	copySingle: -> new Layer @properties

	##############################################################
	## IMAGE

	@define "image",
		exportable: true
		default: ""
		get: ->
			@_getPropertyValue "image"
		set: (value) ->

			if not (_.isString(value) or value is null)
				layerValueTypeError("image", value)

			currentValue = @_getPropertyValue "image"

			if currentValue == value
				return @emit "load"

			# Todo: this is not very nice but I wanted to have it fixed
			# defaults = Defaults.getDefaults "Layer", {}

			# console.log defaults.backgroundColor
			# console.log @_defaultValues?.backgroundColor

			# if defaults.backgroundColor == @_defaultValues?.backgroundColor
			# 	@backgroundColor = null

			@backgroundColor = null

			# Set the property value
			@_setPropertyValue("image", value)

			if value in [null, ""]
				@style["background-image"] = null
				return

			imageUrl = value

			# Optional base image value
			# imageUrl = Config.baseUrl + imageUrl

			# If the file is local, we want to avoid caching
			# if Utils.isLocal() and not (_.startsWith(imageUrl, "http://") or _.startsWith(imageUrl, "https://"))
			if Utils.isLocal() and not imageUrl.match(/^https?:\/\//) and @_cacheImage is false
				imageUrl += "?nocache=#{Date.now()}"

			# As an optimization, we will only use a loader
			# if something is explicitly listening to the load event

			if @events?.hasOwnProperty "load" or @events?.hasOwnProperty "error"

				loader = new Image()
				loader.name = imageUrl
				loader.src = imageUrl

				loader.onload = =>
					@style["background-image"] = "url('#{imageUrl}')"
					@emit "load", loader

				loader.onerror = =>
					@emit "error", loader

			else
				@style["background-image"] = "url('#{imageUrl}')"

	##############################################################
	## HIERARCHY

	@define "superLayer",
		exportable: false
		get: ->
			@_superLayer or null
		set: (layer) ->

			return if layer is @_superLayer

			# Check the type
			if not layer instanceof Layer
				throw Error "Layer.superLayer needs to be a Layer object"

			# Cancel previous pending insertions
			Utils.domCompleteCancel @__insertElement

			# Remove from previous superlayer sublayers
			if @_superLayer
				@_superLayer._subLayers = _.without @_superLayer._subLayers, @
				@_superLayer._element.removeChild @_element
				@_superLayer.emit "change:subLayers", {added:[], removed:[@]}

			# Either insert the element to the new superlayer element or into dom
			if layer
				layer._element.appendChild @_element
				layer._subLayers.push @
				layer.emit "change:subLayers", {added:[@], removed:[]}
			else
				@_insertElement()

			# Set the superlayer
			@_superLayer = layer

			# Place this layer on top of its siblings
			@bringToFront()

			@emit "change:superLayer"

	# Todo: should we have a recursive subLayers function?
	# Let's make it when we need it.

	@define "subLayers",
		exportable: false
		get: -> _.clone @_subLayers

	@define "siblingLayers",
		exportable: false
		get: ->

			# If there is no superLayer we need to walk through the root
			if @superLayer is null
				return _.filter @_context._layerList, (layer) =>
					layer isnt @ and layer.superLayer is null

			return _.without @superLayer.subLayers, @

	addSubLayer: (layer) ->
		layer.superLayer = @

	removeSubLayer: (layer) ->

		if layer not in @subLayers
			return

		layer.superLayer = null

	subLayersByName: (name) ->
		_.filter @subLayers, (layer) -> layer.name == name

	superLayers: (context=false) ->

		superLayers = []
		currentLayer = @

		if context is false
			while currentLayer.superLayer
				superLayers.push(currentLayer.superLayer)
				currentLayer = currentLayer.superLayer
		else
			while currentLayer._superOrParentLayer()
				superLayers.push(currentLayer._superOrParentLayer())
				currentLayer = currentLayer._superOrParentLayer()

		return superLayers

	_superOrParentLayer: ->
		if @superLayer
			return @superLayer
		if @_context._parentLayer
			return @_context._parentLayer

	##############################################################
	## ANIMATION

	animate: (options) ->

		start = options.start
		start ?= true
		delete options.start

		options.layer = @
		animation = new Animation options
		animation.start() if start
		animation

	animations: ->
		# Current running animations on this layer
		_.filter @_context._animationList, (animation) =>
			animation.options.layer == @

	animatingProperties: ->

		properties = {}

		for animation in @animations()
			for propertyName in _.keys(animation._stateA)
				properties[propertyName] = animation

		return properties

	@define "isAnimating",
		exportable: false
		get: -> @animations().length isnt 0

	animateStop: ->
		_.invoke(@animations(), "stop")

	##############################################################
	## INDEX ORDERING

	bringToFront: ->
		@index = _.max(_.union([0], @siblingLayers.map (layer) -> layer.index)) + 1

	sendToBack: ->
		@index = _.min(_.union([0], @siblingLayers.map (layer) -> layer.index)) - 1

	placeBefore: (layer) ->
		return if layer not in @siblingLayers

		for l in @siblingLayers
			if l.index <= layer.index
				l.index -= 1

		@index = layer.index + 1

	placeBehind: (layer) ->
		return if layer not in @siblingLayers

		for l in @siblingLayers
			if l.index >= layer.index
				l.index += 1

		@index = layer.index - 1

	##############################################################
	## STATES

	@define "states",
		get: -> @_states ?= new LayerStates @

	#############################################################################
	## Draggable

	@define "draggable",
		get: ->
			@_draggable ?= new LayerDraggable @
			@_draggable
		set: ->
			throw Error "You can't set the draggable object"

	##############################################################
	## SCROLLING

	# TODO: Tests

	@define "scrollFrame",
		get: ->
			return new Frame
				x: @scrollX
				y: @scrollY
				width: @width
				height: @height
		set: (frame) ->
			@scrollX = frame.x
			@scrollY = frame.y

	@define "scrollX",
		get: -> @_element.scrollLeft
		set: (value) ->
			layerValueTypeError("scrollX", value) if not _.isNumber(value)
			@_element.scrollLeft = value

	@define "scrollY",
		get: -> @_element.scrollTop
		set: (value) -> 
			layerValueTypeError("scrollY", value) if not _.isNumber(value)
			@_element.scrollTop = value

	##############################################################
	## EVENTS

	addListener: (eventNames..., originalListener) =>

		# To avoid an error in Framer Studio we return if no originalListener was given
		if not originalListener
			return

		# # Modify the scope to be the calling object, just like jquery
		# # also add the object as the last argument
		listener = (args...) =>
			originalListener.call(@, args..., @)

		# Because we modify the listener we need to keep track of it
		# so we can find it back when we want to unlisten again
		originalListener.modifiedListener = listener

		eventNames = [eventNames] if typeof eventNames == 'string'

		# Listen to dom events on the element
		for eventName in eventNames
			do (eventName) =>
				super eventName, listener
				@_context.eventManager.wrap(@_element).addEventListener(eventName, listener)

				@_eventListeners ?= {}
				@_eventListeners[eventName] ?= []
				@_eventListeners[eventName].push(listener)

				# We want to make sure we listen to these events, but we can safely
				# ignore it for change events
				if not _.startsWith eventName, "change:"
					@ignoreEvents = false

	removeListener: (eventNames..., listener) ->

		# If the original listener was modified, remove that
		# one instead
		if listener.modifiedListener
			listener = listener.modifiedListener

		eventNames = [eventNames] if typeof eventNames == 'string'
			
		for eventName in eventNames
			do (eventName) =>
				super eventName, listener
				
				@_context.eventManager.wrap(@_element).removeEventListener(eventName, listener)

				if @_eventListeners
					@_eventListeners[eventName] = _.without @_eventListeners[eventName], listener

	once: (eventName, listener) ->

		originalListener = listener

		listener = (args...) =>
			originalListener(args...)
			@removeListener(eventName, listener)

		@addListener(eventName, listener)


	removeAllListeners: ->

		return if not @_eventListeners

		for eventName, listeners of @_eventListeners
			for listener in listeners
				@removeListener eventName, listener

	on: @::addListener
	off: @::removeListener

	##############################################################
	## DESCRIPTOR

	toString: ->

		round = (value) ->
			if parseInt(value) == value
				return parseInt(value)
			return Utils.round(value, 1)

		if @name
			return "&lt;Layer id:#{@id} name:#{@name} (#{round(@x)},#{round(@y)}) #{round(@width)}x#{round(@height)}&gt;"
		return "&lt;Layer id:#{@id} (#{round(@x)},#{round(@y)}) #{round(@width)}x#{round(@height)}&gt;"
