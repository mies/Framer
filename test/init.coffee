window.console.debug = (v) ->
# window.console.log = print

# hideFramerRoot = ->
	
# 	element = document.getElementById "FramerRoot"

# 	if not element
# 		return Utils.delay 0.01, hideFramerRoot

# 	_.extend element.style,
# 		top:  "-10000000px"
# 		left: "-10000000px"

# hideFramerRoot()

require "./tests/EventEmitterTest"
require "./tests/UtilsTest"
require "./tests/BaseClassTest"
require "./tests/FrameTest"
require "./tests/LayerTest"
require "./tests/LayerStatesTest"
require "./tests/VideoLayerTest"
require "./tests/CompatTest"
require "./tests/ImporterTest"
require "./tests/LayerAnimationTest"
require "./tests/ContextTest"

