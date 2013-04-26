package  
{
	import fl.controls.Slider;
	import fl.events.SliderEvent;
	import flash.display.DisplayObject;
	import flash.display.SimpleButton;
	import mx.controls.scrollClasses.ScrollBar;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.filters.BitmapFilter;
	import flash.geom.Point;
	import flash.system.System;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.ui.Mouse;
	import Menu.MenuButton;
	import flash.media.Camera;
	import Main;
	import HitArea;
	import flash.text.TextField;
	/**
	 * ...
	 * @author Ben
	 * 
	 * This program captures data from a webcam and graphs the light in real time
	 * 
	 * The components are broken up across several major classes:
	 * CameraSelector is the entry-point, and a little misnamed -- it really generates all of the UI
	 * for the program, with the exception of graph, so it takes care of buttons, as well as selecting the camera
	 * 
	 * Main is almost a gateway for a spectrum of activity -- its responsible for attaching the camera, and communicating 
	 * information between the UI and the active process (between CameraSelector and Runner/Poly). It also does most of the overhead
	 * in managing the running process, including stopping, starting, pausing, as well as collecting data about the set up to collect data
	 * 
	 * Runner is the pseudothread process that runs to collect data. It not only communicates with the webcam, but with Poly, the graphing function
	 * to product a display. This also works with formatting the saved images and scaling
	 * 
	 * Poly is a wrapper to a sprite that displays the meat of the application, rightfully named "displaySprite" -- it has wrappers to all the essential UI and 
	 * data of the displayed graph and graphing
	 * 
	 * Alert is commonly used to generate alert dialogs and buttons -- credit is 
	 * 
	 * Right now, deprecated classes include Preference, PreferenceChangeEcent, PreferenceItem, PreferenceWrapper, and UploadPostHelper
	 * 
	 * For the most part, the implementation of Alert, AlertOptions, IRunnable, PNGEncoder, and PseudoThread do not affect the core functionality
	 * of the program -- most of the logic is contained in the explained classes
	 */
	[SWF(backgroundColor="0x63EDFF")]
	public class CameraSelector extends Sprite
	{
		private var buttonList:Vector.<MenuButton> = new Vector.<MenuButton>();	//List of all the menu options 
		private var indexRange:Array = new Array(30);					//keep track of indecies to keep visible on hover -- very tricky stuff
		
		private var camNames:Array;
		private var mainfxn:Main;
		private var camIndex:int = -1;
		private var hitA:HitArea;
		private var center:Point = new Point();
		
		private var resumeButton:SimpleButton;
		private var collectDataButton:SimpleButton;
		private var aimCameraButton:SimpleButton;
		private var pauseButton:SimpleButton;
		private var saveButton:SimpleButton;
		private var autoScaleButton:SimpleButton;
		private var aboutButton:SimpleButton;
		private var helpButton:SimpleButton;
		private var copyRight:TextField = new TextField();
		private var slideStartVal:int = 20;
		
		private var aimInstr:TextField = new TextField();
		
		private var slideSelect:Slider;
		private var slideDescript:TextField;
		//inputText is a sprite contained several TextFields that encompass the "Capture Data for xx seconds" Dialog
		private var inputText:Sprite = new Sprite();
		
		//Special index for the Resume button under Edit.. it shouldn't have to be special but I messed up
		private var resumeIndex:int = -1;
	
		/**
		 * Capture Data labels on top right
		 */
		private var runTime:TextField = new TextField();
		private var label:TextField = new TextField();
		private var smallLabel:TextField = new TextField();
		
		public function CameraSelector() { 
			camNames = Camera.names;
			Alert.init(stage);
			inputText.x = 372;	//Complete arbitrary UI choice to make
			
			Alert.show("Choose a camera", {buttons:camNames, callback:camera});		//make them choose a camera before letting them continue
		}
		/**
		 * Handler for the choose a camera dialog
		 * @param	response: The camera name that the user selected
		 */
		private function camera(response:String):void {
			var keeper:int;
			trace(response);
			
			for (var i:int = 0; i < camNames.length; i++) {				
				if (response.toLowerCase() == camNames[i].toLowerCase()) {
					keeper = i;
				}
			}
			
			
			mainfxn = new Main(String(keeper), this.stage, this);
			addCopyRight();
			getAllButtons();
			this.addInputText();
			onDataChange();
			trace(15 + mainfxn.getDimensions().right / 2 + " -- " + (45+(mainfxn.getDimensions().bottom/2)+45));
			hitA = new HitArea(HitArea.CIRCLE, 0 + mainfxn.getDimensions().right / 2,  (60 + (mainfxn.getDimensions().bottom / 2)), (slideStartVal * 240)/100);
			center.x = 0 + mainfxn.getDimensions().right / 2;
			center.y = (60 + (mainfxn.getDimensions().bottom / 2));
			stage.addChild(hitA);
			
			//Debugging
			stage.addChild(mainfxn);
			
		}
		/**
		 * Adds or removes a given button from the stage
		 * @param	btn: Button to add/remove
		 * @param	bool: true to add it, false to remove it
		 */
		private function toggleButton(btn:DisplayObject, bool:Boolean):void {
			if (stage.contains(btn) && !bool) {
				stage.removeChild(btn);
			} else if (!stage.contains(btn) && bool) {
				stage.addChild(btn);
			}
		}
		/**
		 * Generic method to instantiate and set up all of the buttons on the UI
		 */
		private function getAllButtons():void {
			resumeButton = drawButton("Resume", 206, 35, 100, 30);
			aimCameraButton = drawButton("Aim Camera", 270, 35, 100, 30);
			pauseButton = drawButton("Pause", 206, 35, 100, 30);
			pauseButton.width = 60;												//So it doesn't look weird when you click the pause Button and the resume button pops up as a different size
			saveButton = drawButton("Save", 161, 35, 75, 30);
			
			autoScaleButton = drawButton("AutoScale", 82, 35, 60, 30);
			aboutButton = drawButton("About", 595, 35, 60, 30);
			helpButton = drawButton("Help!", 0, 35, 10, 10);
			
			
			/**
			 * readjustment of all the buttons
			 */
			autoScaleButton.x = 0;
			saveButton.x = autoScaleButton.x + autoScaleButton.width + 10;
			resumeButton.x = saveButton.x +saveButton.width + 10;
			pauseButton.x = resumeButton.x;
			aimCameraButton.x = resumeButton.x + resumeButton.width + 10;
			collectDataButton = drawButton("Capture Data", -15, 35, 100, 30);
			inputText.addChild(collectDataButton);
			aboutButton.x = 535;
			helpButton.x = aboutButton.x + aboutButton.width + 10;
			/**
			 * new:   create slider to select target size
			 */
			slideSelect = new Slider();
			slideSelect.direction = "vertical";
			slideSelect.maximum = 100;
			slideSelect.minimum = 5;
			slideSelect.value = 20;
			slideSelect.x = 710;
			slideSelect.y = 105;
			slideSelect.snapInterval = .01;
			slideSelect.setSize(100, 400);
			addChild(slideSelect);
			slideSelect.addEventListener(SliderEvent.CHANGE, slideChange);
			slideSelect.addEventListener(SliderEvent.THUMB_DRAG, slideChange);
			slideSelect.value = 20;
			slideDescript = new TextField();
			var f2:TextFormat = new TextFormat();
			f2.size = 16;
			slideDescript.text = "Select Target Size";
			slideDescript.setTextFormat(f2, -1, -1);
			slideDescript.x = 640;
			slideDescript.y = 75;
			slideDescript.width = 200;
			slideDescript.height = 25;
			addChild(slideDescript);
			
			/**
			 * Add Title of program to remain on screen.
			 */
			var title:TextField = new TextField();
			title.text = "Light Grapher v3.0";
			var format:TextFormat = new TextFormat();
			format.size = 26;
			format.bold = true;
			title.setTextFormat(format, -1, -1);
			title.x = 0;
			title.width = 500;
			addChild(title);
			
			/**
			 * Creates the insrtuctions for how to aim the target.
			 */
			aimInstr.text = "Use the slider to adjust the target circle so that it encompasses the star."
			aimInstr.x = 30;
			aimInstr.y = 540;
			aimInstr.wordWrap = true;
			aimInstr.width = 800;
			var f:TextFormat = new TextFormat();
			f.size = 20;
			aimInstr.setTextFormat(f, -1, -1);
			addChild(aimInstr);
			
			//add a bunch of listeners
			helpButton.addEventListener(MouseEvent.CLICK, this.helpAlert);
			aboutButton.addEventListener(MouseEvent.CLICK, this.alertAbout);
			autoScaleButton.addEventListener(MouseEvent.CLICK, mainfxn.adjustScale);
			resumeButton.addEventListener(MouseEvent.CLICK, mainfxn.onPause);
			collectDataButton.addEventListener(MouseEvent.CLICK, mainfxn.startDataCollection);
			collectDataButton.addEventListener(MouseEvent.CLICK, removeSlide);
			collectDataButton.addEventListener(MouseEvent.CLICK, removeAimInstr);
			aimCameraButton.addEventListener(MouseEvent.CLICK, mainfxn.stop);
			aimCameraButton.addEventListener(MouseEvent.CLICK, addSlide);
			aimCameraButton.addEventListener(MouseEvent.CLICK, addAimInstr);
			pauseButton.addEventListener(MouseEvent.CLICK, mainfxn.onPause);
			saveButton.addEventListener(MouseEvent.CLICK, mainfxn.save);
			
			//These are never taken away from the UI, so just add them right now
			toggleButton(aboutButton, true);
			toggleButton(helpButton, true);
		}
		/**
		 * Function to draw buttons
		 * @param	label: Text of the button
		 * @param	x: x-coord
		 * @param	y: y-coord
		 * @param	width: width of button
		 * @param	height: height
		 * @return A SimpleButton with a little style
		 */
		private function drawButton(label:String, x:int, y:int, width:int, height:int):SimpleButton {
			var returnSimple:SimpleButton = Alert.createButton(label, new AlertOptions(null, label), width, 0);
			returnSimple.x = x;
			returnSimple.y = y;
			return returnSimple;
		}
		/**
		 * Examines the current state of the application and adjusts the UI to reflect that by hiding or adding buttons
		 */
		public function onDataChange():void {
			if (mainfxn.isPaused()) {
				toggleButton(pauseButton, false);
				toggleButton(resumeButton, true);
				toggleButton(aimCameraButton, true);
				toggleButton(inputText, true);
				toggleButton(saveButton, true);
				toggleButton(autoScaleButton, true);
			} else if (mainfxn.inProgress()) {
				toggleButton(pauseButton, true);
				toggleButton(resumeButton, false);
				toggleButton(aimCameraButton, true);
				toggleButton(inputText, true);
				toggleButton(saveButton, true);
				toggleButton(autoScaleButton, true);
			} else {
				if (hitA != null && !stage.contains(hitA)) {
					stage.addChild(hitA);
				}
				toggleButton(pauseButton, false);
				toggleButton(resumeButton, false);
				toggleButton(aimCameraButton, false);
				toggleButton(inputText, true);
				toggleButton(saveButton, false);
				toggleButton(autoScaleButton, false);
			}
		}
		/**
		 * Initialization function used to add the block of "Capture Data for xx seconds" to the stage
		 */
		private function addInputText():void {
			var biggerFont:TextFormat = new TextFormat();
			biggerFont.size = 12;
			var format:TextFormat = new TextFormat();
			format.size = 12;
			format.underline = true;
			format.align = TextFormatAlign.CENTER;
			runTime.defaultTextFormat = format;
			runTime.border = true;
			runTime.borderColor = 0x000000;
			runTime..htmlText = '<font face="Verdana"><b>30</b></font>';
			runTime.x = 110;
			runTime.y = 35;
			runTime.width = 30;
			runTime.type = TextFieldType.INPUT;
			runTime.background = true;
			runTime.backgroundColor = 0xFFFFFF;
			runTime.height = 30;
			runTime.autoSize = TextFieldAutoSize.CENTER;
			
			runTime.textColor = 0x16166B;

			label.htmlText = '<font face="Verdana"><b> seconds</b></font>';
			label.x = 140;
			label.y = 35;
			label.width = 70;
			label.setTextFormat(biggerFont);
			
			smallLabel.htmlText = '<font face="Verdana"><b>for</b></font>';
			smallLabel.x = 84;
			smallLabel.y = 35;
			smallLabel.width = 25;
			smallLabel.setTextFormat(biggerFont);
			
			inputText.addChild(runTime);
			inputText.addChild(label);
			inputText.addChild(smallLabel);
			inputText.x = 325;
			inputText.name = "inputText";
		}
		/**
		 * A handler for the xx seconds part to parse the Execution time of the trial and set the value to it in main
		 */
		public function captureData():void {
			trace("capture data");
			if (hitA != null && stage.contains(hitA)) {
				stage.removeChild(hitA);
			}
			var time_exec:Number = Number(runTime.text)
			if (time_exec != 0) {
				mainfxn.setTimeExecution(time_exec);
			} else {
				//use default value
			}
		}
		/**
		 * Gets called when the trial completes and we're displaying data
		 * because there is no easy way to check for this in main, its easier
		 * to do this not in onDataChange() but instead in a separate callback function
		 */
		public function onTrialComplete():void {
			toggleButton(inputText, true);
			toggleButton(pauseButton, false);
			toggleButton(resumeButton, false);
			toggleButton(aimCameraButton, true);
		}
		/**
		 * Remove all UI components
		 */
		public function removeAll():void {
			if (stage.contains(this.inputText)) { stage.removeChild(inputText); }
			
			toggleButton(saveButton, false);
			toggleButton(inputText, false);
			toggleButton(pauseButton, false);
			toggleButton(resumeButton, false);
			toggleButton(aimCameraButton, false);
		}
		/**
		 * Adds the copyright
		 */
		private function addCopyRight():void {
			var format:TextFormat = new TextFormat();
			format.size = 10;
			copyRight.htmlText = "© 2012 by The Regents of the University of California. <br />Universal Permission granted for non-profit educational use";
			copyRight.multiline = true;
			copyRight.width = 260;
			copyRight.wordWrap = true;
			//copyRight.defaultTextFormat = format;
			copyRight.setTextFormat(format,-1,-1);
			copyRight.x = 0;
			copyRight.y = 570;
			stage.addChild(copyRight);
		}
		/**
		 * Refreshes it if something goes on top of it on stage
		 */
		public function refreshCopyright():void {
			var temp:TextField = (stage.removeChild(copyRight) as TextField);
			stage.addChild(temp);
		}
		/**
		 * Create the alert dialog about credit
		 * @param	e MouseEvent
		 */
		private function alertAbout(e:MouseEvent):void {
			if (mainfxn.inProgress()) {
				mainfxn.onPause();
			}
			Alert.init(stage);
			Alert.show("<h2>Welcome to Light Grapher!</h2><br /><br>" +
						"LightGrapher is a Flash applet that turns your webcam or built-in computer camera into a makeshift \n" +
						"light sensor to display graphically the brightness of a model star (a lightbulb or even light-colored \n" +
						"ball). When a [darker-colored] planet passes in front of the star, the brightness drops and a dip in the \n" +
						"graph occurs. The software receives real-time data from an external webcam or internal computer camera. \n" +
						"It may be run either directly from this page or downloaded and run locally in your browser.<br>" +
						
						"This Flash program detects changes in brightness of an object such as a light bulb and graphs <br />" + 
						"those changes in brightness. It was created to illustrate the function of the NASA Kepler photometer<br />in detecting changes in " + 
						"brightness of stars when planets pass in front of them (planet transits).<br /><br />" +
						
						"<br><br>Version 3.0, released 2012 Sep 14, is a major upgrade that </p>"+
						"<ul><li> allows for use in rooms with ambient  (non-dark) light, as in most classrooms,</li>"+
						"<li> works with either a light bulb as model star or simply a light colored ball,</li>"+
						"<li> has improved targeting control with a wider ranging slider to define target (star) size,</li>"+
						"<li> is not affected by background movements,</li>"+
						"<li> runs reliably every time.</li><br/>" +
						
						"Created by staff of Lawrence Hall of Science for the NASA Kepler Mission:<br />" + 
						"<ul><li>Jordan Bull (Programmer, Lawrence Hall of Science)</li>" +
						"<li>Ben Augarten (Programmer, Lawrence Hall of Science)</li>" + 
						"<li>David Spies (Programmer, Lawrence Hall of Science)</li>" + 
						"<li>Alan Gould (Kepler Co-Investigator for Education and Public Outreach)</li>" + 
						"</ul><br /><br />Version 1.0 © 2011, Version 2.0 © 2012, Version 3.0 © 2012 by the Regents of the University of California<br />" + 
						"Permission granted for non-profit educational use.</div>");
		}
		/**
		 * creates the alert dialog giving directions and tips about the software
		 * manually add new lines with \n bullet points are <li> </li> to indent use '\t\t  '
		 * @param	e
		 */
		private function helpAlert(e:MouseEvent):void {
			if (mainfxn.inProgress()) {
				mainfxn.onPause();
			}
			Alert.init(stage);
			Alert.show("This graphing software is designed to produce light curves for planet transit models, including:<br>"+
						"<ul><li> <a href=\"http://kepler.nasa.gov/education/ModelsandSimulations/LegoOrrery\">LEGO orrery</a></li>"+
						"<li> FOSS Orrery</li>"+
						"<li> a ball on a string, swinging pendulum-style but in orbit around a model star</li></ul><P><hr></P>" +
						
						"<P>DIRECTIONS:<br>"+
						"<ol><li>Set up planet(s) to orbit the model star (light bulb or white sphere).</li>"+
						"<li>Star the software and click on \"Allow\" to let brightness data to come in from the camera.</li>"+
						"<li>Aim the camera at the model star and center the targeting circle on the model star in the camera view.</li>"+
						"<li>Alter the height of the camera/laptop or the star-planet model so that the planet(s) actually pass in </li>\t\t" +
						"front of the star as seen by the camera view. [The camera must be in the planets' orbit plane.]"+
						"<li>Set size of target circle to fit the star using slider on right of screen. Making the targeting circle</li>\t\t" +
						"slightly smaller than the star is better than having it slightly larger than the star."+
						"<li>If desired, change duration of \"Capture Data\" (default time = 30 seconds)</li>"+
						"<li>Click \"Capture Data\" button and make planet(s) orbit.</li>"+
						"<li>To adjust vertical scale, either click \"Autoscale\" or manually enter minimum and maximum % values at</li>\t\t" +
						"bottom and top of y-axis."+
						"<li>You may cllick Pause button, then Resume, anytime during Data Capture.</li>"+
						"<li>You can \"Save\" the data for any trial as a .png graphics file that you can open in a graphics program.</li>"+
						"</ol>"+

						"<P>TIPS:<br>"+
						"<ul><li>It's best not to move the camera during a trial.</li>"+
						"<li>This software works best with</li>\t\t"+
						"- a light bulb as the model star at a distance of 1 meter or less, or<br>\t\t"+
						"- an opaque light-colored (or white) sphere as the star at a distance of 60 cm or less.<br>\t\t"+
						"In truth, the closer the model is to the camera, the better, but be sure to point out to students that \n\t\t" +
						"the model represents a situation where the camera/spacecraft is light-years away from the star.<br>"+
						"<li>In general, slower cranking and larger target sizes gives better results.</li>"+
						"<li>In darker environments, the webcam requires more exposure time for each frame effectively decreasing</li>\t\t" +
						"the frame rate, so crank the orrery more slowly if surroundings are dark."+
						"<li>If the environment is dark, using a light bulb as model star is preferable to a white sphere.</li>"+
						"</ul>");
		}
		
		public function getHitArea():CustomShape {
			return hitA.getHitArea();
		}
		public function getCenter():Point {
			trace("Center: " + center + " --- radius: " + hitA.getHitArea().getSize() * 10);
			return center;
		}
		/** changes the size of hitA */
		public function slideChange(e:SliderEvent):void {
			hitA.currentSize = (slideSelect.value * 240)/100;
			hitA.draw();
		}
		/** Creates the slider and its description **/
		private function addSlide(e:MouseEvent):void {
			addChild(slideSelect);
			addChild(slideDescript);
		}
		/**
		 * Removes the slider and its description so it wont be visible when not aiming the camera
		 * @param	e
		 */
		private function removeSlide(e:MouseEvent):void {
			removeChild(slideDescript);
			removeChild(slideSelect);
		}
		/**
		 * Removes the text below the webcam explaining how to aim the camera
		 * @param	e
		 */
		private function removeAimInstr(e:MouseEvent):void {
			removeChild(aimInstr);
		}
		/**
		 * Re-adds the text below the webcam explaining how to aim the camera
		 * @param	e
		 */
		private function addAimInstr(e:MouseEvent):void {
			addChild(aimInstr);
		}
	}

}
