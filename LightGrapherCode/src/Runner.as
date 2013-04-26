package  
{
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.media.Video;
	import flash.system.System;
	import flash.utils.ByteArray;
	import flash.utils.SetIntervalTimer;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	/**
	 * ...
	 * @author Ben
	 */
	public class Runner implements IRunnable 
	{
		private static var BYTES_TO_SKIP:int = 1;
		public const XBOUND:int = 640;
		public const YBOUND:int = 480;
		private var bottomScale:int = 0;
		private var topScale:int = 100;
		
		public var sum:Number;
		private var pt:Point = new Point();
		private var xbound:int = 640;		//Magic numbers -- will be changed later
		private var ybound:int = 480;		//later
		private var mainInstance:Main;
		private var byteArray:ByteArray;
		private var impByteArray:Array;
		private var total:Number;
		public var time:Number;
		private var poly:Poly;
		private var theStage:Stage;
		private var vidCopy:Video; 
		private var lastValue:Number;
		private var lastFewTrials:Array;
		private var lastFewTrialsIndex:int;
		private var bitmap:BitmapData; //= new BitmapData(vidCopy.width, vidCopy.height);
		private var high:Number = 0;
		private var low:Number = 100;
		private var retrieveSavedScale:Boolean = true;
		private var oldBottomScale:int = -1;
		private var oldTopScale:int = -1;
		//For saving data
		private var savedBottomScale:int = -1;
		private var savedTopScale:int = -1;
		private var newBounds:Array;
		//For debugging
		private var totalTime:Number = 0;
		private var totalIterations:int = 0;
		
		private var t0:Number;
		private var t1:Number;
		
		public function Runner(main:Main, _stage:Stage, bytearr:ByteArray, points:Array = null, onStage:Boolean = true, scale:Array = null) {
			
			/* Initiation variables to be set */
			mainInstance = main;
			theStage = _stage;
			vidCopy = mainInstance.getVideo();
			if (scale != null) {
				this.topScale = scale[0];
				this.bottomScale = scale[1];
			}
			poly = new Poly(_stage, mainInstance.getDimensions(),mainInstance, null, points, this, onStage);
			impByteArray = mainInstance.important_bytearr;
			byteArray = bytearr;
			bitmap = new BitmapData(vidCopy.width, vidCopy.height);
			total = (impByteArray.length * 25500) / BYTES_TO_SKIP;
			trace(total);
		}
		/**
		 * This function gets called by PseudoThread repeatedly... it collects the data, plots the point, and then redraws poly -- basically the entire application
		 * from a functionality standpoint
		 */
		public function process():void {

			if (!mainInstance.collectData) {		//Must be paused
				return;
			}
			time = new Date().getTime();
			if (time - mainInstance.getTotalPauseTime() - mainInstance.getInitializeTime() > mainInstance.getTimeExecution()) {		//Exceeded run time (set by user)
				mainInstance.onTrialComplete();
				return;
			}
			pt = new Point();
			if (total == 0) {															//Something went terribly wrong -- user should restart the program
				return;
			}
			pt.x = 40 + (time-mainInstance.getXTime()) / (poly.MAX_TIME_DISPLAY) * (xbound-40);
			var temp:Number = getSum();
			var percentLight:Number = temp / total;
			var percent:Number = (((percentLight)*100 - bottomScale) * (100/ (topScale - bottomScale)));
			pt.y = ybound - (int) ((percent / 100) * ybound);													//y-coord is based off a percentage of light getting through and then scaled to the axis
			
			poly.addUnscaledPoint(pt);
			poly.draw();
						t1 = getTimer();
			if (t0 != 0) {
				//trace (t1 - t0);
			}
			t0 = getTimer();
		}
		/**
		 * Gets the sum of important pixels set on the start in order to graph the brightness of the bulb
		 * @return the sum of the brightness of the important pixels
		 */
		private function getSum():Number {
			sum = 0;
			bitmap.draw(vidCopy);
			var total:int = 0;
			//byteArray = bitmap.getPixels(new Rectangle(0, 0, vidCopy.width, vidCopy.height));
		
			
			/*for (var i:int; i < impByteArray.length; i += BYTES_TO_SKIP) {
				var pixel:Number;
				try {
					byteArray.position = impByteArray[i];
					pixel = byteArray.readByte();
				}
					catch (e:Error) {
					trace(e);
					sum += 25500;
					continue;
				}
					var thisval:int = Main.getValueOfPixel(pixel);			//Use the standard Main function to provide consistency in measurement
					sum += thisval;
			} */
			for (var i:int; i < impByteArray.length; i += BYTES_TO_SKIP) {
				var pixel:Number = bitmap.getPixel(impByteArray[i].x, impByteArray[i].y);
				var thisval:int = Main.getValueOfPixel(pixel);			//Use the standard Main function to provide consistency in measurement
				sum += thisval;
				total += 25500;
			}
			return sum;
		}
		/**
		 * Wrapper to Poly.kill() for main function
		 */
		public function destroy():void {
			poly.kill();
		}
		/**
		 * Function analyzes the current data and approximates an appropriate scale for use throughout the experiment
		 * @return an Array: in position [0] is the suggested max value and in [1] is the suggested min value
		 */
		public function changeScale():Array {
			var percent:Number;
			var newT:Number, newB:Number;
			var minY:Number = this.poly.getMinMax(Poly.MIN);	//get minimum y-value (highest on graph)
			var maxY:Number = this.poly.getMinMax(Poly.MAX);	//get maximum y-value (lowest on graph)
			var oldB:Number = bottomScale, oldT:Number = topScale;
			
			var tempPercent:Number = ((ybound - minY) / ybound) * 100;
			percent = ((tempPercent / (100 / (oldT-oldB))) + oldB) / 100;
			newT = Math.round(percent * 10) * 10 +10;
			
			tempPercent = ((ybound - maxY) / ybound) * 100;
			var temp:Number = 100 / (oldT - oldB);

			var result:Number = tempPercent / temp;

			percent = (result + oldB) / 100;

			newB = Math.round(percent * 10) * 10 - 5;
			
			return [newT, newB];
		}
		/**
		 * 
		 * @return The current scale, with pos[0] = top, and pos[1] = bottom
		 */
		public function getScale():Array {
			return new Array(topScale, bottomScale);
		}
		/**
		 * Sets the current scale
		 * @param	lower: new lower scale value
		 * @param	upper: new upper scale value
		 */
		public function setScale(lower:int, upper:int):void {
			topScale = upper;
			bottomScale = lower;
		}
		/**
		 * 
		 * @return the current grapher display (exactly how it is on screen)
		 */
		public function getDisplay():Sprite { return poly.getDisplaySprite(); }
		/**
		 * Weird function that simply saves a scaled version of the current display. It saves it using the main function's 
		 * graphdata and such, not to file
		 */
		public function saveData():void {
	
			var temp:Sprite = getScaledSprite();
			
			mainInstance.addToSprite(temp, true, mainInstance.getXTime() - mainInstance.getInitializeTime(), mainInstance.getXTime() - mainInstance.getInitializeTime() + mainInstance.getTimeExecution());
			
			this.revertScale();				//Messing with saving sometimes scales the current runner, so as a precaution we revert the scale back to how it was and everything works peachy

		}
		/**
		 * A lot of the meat of saving the data is in formatting it correctly -- making sure the scales are consistent and that none of it messes with the UI
		 * This function takes care of all that by making a new runner, new poly and scaling that consistently across saves. This method is the key to getting the sprite that
		 * we actually want to save
		 * @return the sprite (usually to add to the bitmap of data we collected)
		 */
		public function getScaledSprite():Sprite {
			var pts:Array = new Array(), pts2:Array = this.poly.getPoints();
			for (var i:int = 0; i < pts2.length; i++) {
				pts[i] = pts2[i];
			}
			
			var tempRunner:Runner = new Runner(mainInstance, theStage, new ByteArray(), pts, false);
			tempRunner.poly.toggleTranslate(true);						//We shouldn't be translating, or else we're going to go into an infinite loop (it'll try to save the data on translation)
			if (savedBottomScale == -1 && savedTopScale == -1) {		//This is the first time we've saved something, so we need to come up with bounds to use
				newBounds = this.changeScale();
				savedBottomScale = newBounds[1];
				savedTopScale = newBounds[0];
			}
			tempRunner.setScale(savedBottomScale, savedTopScale);								//Get y-axis scaling right
			tempRunner.poly.setTimeBackCounter(this.poly.getTimeBackCounter());					//to get x-axis scaling right
			tempRunner.poly.reDraw(bottomScale, topScale, savedBottomScale, savedTopScale);		//Rescale
			tempRunner.poly.toggleTranslate(false);												
			return tempRunner.getDisplay();
		}
		/**
		 * Only used by runner.saveData() -- pretty much it fixes exactly what getScaledSprite breaks. I couldn't find a better way to implement it other than rescaling the
		 * existing data.. its also an unnecessary function, and could be done sing adjustScale(...);
		 */
		public function revertScale():void {
			this.poly.toggleTranslate(true);
			this.poly.reDraw(newBounds[1], newBounds[0], bottomScale, topScale);
			this.poly.toggleTranslate(false);
		}
		/**
		 * Wrapper to poly.reDraw(..) -- its used as a generic rescaling tool
		 * @param	oldB: old Bottom scale
		 * @param	oldT: old Top Scale
		 * @param	newB: new Bottom Scale 
		 * @param	newT: new Top Scale
		 */
		public function adjustScale(oldB:int, oldT:int, newB:int, newT:int):void {
			this.poly.reDraw(oldB, oldT, newB, newT);
		}
	}
	

}