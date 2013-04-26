package  
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.utils.getTimer;
	/**
	 * ...
	 * @author Ben
	 * 
	 * 	 
	 */
	public class Poly extends Sprite 
	{
		private static var counter:int = 0;
		
		public const MAX_TIME_DISPLAY:uint = 30000;
		private var points:Array;
		private var deleteDate:Boolean = false;
		private var initialBounds:Rectangle;
		private var nowBounds:Rectangle;
		private var mainfxn:Main;
		private var theStage:Stage;
		private var lastIndex:int = 0;
		private var redraw:Boolean = false;
		private var runner:Runner;
		public var displaySprite:Sprite;
		public static const MAX:int = 1;
		public static const MIN:int = 0;
		private var oldScale:Array = new Array(2);
		private var topScale:TextField;
		private var bottomScale:TextField;
		private var xAxisLabels:Sprite = new Sprite();
		private var yAxisLabels:Sprite = new Sprite();
		private var TimeBackCounter:int = 0;
		private var dontTranslate:Boolean = false;
		private var _visible:Boolean = true;
		
		public function Poly(_stage:Stage, bounds:Rectangle, maininstance:Main, _nowBounds:Rectangle = null, pts:Array = null, context:Runner = null, _visible:Boolean = true) {
			super();
			this.initialBounds = bounds;
			this.mainfxn = maininstance;
			this.visible = true;
			this.runner = context;
			this.displaySprite = new Sprite();
			this.displaySprite.y = 60;
			this.displaySprite.x = 0;
			displaySprite.name = "display sprite" + counter;
			counter++;
			displaySprite.graphics.lineStyle(1, 0x000000, 1);
			displaySprite.opaqueBackground = 0xFFFFFFFF;
			theStage = _stage;
			this._visible = _visible
			theStage.addChildAt(displaySprite, 1);
			if (!_visible) {
				displaySprite.visible = false;
			}
			if (_nowBounds != null) {
				this.nowBounds = _nowBounds;
			} else {
				this.nowBounds = bounds;
			}
			if (pts != null) {
				this.points = pts;
			} else {
				this.points = new Array();
			}
			this.drawAxis(displaySprite.graphics);
			labelAxis();
		}
		/**
		 * Removes the current displaySprite from view and clears everything from it
		 */
		public function kill():void {
			displaySprite.graphics.clear();
			if (theStage.contains(displaySprite)) { 
				theStage.removeChild(displaySprite); }
			
		}
		/**
		 * Draws all of the points
		 * @param	g
		 */
		private function drawPoints(g:Graphics):void {
			if (points.length > 1) {
				var point:Point = points[0];
				g.moveTo(point.x, point.y);
				for (var i:int = 1; i < points.length; i++) {
					point = points[i];
					g.lineTo(point.x, point.y);
				}
			}
		}
		/**
		 * Draw the axis
		 * @param	g
		 */
		private function drawAxis(g:Graphics):void {
			g.lineStyle(1, 0x000000, 1);
			g.moveTo(40, 0);
			g.lineTo(40, (mainfxn.getVideo()).height-30);
			g.lineTo((mainfxn.getVideo()).width, (mainfxn.getVideo()).height-30);
		}
		/**
		 * Label them... arguments are unnecessary, but were used for rescaling at one point
		 * @param	bottom
		 * @param	top
		 */
		private function labelAxis(bottom:int = -1, top:int = -1):void {
			rotateText("Brightness (%)", -90, 0, mainfxn.getVideo().height / 2);
			var label:TextField = new TextField();
			label.text = "Time (seconds)";
			label.x = mainfxn.getVideo().width * .82;
			label.y = mainfxn.getVideo().height - 50;
			label.width = 150;
			var format:TextFormat = new TextFormat();
			format.size = 17;
			label.setTextFormat(format);
			
			displaySprite.addChild(label);
			if (bottom == -1) { 
				bottom = runner.getScale()[1]; 
			}
			if (top == -1) { 
				top = runner.getScale()[0];
			}
			labelYAxis(bottom, top);
			labelXAxis();
		}
		/**
		 * Label the y-axis from @param bottom to @param top
		 * @param	bottom
		 * @param	top
		 */
		private function labelYAxis(bottom:int, top:int):void {
			if (displaySprite.contains(yAxisLabels)) {
				displaySprite.removeChild(yAxisLabels);
				yAxisLabels.graphics.clear();
				while (yAxisLabels.numChildren > 0) {
					yAxisLabels.removeChildAt(0);
				}
			}
			var scale:Array = [ top, bottom ];
			//scale[0] is top, scale[1] is bottom;
			var spaceBetween:int;
			if (scale[0] - scale[1] > 80) {
				spaceBetween = 20;
			} else if (scale[0] - scale[1] > 40) {
				spaceBetween = 10;
			} else {
				spaceBetween = 5;
			}
			displaySprite.graphics.lineStyle(1, 0xB3B3B3);
			for (var i:int = scale[1] + spaceBetween; i < scale[0]; i += spaceBetween) {	//don't include the editable text fields at the lower and upper bounds
				var label:TextField = new TextField();
				label.text = String(i);
				label.x = 20;
				label.y =  (nowBounds.bottom - 30) - ((i - scale[1]) / (scale[0] - scale[1]) * (nowBounds.bottom - 30));
				var format:TextFormat = new TextFormat();
				format.size = 18;
				label.setTextFormat(format);
				yAxisLabels.addChild(label);
				
				displaySprite.graphics.moveTo(40, label.y+10);
				displaySprite.graphics.lineTo(nowBounds.right, label.y+10);
			}
			
			topScale = makeEditableText(String(scale[0]), 10, 0);
			
			bottomScale = makeEditableText(String(scale[1]), 15, nowBounds.bottom - 40);
			displaySprite.graphics.moveTo(15, 0);
			displaySprite.graphics.lineTo(nowBounds.right, 0);
			displaySprite.graphics.lineStyle(1, 0x000000);
			
			topScale.addEventListener(FocusEvent.FOCUS_OUT, reScaleWrapper);
			topScale.addEventListener(KeyboardEvent.KEY_DOWN, keyPressed);
			bottomScale.addEventListener(FocusEvent.FOCUS_OUT, reScaleWrapper);
			bottomScale.addEventListener(KeyboardEvent.KEY_DOWN, keyPressed);
			oldScale[0] = scale[0];
			oldScale[1] = scale[1];
			yAxisLabels.addChild(topScale);
			yAxisLabels.addChild(bottomScale);
			displaySprite.addChild(yAxisLabels);
		}
		/**
		 * Helper to make the upper and lower scales editable for people to manually adjust the scale
		 * @param	label: Text to display
		 * @param	x: x coord
		 * @param	y: y coord
		 * @return the TextField
		 */
		private function makeEditableText(label:String, x:int, y:int):TextField {
			var format:TextFormat = new TextFormat();
			format.underline = true;
			format.size = 17;
			format.align = TextFormatAlign.CENTER;
			var editableText:TextField = new TextField();
			editableText.defaultTextFormat = format;
			editableText.border = true;
			editableText.borderColor = 0x000000;
			editableText.text = label;
			editableText.x = x;
			editableText.y = y;
			editableText.width = 25;
			editableText.type = TextFieldType.INPUT;
			editableText.background = true;
			editableText.backgroundColor = 0xFFFFFF;
			editableText.height = 30;
			editableText.autoSize = TextFieldAutoSize.CENTER;
			
			
			return editableText;
		}
		/**
		 * Label the x axis -- relies on a count of how many times we've translated points back
		 */
		private function labelXAxis():void {
			if (displaySprite.contains(xAxisLabels)) {
				displaySprite.removeChild(xAxisLabels);
				while (xAxisLabels.numChildren > 0) {
					xAxisLabels.removeChildAt(0);
				}
			}
			var timeBetween:int;
			timeBetween = 5;
			var first:int = 0;
			
			first = 0 + 15 * TimeBackCounter;
			var k:int = 0;
			displaySprite.graphics.lineStyle(1, 0xB3B3B3);
			for (var i:int = first; i <= first + 30; i += timeBetween) {
				var back:int = 13;
				if (i == first) {
					back = 3;
				}
				if (i == first + 30) {
					back = 20;
				}
				
				var label:TextField = new TextField;
				label.text = String(i);
				label.x = 40 + (k / (30/timeBetween)) * (nowBounds.right - 40) - back;
				var format:TextFormat = new TextFormat();
				format.size = 18;
				label.setTextFormat(format);
				k++;
				label.y = nowBounds.bottom - 20;
				xAxisLabels.addChild(label);
				
				displaySprite.graphics.moveTo(label.x+back, nowBounds.bottom - 20);
				displaySprite.graphics.lineTo(label.x+back, 0);
			}
			displaySprite.graphics.lineStyle(1, 0x000000);
			displaySprite.addChild(xAxisLabels);
		}
		/**
		 * I thought this would be more useful than it actually is... its a way to make rotated text fields
		 * Really only the y-axis label uses it. It also adds it to the stage for you
		 * @param	text: text to display
		 * @param	rotation: amount of rotation in degrees
		 * @param	x: x coord
		 * @param	y: y coord
		 */
		private function rotateText(text:String, rotation:int, x:int, y:int):void {
			var label:TextField = new TextField();

			label.text = text;
			var format:TextFormat = new TextFormat();
			format.size = 17;
			label.setTextFormat(format);
			label.autoSize = TextFieldAutoSize.LEFT;
			var bitMapData:BitmapData = new BitmapData(120,20);
			bitMapData.draw(label);
			var bitMap:Bitmap = new Bitmap(bitMapData);
			
			bitMap.rotation = rotation;
			bitMap.x = x;
			bitMap.y = y;

			displaySprite.addChild(bitMap);
		}
		private function removeAbove(x:int):void {
			removeAboveUnscaled(scaleInX(x));
		}
		
		private function removeBelow(x:int):void {
			removeBelowUnscaled(scaleInX(x));
		}
		private function removeBelowUnscaled(x:int):void {
			var p:Point = null;
			var lastIndex:int = -1;
			var pointsTemp:Array = points.filter(function(elm:Point, index:int, arr:Object):Boolean { 
					return (elm.x > x) } );
			if (pointsTemp.length > 0) { p = points[pointsTemp.length - 1];}
					
			if (p != null && p.x != x) {
				var firstPoint:Point = pointsTemp[0];
				addUnscaledPoint(new Point(x, (x - firstPoint.x) * (p.y - firstPoint.y) / (p.x - firstPoint.x) + firstPoint.y));
			}
			points = pointsTemp;
		}
		private function removeAboveUnscaled(x:int):void {
			var p:Point = null;
			var lastIndex:int = -1;
			var pointsTemp:Array = points.filter(function(elm:Point, index:int, arr:Object):Boolean { 
					if (index < lastIndex) { lastIndex = index;}
					return (elm.x < x) } );
			if (lastIndex != -1) {p = points[lastIndex];}
					
			if (lastIndex != -1 && p != null && p.x != x) {
				var lastPoint:Point = pointsTemp[pointsTemp.length - 1];
				addUnscaledPoint(new Point(x, (x - lastPoint.x) * (p.y - lastPoint.y) / (p.x - lastPoint.x) + lastPoint.y));
			}
			points = pointsTemp;
		}
		public function addUnscaledPoint(add_p:Point):Point {
			if (new Date().getTime() - mainfxn.getXTime() > mainfxn.getTimeExecution()) {
				//removeBelow((new Date().getTime() - mainfxn.getXTime()) / 
			}
			if (points.length == 0) {
				points[0] = add_p;
				return null;
			} else if (add_p.x > lastUnscaledX()) {
				points[points.length] = add_p;
				return null;
			} else if (add_p.x < firstUnscaledX()) {
				points = addtoArray(add_p, points, 0);
				return null;
			} else {
				var push:Boolean = false;
				
				for (var index:int = 0; index < points.length - 1; index++) {
					if (add_p.x == points[index]) {
						var temp:Point = points[index];
						points[index] = add_p;
						return temp;
					}
					if (index == points.length - 1) { break;}
					if (add_p.x > points[index] && add_p.x < points[index + 1]) {
						points = addtoArray(add_p, points, index);
						return null;
					}
				
				}
			}
			return null;
		}
		private function addtoArray(p:Point, arr:Array, ind:int):Array {
			for (var i:int = arr.length; i > ind; i--) {
				arr[i] = arr[i - 1];
			}
			arr[ind] = p;
			return arr;
		}
		private function lastUnscaledX():int {
			return (points[points.length - 1] as Point).x;
		}
		
		private function firstUnscaledX():int {
			if (points.length > 0) {
				return (points[0] as Point).x;
			}
			return 0;
		}
		/**
		 * These two getters are unnecessary and/or unused
		 * 
		 */
		private function lastX():int {
			return scaleOutX(lastUnscaledX());
		}
		private function firstX():int {
			return scaleOutX(firstUnscaledX());
		}

		private function scaleInPoint(point:Point):Point {
			return new Point(scaleInX(point.x), scaleInY(point.y));
		}
		private function scaleOutX(x:int):int {
			if (nowBounds.equals(initialBounds)) {
				return x;
			} 
			return ((x - initialBounds.x) * nowBounds.width / initialBounds.width) + nowBounds.x;
		}
		private function scaleOutY(y:int):int {
			if (nowBounds.equals(initialBounds)) {
				return y;
			}
			return ((y - initialBounds.y) * nowBounds.height / initialBounds.height) + nowBounds.y;
		}
		private function scaleInX(x:int):int {
			if (nowBounds.equals(initialBounds)) {
				return x;
			}
			return ((x - nowBounds.x) * initialBounds.width / nowBounds.width) + initialBounds.x;
		}
		private function scaleInY(y:int):int {
			if (nowBounds.equals(initialBounds)) {
				return y;
			}
			return ((y - nowBounds.y) * initialBounds.height / nowBounds.height) + initialBounds.y;
		}
		private function scale(newBounds:Rectangle):void {
			nowBounds = newBounds;
		}
		public function isEmpty():Boolean { return points.length == 0; }
		
		/**
		 * Most of the bulk of Poly is found in here... this draws the displaySprite according to the state of
		 * poly and runner -- there are several flags -- deleteData, redraw and dontTranslate... all do pretty much exactly
		 * what they sound like. This pretty much draws a line from the last point drawn to the current,
		 * If it needs to translate and !dontTranslate, then it will translate the points,
		 * If redraw, then it redraws all the points and axis and labels
		 * if deleteData, well you guessed it! :)
		 */
		public function draw():void {
			//this.alpha = 1;
			var d:Rectangle = theStage.getBounds(displaySprite);
			if (mainfxn.getDimensions().x != nowBounds.x || mainfxn.getDimensions().y != nowBounds.y) {
				scale (new Rectangle(d.width, d.height));
			}
			var lastPoint:Point = null;
			if (deleteDate) {
				removeAbove(0);
				deleteDate = false;
			}
			if (new Date().getTime() - mainfxn.getXTime() > MAX_TIME_DISPLAY) {
				if (new Date().getTime() - mainfxn.getInitializeTime() - mainfxn.getTotalPauseTime() > mainfxn.getTimeExecution() - 500 || dontTranslate) {
					//Don't translate.. either we're saving the data or we are too close to the end for it to be worth it
				} else {
					var t0:Number = getTimer();
					this.runner.saveData();
					trace("Total time: " + (getTimer() - t0));
					translatePoints((mainfxn.timeMoveBack() / MAX_TIME_DISPLAY) * nowBounds.right);	//To the left, to the left
					displaySprite.graphics.clear();
					displaySprite.graphics.lineStyle(1, 0x000000, 1);
					displaySprite.opaqueBackground = 0xFFFFFFFF;

					TimeBackCounter++;
					redraw = true;
					
					mainfxn.addXTime(mainfxn.timeMoveBack());
				}
			}
			if (redraw) {
				lastIndex = 0;
				drawAxis(displaySprite.graphics);
				labelAxis();
				redraw = false;
			}
			
			for (var _ind:int = lastIndex; _ind < points.length; _ind++) {
				var _p:Point = points[_ind];
				if (lastPoint != null) {
					displaySprite.graphics.lineTo(_p.x, _p.y);
				} else {
					displaySprite.graphics.moveTo(_p.x, _p.y);
				}
				lastPoint = _p;
				
			}
			lastIndex = points.length - 1;
		}
		public function getPoints():Array { return points; }
		/**
		 * Returns the minimum or maximum y value in the points array, according to the flag key
		 * @param	key: The key, can be Poly.MAX or Poly.MIN
		 * @return returns the corresponding y-value, either MAX or MIN in the points array
		 */
		public function getMinMax(key:int):int {
			var comp:Function;
			if (key == Poly.MAX) {
				comp = function(val1:int, val2:int):Boolean { return val1 > val2; };				
			} else if (key == Poly.MIN) {
				comp = function(val1:int, val2:int):Boolean { return val1 < val2; };
			}
			if (points.length > 0) {
				var i:int = 0;
				while (points[i].y == 0 ) {
					i++;
				}
				var minMax:int = points[i].y;
			} else {
				return -1;
			}
			for (var _ind:int = 0; _ind < points.length; _ind++) {
				if ((!comp(minMax, points[_ind].y)) && points[_ind].y != 0 ) {
					minMax = points[_ind].y;
				} 
			}
			return minMax;
		}
		/**
		 * Rescales and redraws the displaySprite according to the params
		 * @param	oldBottom: old bottom scale
		 * @param	oldTop: old top scale
		 * @param	newBottom: new bottom scale
		 * @param	newTop: new top scale
		 */
		public function reDraw(oldBottom:int, oldTop:int, newBottom:int, newTop:int ):void {
			displaySprite.graphics.clear();
			redraw = true;
			rescalePoints(oldBottom, oldTop, newBottom, newTop);
			while (displaySprite.numChildren > 0) {
				displaySprite.removeChildAt(0);
			}
			this.drawAxis(displaySprite.graphics);
			this.labelAxis();
			this.dontTranslate = true;
			this.draw();
			this.dontTranslate = false;
		}
		/**
		 * Rescales the points array according to the params
		 * @param	oldB: old bottom scale
		 * @param	oldT: old top scale
		 * @param	newB: new bottom scale
		 * @param	newT: new top scale
		 */
		private function rescalePoints(oldB:int, oldT:int, newB:int, newT:int):void {
			var oldDifference:int = oldT - oldB;
			var ybound:int = nowBounds.bottom;
			for (var i:int; i < points.length; i++) {
				var old:Number = points[i].y;
				var percent:Number = ((ybound - points[i].y) / ybound) * 100;
				var sum_total:Number = ((percent / (100 / (oldT-oldB))) + oldB) / 100;
				var newPercent:Number = ((sum_total*100 - newB) * (100/ (newT - newB)));
				points[i].y = ybound - (int) ((newPercent/100)*ybound);
			}
		}
		/**
		 * This is an event handler for manual rescaling -- when the user clicks out of the y-axis labels, then this is called and
		 * rescales the runner according to the value(s) of the boxes
		 * @param	e
		 */
		private function reScaleWrapper(e:FocusEvent):void {
			var newTop:int = parseInt(topScale.text);
			
			var newBot:int = parseInt(bottomScale.text);
			
			if (newTop <= newBot || newTop < 0 || newTop > 100) {
				newTop = oldScale[0];
			} 
			if (newTop <= newBot || newBot < 0 || newBot > 100) {
				newBot = oldScale[1];
			}
			bottomScale.text = String(newBot);
			topScale.text = String(newTop);
			runner.setScale(newBot,newTop );
			
			while (displaySprite.numChildren > 0) {
				displaySprite.removeChildAt(0);
			}
			reDraw(oldScale[1], oldScale[0], newBot, newTop);
		}
		/**
		 * Translates the points array numPixel pixels backwards
		 * @param	numPixel: Number of pixels to subtract
		 */
		private function translatePoints(numPixel:int):void {
			removeBelow(numPixel);
			for (var i:int; i < points.length; i++) {
				points[i].x -= (numPixel-40);
				
			}
		}
		/**
		 * @return the current display/graph
		 */
		public function getDisplaySprite():Sprite {
			return displaySprite;
		}
		public function toggleTranslate(bool:Boolean):void {
			dontTranslate = bool;
		}
		public function getTimeBackCounter():int {
			return TimeBackCounter;
		}
		public function setTimeBackCounter(time:int):void {
			TimeBackCounter = time;
		}
		private function keyPressed(k:KeyboardEvent):void {
			if (k.keyCode == 13) {
				var newTop:int = parseInt(topScale.text);
			
			var newBot:int = parseInt(bottomScale.text);
			
			if (newTop <= newBot || newTop < 0 || newTop > 100) {
				newTop = oldScale[0];
			} 
			if (newTop <= newBot || newBot < 0 || newBot > 100) {
				newBot = oldScale[1];
			}
			bottomScale.text = String(newBot);
			topScale.text = String(newTop);
			runner.setScale(newBot,newTop );
			
			while (displaySprite.numChildren > 0) {
				displaySprite.removeChildAt(0);
			}
			reDraw(oldScale[1], oldScale[0], newBot, newTop);
			}
		}
	}
}