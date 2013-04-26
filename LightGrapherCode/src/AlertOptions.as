package  
{
	import flash.geom.Point
	
	//
	public class AlertOptions {
		
		public var background:String;
		public var buttons:Array = new Array();
		public var callback:Function;
		public var colour:int;
		public var fadeIn:Boolean;
		public var position:Point;
		public var promptAlpha:Number;
		public var text:String;
		public var textColour:int = 0x000000;
		public function AlertOptions(alertOptions:Object, Text:*):void {
			if (alertOptions != null) {
				if (alertOptions.background == null) {
					background = "simple";	
				} else {
					background = alertOptions.background;
				}
				if (alertOptions.buttons == null) {
					buttons = ["OK"];
				} else {
					if (alertOptions.buttons.length > 3) {
						buttons = alertOptions.buttons.slice(0, 2);
					} else {
						buttons = alertOptions.buttons;
					}
				}
				callback = alertOptions.callback; 
				if (alertOptions.colour == null) {
					colour = 0x4E7DB1;
				} else {
					colour = alertOptions.colour;
				}
				position = alertOptions.position;
				if (alertOptions.promptAlpha == null) {
					promptAlpha = 0.9;
				} else {
					promptAlpha = alertOptions.promptAlpha;
				}
				if (alertOptions.textColour != null) {
					textColour = alertOptions.textColour;
				} else {
					textColour = 0x000000;
				}
			} else {
				background = "simple";
				buttons = ["OK"];
				colour = 0x4E7DB1;
				promptAlpha = 0.9;
				textColour = 0x000000;
			}
			text = Text.toString();
		}
	}
}