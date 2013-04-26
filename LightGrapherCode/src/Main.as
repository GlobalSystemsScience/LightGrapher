package  
{
	/**
	 * ...
	 * @author Ben
	 */
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.LoaderInfo;
	import flash.geom.Point;
	import flash.net.URLRequestMethod;
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.ActivityEvent;
	import flash.events.MouseEvent;
	import flash.events.StatusEvent;
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.geom.Rectangle;
	import flash.net.FileReference;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLVariables;
	import flash.text.TextField;
	import flash.media.Camera;
	import flash.media.Video;
	import flash.display.BitmapData;
	import flash.text.TextFieldAutoSize;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import Menu.MenuButton;
	import mx.utils.Base64Encoder;
	import flash.utils.getTimer;
	import mx.utils.ObjectUtil;
	
	import PseudoThread;
	import Runner;
	import Alert;
	import flash.events.Event;
	
	public class Main extends Sprite
	{
		private static var counter:int = 0;
		
		private static var LENIENCY:Number = .95;			//// (1 - LENIENCY) * maxPixValue is the minimum value of the pixel to count
		
		private var hitA:CustomShape;
		private var center:Point;
		private var theStage:Stage;
		private var video:Video;
		private var cam:Camera; 
		private var bytearr:ByteArray;
		public var important_bytearr:Array;
		private var width_vid:int = 640;
		private var height_vid:int = 480;
		private var total:Number = 0;
		private var runner:Runner;
		private var thread:PseudoThread;
		private var bitmap:BitmapData;
		private var graphMapWidth:int = 0;
		private var buttonPressed:Boolean = false;
		private var bytes:ByteArray;
		private var t0:Number;				//keeps track of time user hold down a button
		private var saveUpperScale:int = -1;
		private var saveLowerScale:int = -1;
		private var radius:Number = 20;
		
		//Buttons
		private var scrollViewButton:SimpleButton;
		private var viewAllButton:SimpleButton;
		private var right:SimpleButton;
		private var left:SimpleButton;
		
		
		//For the runner class
		private var initializeTime:Number;
		private var x_0Time:Number;
		private var pauseTime:Number;
		private var totalPauseTime:Number;
		public var collectData:Boolean = false;
		private var TIME_EXECUTION:uint = 10000;
		private var cameraSelector:CameraSelector;
		private var paused:Boolean;
		private var startButton:MenuButton;
		private var TIME_MOVE_BACK:uint = 15000;
		private var graphData:BitmapData = null;
		private var graphMap:Bitmap = new Bitmap();
		private var oldGraphMap:BitmapData;
		private var pixelBoundMap:Array;
		private var numImages:int = 0;
		private var extraWidth:int = 0;
		
		public var camIndex:int = -1;
		
		private var totalTime:Number = 0;
		private var totalIterations:int = 0;
		
		
		public function Main(_camName:String, _theStage:Stage, context:CameraSelector):void {
			camIndex = parseInt(_camName);
			theStage = _theStage;
			cameraSelector = context;
			
			video = new Video(width_vid, height_vid);
			paused = false;
			bitmap = new BitmapData(width_vid, height_vid);

			swapCameras(_camName);
			
			cam.setQuality(0, 50);
			cam.setMode(width_vid, height_vid, 30, false);			
		}

		/**
		 * Pivotel function that sets an array of deemed "important bytes", which are the only ones we follow
		 * for changes throughout the program
		 */
		private function webCamOnOff():void { 				//get array of importat bytes
			bitmap.draw(video);
			//bytearr = bitmap.getPixels(new Rectangle(0, 0, width_vid, height_vid));
			//bytearr.position = 0;
			
			var max:int = 25500;
			var pixel:Number;
			
			var importantBytes:Array = new Array();//bytearr.length);
			var index:int = 0;
			this.total = 0;
			var lower:Number = (max - LENIENCY * 25500);
			var tooLow:Number = .75 * lower;
			/*while (bytearr.bytesAvailable > 0) {
				pixel = bytearr.readByte();
				var thisval:Number = getValueOfPixel(pixel)
				if ( thisval >= lower) {
					importantBytes[index] = bytearr.position-1;
					index++;
					this.total += 25500;
				} else if (thisval < tooLow) {		//If its really dark, its unlikely to be next to a bright pixel... skip its neighbors in the name of SPEEEED
					bytearr.position += 5;
				}
			}*/
			var height:int = video.y;
			for (var i:int = 0; i < bitmap.width; i++) {
				for  (var j:int = 0; j < bitmap.height; j++) {
					if (Math.pow((i - 320), 2) + Math.pow((j - 240), 2) < Math.pow(hitA.getSize() * 10, 2)) {
						pixel = bitmap.getPixel(i, j);
						bitmap.setPixel(i, j, 0x000000);
						var thisval:Number = getValueOfPixel(pixel)
						if ( thisval >= lower) {
							importantBytes[index] = new Point(i, j);
							index++;
							this.total += 25500;
						}
					}
				}
			}
			this.important_bytearr = new Array(index);
			for (var k:int = 0; k < index; k++) {
				important_bytearr[k] = importantBytes[k];
			}
			importantBytes = null;
			bytearr = null;
		}
		/**
		 * This function starts the data collection, initializes the runner, etc. 
		 * @param	event
		 */
		public function startDataCollection(event:MouseEvent):void {
			if (this.inProgress() || this.isPaused()) {
				var bounds:Array = runner.getScale();
				saveLowerScale = bounds[1];
				saveUpperScale = bounds[0];
				this.kill(true);
			}
			if (!this.theStage.contains(video)) {
				video = new Video(width_vid, height_vid);
				video.attachCamera(cam);
				theStage.addChildAt(video, 0);
			}
			cameraSelector.captureData();
			if (removeFromStage(graphMap)) { graphMap = new Bitmap();}
			
			oldGraphMap = null;
			graphData = null;
			if (right != null) {			//They all get instantiated and garbage collected together
				removeFromStage(right);
				removeFromStage(left);
				removeFromStage(scrollViewButton);
				removeFromStage(viewAllButton);
			}
			//Make sure we are starting data collection
			if (this.isPaused()) {
				this.kill(true);
			}
			
			hitA = cameraSelector.getHitArea();
			center = cameraSelector.getCenter();
			
			webCamOnOff();
			collectData = true;
			paused = false;
			theStage.removeChild(video);
			
			initializeTime = new Date().getTime();
			x_0Time = initializeTime;
			totalPauseTime = 0;
			
			createThread();
			thread.addEventListener(Event.COMPLETE, handleComplete);
			trace("Starting");
			cameraSelector.onDataChange();
			thread.start();
		}
		/**
		 * Creates the thread
		 */
		private function createThread():void {
			if (thread != null) {
				try {
					thread.destroy();
				} catch (e:Error) {
					//already destroyed
				}
			}
			thread = new PseudoThread(createRunnable(), "Runner", 10);
		}
		/**
		 * Instantiates the runnable object.. it also sets the scale of the runnable object
		 * to previous data if a runnable had already been created and destroyed (i.e. there was 
		 * already at least one trial)
		 * @return the runnable object
		 */
		private function createRunnable():IRunnable {
			var scale:Array = null;
			if (this.saveLowerScale != -1 && this.saveUpperScale != -1) {
				scale = new Array();
				scale[0] = saveUpperScale;
				scale[1] = saveLowerScale;
			}
			runner = new Runner(this, theStage, bytearr,null,true,scale);
			return runner;
		}
		
		private function handleComplete(event:ActivityEvent):void {
			//what to do on completion.. i.e. nothing (we handle that elsewhere -- the thread never reeeally stops)
		}	
		public function getTotal():uint {
			return this.total;
		}
		/**
		 * Kills every aspect of the display and running process
		 * @param	removeGraph: Flag whether or not to remove the runner's poly's displaysprite -- traditionally we left it up when over, but the flag is relatively useless now
		 */
		public function kill(removeGraph:Boolean):void {
			if (thread != null) {
				try {
					thread.destroy();
				} catch (e:Error) {
					trace(e);
				}
			}
			if (removeFromStage(graphMap)) { graphMap = new Bitmap(); }
			
			oldGraphMap = null;
			graphData = null;
			graphMapWidth = 0;
			
			if (scrollViewButton != null) {			//They all get instantiated and garbage collected together
				removeFromStage(scrollViewButton);
			}
			if (right != null) {
				removeFromStage(right);
				removeFromStage(left);
				removeFromStage(viewAllButton);
			}
			
			bytearr = null;
			important_bytearr = null;

			total = 0;
			if (removeGraph) {
				try {
					runner.destroy();
				} catch (e:Error) {
					trace(e);
				}
				runner = null;
				thread = null;
			}
			
			//For the runner class
			initializeTime = 0;
			x_0Time = 0;
			totalPauseTime = 0;
			collectData = false;
			paused = false;
		}
		/**
		 * Getters and setters...
		 *
		 */
		public function inProgress():Boolean {
			return collectData;
		}
		public function getVideo():Video {
			return video;
		}
		public function getInitializeTime():Number {
			return initializeTime;
		}
		public function getXTime():Number {
			return x_0Time;
		}
		public function getTotalPauseTime():Number {
			return totalPauseTime;
		}
		public function getCollectData():Boolean {
			return collectData;
		}
		public function getImportantBytesArray():Array {
			return important_bytearr;
		}
		public function getByteArray():ByteArray {
			return bytearr;
		}
		public function getDimensions():Rectangle {
			return new Rectangle(width_vid, height_vid);
		}
		public function getTimeExecution():int { return TIME_EXECUTION; }
		
		public function setTimeExecution(time:Number):void { TIME_EXECUTION = time * 1000; }
		
		/**
		 * Essential function right here -- it takes a byte and outputss a value used to judge how bright that pixel is
		 * @param	pixel: The pixel from the byteArray
		 * @return The value of that pixel
		 */
		public static function getValueOfPixel(pixel:int):Number {
			trace("getting value");
			var red:int = pixel >> 16 & 0xFF;
			var green:int = pixel >> 8 & 0xFF;
			var blue:int = pixel & 0xFF;
			//return red * 30 + green * 59 + blue * 11; //adjusted to what the human eye sees as luminosity
			return red * 33 + green * 34 + blue * 33; //each color contributing equally
		}
		/**
		 * Handles everything about pausing the application -- unpauses if paused and pauses if unpaused
		 * It also takes care of the threading and UI element 
		 */
		public function onPause(e:MouseEvent = null):void {
			if (!this.isPaused()) {
				collectData = false;
				paused = true;
				pauseTime = new Date().getTime();
				cameraSelector.onDataChange();
			} else {
				paused = false;
				collectData = true;
				x_0Time += new Date().getTime() - pauseTime;
				totalPauseTime += new Date().getTime() - pauseTime;
				pauseTime = 0;
				cameraSelector.onDataChange();
			}
		}
		/**
		 * Stops all data collection, stops the graphher, and goes back to the video/aim camera display
		 * @param	e: MouseEvent
		 */
		public function stop(e:MouseEvent = null):void {
			if (runner != null) {
				var bounds:Array = runner.getScale();
				saveLowerScale = bounds[1];
				saveUpperScale = bounds[0];
			}
			if (this.inProgress() || this.isPaused || theStage.contains(graphMap)){		//If its running, paused or displaying results -- otherwise, what are we stopping?
				this.kill(true);
			}
			cameraSelector.onDataChange();
			if (this.camIndex != -1) {
				swapCameras(String(camIndex));					//default camera
			} else {
				swapCameras(String(0));
			}
		}
		public function isPaused():Boolean {
			return paused;
		}
		
		public function detachCamera():void {
			if (video != null) {
				theStage.removeChild(video);
				video = null;
			}
		}
		/**
		 * Swaps the existing camera out for a new one. If there is no existing camera,
		 * it will just add a new one to the stage
		 * @param	_camName: The index of the camera in the Camera.getCamera() deal
		 */
		public function swapCameras(_camName:String):void {
			if (theStage.contains(video)) {
				theStage.removeChild(video);
			}
			this.camIndex = Number(_camName);
			if (this.inProgress() || this.isPaused()) {
				Alert.init(theStage);
				if (!this.isPaused()) {
					this.onPause();
				}
				Alert.show("Switch to different Webcam?", { buttons:["Yes", "No"], callback:alertEventHandler, background:"blur" } );
				return;
			}
			var cameras:Array = new Array();
			var videos:Array = new Array();
			for (var k:int = 0; k < parseInt(_camName); k++) {
				cameras[k] = Camera.getCamera(String(k));
				videos[k] = new Video(0, 0);
				videos[k].attachCamera(cameras[k]);
			}
			cam = Camera.getCamera(_camName);
			
			video.y = 60;
			video.attachCamera(cam);
			video.name = "videoCamera";
			if (!theStage.contains(video)) {
				theStage.addChildAt(video, 0);
			}
		}
		/**
		 * Deprecated.. we don't do this anymore -- you can't change cameras mid-session
		 * @param	response
		 */
		public function alertEventHandler(response:String):void {
			if (response == "Yes") {
				this.kill(true);
				swapCameras(String(camIndex));
				cameraSelector.onDataChange();
			} else {
				if (this.isPaused()) {
					this.onPause();	
				}
				//
			}
		}
		
		/**
		 * Called by auto-scale button -- pretty much just autoscales the runner/poly
		 * @param	e
		 */
		public function adjustScale(e:MouseEvent):void {
			if (!inProgress() && !isPaused()) {
				//Nothing... there's no scale to adjust
			} else {
				var oldBounds:Array = runner.getScale();
				var newBounds:Array = runner.changeScale();
				runner.setScale(newBounds[1], newBounds[0]);
				runner.adjustScale(oldBounds[1], oldBounds[0], newBounds[1], newBounds[0]);
			}
		}
		public function getRunner():Runner {
			return runner;
		}
		/**
		 * A bunch of things to handle a completed trial, including displaying results
		 * and cleaning up some threading issues, saving some information, and UI update
		 */
		public function onTrialComplete():void {
			//addToSprite(runner.getScaledSprite());
			//var bounds:Array = runner.getScale();
			//this.saveLowerScale = bounds[1];
			//this.saveUpperScale = bounds[0];
			//this.kill(true);
			
			//viewAll();
			cameraSelector.onTrialComplete();
			
		}
		/**
		 * A single view associated with a completed trial -- the scrollView allows users to scroll through a detailed
		 * look of their trial. This and viewAll() are kind of a mess
		 * @param	e
		 */
		private function scrollView(e:MouseEvent = null):void {
			removeFromStage(scrollViewButton);
			graphMap.width = graphMapWidth;
			graphMap.scrollRect = new Rectangle(0, 0, 642, 480);
			right = Alert.createButton("Right", new AlertOptions(null, "Right"), 60, -1);
			left = Alert.createButton("Left", new AlertOptions(null, "Left"), 60, -1);
			right.height = 20;
			left.height = 20;
			right.x = 580;
			right.y = video.height / 2;
			left.x = 0;
			left.y = video.height / 2;
			
			right.addEventListener(MouseEvent.MOUSE_DOWN, moveRightFast);
			left.addEventListener(MouseEvent.MOUSE_DOWN, moveLeftFast);
			right.addEventListener(MouseEvent.CLICK, moveRight);
			left.addEventListener(MouseEvent.CLICK, moveLeft);
			right.addEventListener(MouseEvent.MOUSE_UP, function(e:Event):void { 
				buttonPressed = false; } );
				
			left.addEventListener(MouseEvent.MOUSE_UP, function(e:Event):void { 
				buttonPressed = false; } );

			viewAllButton = Alert.createButton("View All", new AlertOptions(null, "View All"), 80, -1);
			viewAllButton.x = 380;
			viewAllButton.y = 580;
			viewAllButton.addEventListener(MouseEvent.CLICK, this.viewAll);
			
			theStage.addChild(viewAllButton);
			theStage.addChild(right);
			theStage.addChild(left);
		}
		/**
		 * A single view associated with a completed trial -- the viewAll allows users to see their entire trial in one view. 
		 * This and scrollView() are kind of a mess
		 * @param	e
		 */
		private function viewAll(e:MouseEvent = null):void {
			if (right != null) {
				removeFromStage(right);
				removeFromStage(left);
				removeFromStage(viewAllButton);
			}
			removeFromStage(graphMap);
			
			if (graphMap == null) { graphMap = new Bitmap(oldGraphMap); }
			graphMap.scrollRect = null;
			graphMap.x = 0;
			graphMap.y = 60;
			if (graphMapWidth == 0) {
				graphMapWidth = graphMap.width;
			}
			
			graphMap.scaleX = (700  / graphMapWidth);
			
			scrollViewButton = Alert.createButton("Expanded View", new AlertOptions(null, "Expanded View"), 80, -1);
			scrollViewButton.x = 380;
			scrollViewButton.y = 580;
			scrollViewButton.addEventListener(MouseEvent.CLICK, this.scrollView);
			
			theStage.addChild(graphMap);
			theStage.addChild(scrollViewButton);
			cameraSelector.refreshCopyright();
		}
		/**
		 * Removes the argument from stage if they are on it
		 * @param	frank: DisplayObject to remove
		 * @return true upon successful removal, false if the stage doesn't contain the displayObject
		 */
		private function removeFromStage(frank:DisplayObject):Boolean {
			if (theStage.contains(frank)) {
				theStage.removeChild(frank);
				return true;
			} else {
				return false;
			}
		}
		/**
		 * OnClick listener for scrollView right button
		 * @param	e
		 */
		private function moveRight(e:MouseEvent):void {
			var rect:Rectangle = graphMap.scrollRect;
			if (rect.x + 20 >= graphMapWidth-720) {
				//don't move
			} else {
				rect.x += 20;
			}
			graphMap.scrollRect = rect;
		}
		/**
		 * OnClick listener for scrollView left button
		 * @param	e
		 */
		private function moveLeft(e:MouseEvent):void {
			var rect:Rectangle = graphMap.scrollRect;
			if (rect.x - 20 <= 0) {
				//don't move
			} else {
				rect.x -= 20;
			}
			graphMap.scrollRect = rect;
		}
		/**
		 * OnClickAndHold listener for scrollView right button
		 * @param	e
		 */
		private function moveRightFast(e:MouseEvent):void {
			buttonPressed = true;
			t0 = getTimer();
			callback();
			var timer:Timer = new Timer(125);
			timer.addEventListener(TimerEvent.TIMER, callback);
			timer.start();
			
			function callback():void {
				if (buttonPressed == false) {
					timer.stop(); 
					timer.removeEventListener(TimerEvent.TIMER, callback);  
					return; 
				} else {
					var t1:Number = getTimer();
					var rect:Rectangle = graphMap.scrollRect;
					var moveAmount:int = Math.floor(Math.log(Math.pow((t1 - t0), 5)));
					t0 -= moveAmount;
					if (rect.x + moveAmount >= graphMapWidth-720) {
						//don't move
						
						//rect.x = graphMapWidth - 720;
					} else {
						rect.x += moveAmount;
					}
					graphMap.scrollRect = rect;
				}
				
			}
		}
		/**
		 * OnClickAndHold listener for scrollView left button
		 * @param	e
		 */
		private function moveLeftFast(e:Event):void {
			buttonPressed = true;
			t0 = getTimer();
			callback();
			var timer:Timer = new Timer(125);
			timer.addEventListener(TimerEvent.TIMER, callback);
			timer.start();
			function callback():void {
				if (!buttonPressed) { 
					timer.stop(); 
					timer.removeEventListener(TimerEvent.TIMER, callback); 
					return; 
				} else {
					var t1:Number = getTimer();
					var moveAmount:int = Math.floor(Math.log(Math.pow((t1 - t0), 5)));
					t0 -= moveAmount;	
					var rect:Rectangle = graphMap.scrollRect;
					if (rect.x - moveAmount <= 0) {
						//don't move
						rect.x = 0;
					} else {
						rect.x -= moveAmount;
					}
					graphMap.scrollRect = rect;
				}
			}
		}
		public function timeMoveBack():uint {
			return TIME_MOVE_BACK;
		}
		public function addXTime(add:int):void {
			x_0Time += add;
		}
		/**
		 * Saves the graph. This gets called from the button in CameraSelector -- the idea is that it appends the current display to the existing saved data
		 * and then saves it all as a png
		 * @param	e
		 */
		public function save(e:MouseEvent):void {
			if (this.inProgress()) { this.onPause(); }
			var tempData:BitmapData;
			if (runner != null) {
				
				var poly:Sprite = runner.getScaledSprite();
				runner.revertScale();
				tempData = this.addToSprite(poly, false)
			} else {
				tempData = graphMap.bitmapData;
			}
			var file:FileReference = new FileReference();
			//file.addEventListener(Event.SELECT, addPNG);
			bytes = PNGEncoder.encode(tempData);
			file.save(bytes, "graph.png");
			graphData = null;
		}
		
		/*private function addPNG(e:Event):void {
			var file:FileReference = (e.target as FileReference);
			var name:String = file.name;
			var loader:URLLoader = new URLLoader();
			var header:URLRequestHeader = new URLRequestHeader("Content-type", "application/octet-stream");
			var request:URLRequest = new URLRequest("upload_handler.php");
			var encoder:Base64Encoder = new Base64Encoder();
			
			request.requestHeaders.push(header);
			request.data = bytes;
			request.method = URLRequestMethod.POST;	
			request.contentType = "application/octet-stream";
			//request.requestHeaders.push( new URLRequestHeader( 'Cache-Control', 'no-cache' ) );
			loader.dataFormat = URLLoaderDataFormat.BINARY;
			loader.load(request);
			trace(name);
			//file.cancel();
			trace("YEEEE I'm DOING IT");
			//file.upload(new URLRequest("upload_handler.php?name=" + name), name);
				
		}*/
		
		/**
		 * This function is the cause of and answer to all life's problems.
		 * 
		 * Sorry its horrible, but hopefully you won't have to change it. A lot of the numbers are arbitrarily chosen because 
		 * they provide good results (i.e. the images don't overlap).
		 * 
		 * This function takes a sprite and some unnecessary arguments and appends the sprite to an exiting BitMapData object in the main function.
		 * It does that by adding the bytes by row to the existing object, but only for a certain range of bytes
		 * 
		 * Some of the arguments are now unnecessary. Initially, it was supposed to keep track of byte ranges to delete upon overwriting the old data
		 * but now they are deprecated in favor of pixel bounds
		 * 
		 * @param	add: The sprite to keep
		 * @param	keep
		 * @param	lowerTime
		 * @param	upperTime
		 * @return
		 */
		public function addToSprite(add:Sprite, keep:Boolean = true, lowerTime:int = 0, upperTime:int = 0):BitmapData {
			if (oldGraphMap != null) {
				trace("OGM: " + oldGraphMap.width);
			}
			trace("Saving: " + add.width); 
			var returnData:BitmapData;			//The BitmapData object to return
			var tempData:BitmapData;			//Used as a container for adding the Sprite and old data to
			
			var oldWidth:int;			
			var firstSave:Boolean = true;
			var subtract:int;
			/**
			 * Arbitrary... this is where we start on the add sprite though -- its almost exactly at the time value corresponding 
			 * to half (i.e. when it displays 0 -> 30 seconds, 340px corresponds to 15 seconds). Therefore, starting at 340px only appends
			 * new content to the existing data (because we add it in 15 second intervals)
			 */
			var halfwayPoint:int = 340;	
			
			/**
			 * There are two ways addToSprite is called -- either we are mid-trial and want to save all out progress so far, or we are translating points
			 * back and want a way to remember the data that we already collected. If it is the former, we aren't actually storing the progress in the main
			 * class because we will do that when we translate the points, so we only 'keep' data when translating backwards and create a local, temporary 
			 * bitmapdata object to write to file if we aren't keeping it
			 */
			if (!keep) {						//If we aren't keeping the data... user clicked save
				if (oldGraphMap != null) { 		//There is existing data to append the sprite to
					firstSave = false; 
					returnData = oldGraphMap.clone(); 	//We can't write to oldGraphMap without storing it, so we use returnData
					
					//subtract = (returnData.width - runner.XBOUND);			//Amount of whitespace to subtract
					
					var littleExtra:int = 0;
					if (numImages >= 1) {
						littleExtra = 80;
					} else {
						trace ("NUMIMAGES: " + numImages)
					}
					trace("New width: " + (oldGraphMap.width + add.width - halfwayPoint- littleExtra));
					tempData = new BitmapData(returnData.width + add.width - halfwayPoint - littleExtra, Math.max(returnData.height, add.height)); //282 + (3 * (numImages-2)), Math.max(returnData.height, add.height));
					oldWidth = returnData.width - extraWidth-1;//-8;				//The width of the oldGraphMap -- this is where we start inserting pixels when adding the aprite
					tempData.draw(returnData);
				} else { 
					trace("DIMENSION: " + add.width + " " + add.height);
					tempData = new BitmapData(add.width, add.height);
					if (extraWidth == 0) {
						extraWidth = add.width - runner.XBOUND-1;				//extraWidth gets set when you add the first sprite.. its supposed to represent
																			//the whitespace that we have to overwrite when adding a new sprite (or something like that)
					}
				}
				//set returnData to tempData -- the new, bigger BitmapData
				returnData = tempData;
			} else {
				if (oldGraphMap != null) {
					//This is essentially the same except using oldGraphMap directory rather than returnData -- because we are keeping the graph, the returnData is oldGraphMap
					//subtract = (oldGraphMap.width - runner.XBOUND);	
					
					var littleExtra:int = 0;
					if (numImages >= 1) {
						littleExtra = 80;
					} else {
						trace ("NUMIMAGES: " + numImages)
					}	
					trace("New width: " + (oldGraphMap.width + add.width - halfwayPoint-littleExtra));
					tempData = new BitmapData(oldGraphMap.width + add.width - halfwayPoint-littleExtra, Math.max(oldGraphMap.height, add.height))//282 + (4 * (numImages-2)), Math.max(oldGraphMap.height, add.height));
					firstSave = false; 
					tempData.draw(oldGraphMap);
					oldWidth = oldGraphMap.width - extraWidth-1;// - 8;

				} else {
					if (extraWidth == 0) {
						extraWidth = add.width - runner.XBOUND-1;
					} 
					tempData = new BitmapData(add.width, add.height);
					oldWidth = 0;
				}
				
				//set oldGraphMap to tempData -- the new, bigger BitmapData
				oldGraphMap = null;
				oldGraphMap = tempData;
			
			}
			var bmd:BitmapData = new BitmapData(add.width, add.height);
			bmd.draw(add);
			var bm:Bitmap = new Bitmap(bmd);
				
																		
			if (firstSave) { halfwayPoint = 0; }		//If there is no data, then we need the whole thing -- including the axis, scales, etc.
			
			var t0:Number = getTimer();;
			var t1:Number;
			if (keep) {
				oldGraphMap = addByRow(oldGraphMap, bm.bitmapData, oldWidth, halfwayPoint);
				graphMap = new Bitmap(oldGraphMap);
				numImages++;
				trace("NUMIMAGES++");
				trace(getTimer() - t0);
				return oldGraphMap;
			} else {	
				returnData = addByRow(returnData, bm.bitmapData, oldWidth, halfwayPoint);
				trace(getTimer() - t0);
				return returnData;
			}
		}
		/**
		 * Kind of a cool function, it adds byte2 onto byte1, starting @param oldwidth on byte1 and appending from bytes @param whereToStart on @param byte2 and going to @param byte2.width
		 * @param	byte1: container BitmapData -- such that byte1.width = byte2.width + oldwidth
		 * @param	byte2: BitmapData to append to byte1
		 * @param	oldwidth: The pixel location to begin overwriting pixels on byte1
		 * @param	whereToStart: The pixel location to begin taking values from byte2
		 * @return A combined BitmapData object
		 */
		private function addByRow(byte1:BitmapData, byte2:BitmapData, oldwidth:int, whereToStart:int):BitmapData {
			var littleExtra:int = 0;
			if (numImages > 1) {
			//	littleExtra = 80;
			} else {
				trace ("NUMIMAGES: " + numImages)
			}
			//var temp:ByteArray = byte2.getPixels(new Rectangle(whereToStart, 0, byte1.width - oldwidth, byte1.height));
			var temp:ByteArray = byte2.getPixels(new Rectangle(whereToStart, 0, byte2.width - whereToStart-80-littleExtra, byte1.height));
			temp.position = 0;
			
			trace("Copying width: " + (byte2.width - whereToStart-80-littleExtra));
			byte1.setPixels(new Rectangle(oldwidth, 0, byte2.width - whereToStart-80-littleExtra, byte1.height), temp);
			
			/*for (var i:int = oldwidth; i < byte1.width - 77; i ++) {
				for (var k:int = 0; k < byte1.height; k++) {
						byte1.setPixel(i, k, byte2.getPixel(whereToStart, k));
				}
				whereToStart++;
			}
			*/
			return byte1;
			
		}
		/**
		 * If the user declines the use of the Camera, this error screen comes up and asks the user to refresh the page
		 * and then confirm use of webcam
		 * @param	e
		 */
		private function tryAgain(e:StatusEvent):void {
			if (e.code == "Camera.Muted") {
				cameraSelector.removeAll();
				var text:TextField = new TextField();
				text.multiline = true;
				text.text = "You need to have a webcam to use this app. If you have one, please"
				var btn:SimpleButton = Alert.createButton("Try Again", new AlertOptions(null, "Try Again"), 80, -1);
				text.x = 300;
				text.y = 300;
				text.width = 200;
				text.height = 200;
				text.autoSize = TextFieldAutoSize.CENTER;
				
				btn.x = 350;
				btn.y = 350;
				
				theStage.addChild(text);
				theStage.addChild(btn);
				
				btn.addEventListener(MouseEvent.CLICK, refresh);
			} 
		}
		/**
		 * Helper function/onclicklistener to refresh the page
		 * @param	e
		 */
		private function refresh(e:MouseEvent):void {
			if (ExternalInterface.available) {
				ExternalInterface.call("function startover() {document.location.reload()}" );
			}
		}
		/**
		 * I think this is still used -- its a wrapper for cameraSelector to use in order to rescale the runner to newB and newT
		 * @param	newB: The new bottom Scale
		 * @param	newT: The new top Scale
		 */
		public function reScale(newB:int, newT:int):void {
			var oldBounds:Array = runner.getScale();
			runner.setScale(newB, newT);
			runner.adjustScale(oldBounds[1], oldBounds[0], newB, newT);
		}
		/**
		 * Gets the current scale in the runner, if it is in progress or paused
		 * @return
		 */
		public function getScale():Array {
			if (inProgress() || isPaused()) {
				return runner.getScale();
			} else {
				return null;
			}
		}
	}
}