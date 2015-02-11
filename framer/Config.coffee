Utils = require "./Utils"

FramerCSS = """
body {
	margin: 0;
}

.framerContext {	
	position: absolute;
	left: 0;
	top: 0;
	right: 0;
	bottom: 0;
	pointer-events: none;
	overflow: hidden;
}

.framerLayer {
	display: block;
	position: absolute;
	background-repeat: no-repeat;
	background-size: cover;
	-webkit-overflow-scrolling: touch;
	-webkit-box-sizing: border-box;
	-webkit-user-select: none;
}

.framerLayer input,
.framerLayer textarea,
.framerLayer select,
.framerLayer option,
.framerLayer div[contenteditable=true]
{
	pointer-events: auto;
	-webkit-user-select: auto;
}

.framerDebug {
	padding: 6px;
	color: #fff;
	font: 10px/1em Monaco;
}

"""

Utils.domComplete -> Utils.insertCSS(FramerCSS)