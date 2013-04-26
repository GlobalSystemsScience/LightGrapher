package  
{
	import flash.display.Sprite;
	import flash.text.TextField;
	import mx.controls.CheckBox;
	import Preference;
	/**
	 * ...
	 * @author Ben
	 */
	public class PreferenceWrapper extends Sprite 
	{
		private var prefs:Preference;
		private var byteArray:ByteArray = new ByteArray();
		private var fileStream:FileStream;
		private var cb_remember:CheckBox;
		
		var labels:Array = new Array(new Array(), new Array());		//New array, labels[0] is the txt, labels[1] is the label
		//The inputs
		private var txt_topScale:TextField;
		private var txt_bottomScale:TextField;
		private var txt_timeDisplayed:TextField;
		private var txt_timeMoveBack:TextField;
		
		//The labels
		private var label_topScale:TextField;
		private var label_bottomScale:TextField;
		private var label_timeDisplayed:TextField;
		private var label_timeMoveBack:TextField;
		[Bindable] private var userData:User;
		public function PreferenceWrapper() 
		{
			prefs = new Preference("settings.obj");
			prefs.addEventListener(PreferenceChangeEvent.PREFERENCE_CHANGED_EVENT, onPrefChange);
			checkSettings();
			labels[0] = [txt_topScale, txt_bottomScale, txt_timeDisplayed, txt_timeMoveBack];
			labels[1] = [label_topScale, label_bottomScale, label_timeDisplayed, label_timeMoveBack];
		}
		
		private function onPrefChange(event:PreferenceChangeEvent) {
			if (event.action == PreferenceChangeEvent.ADD_EDIT_ACTION) {
				//new value
			} else if (event.action == PreferenceChangeEvent.DELETE_ACTION) {
				
			}
		}
		private function saveSettings():void {
			if (cb_remember.selected) {
								
				prefs.setValue("topScale", txt_topScale.text, false);
				prefs.setValue("bottomScale", txt_bottomScale, false);
				prefs.setValue("timeDisplayed", txt_timeDisplayed.text, false);
				prefs.setValue("timeMoveBack", txt_timeMoveBack.text, false);
//				prefs.setValue("savePath", txt										Save not implemented yet
			} else {
				//warn them?
			}
		}
		private function checkSettings():void {
			prefs.load();
			txt_topScale.text = prefs.getValue("topScale");
			txt_bottomScale.text = prefs.getValue("bottomScale");
			txt_timeDisplayed.text = prefs.getValue("timeDisplayed");
			txt_timeMoveBack.text = prefs.getValue("timeMoveBack");
			
			for (var txt:TextField in labels[0]) {
				txt.type = "input";
			}
				/*txt_topScale.type = "input";
				txt_bottomScale.type = "input";
				txt_timeDisplayed.type = "input";
				txt_timeMoveBack.type = "input";
				*/
		}
		
		private function drawInterface():void {
			checkSettings();		//load settings
			loadLabels();			//load labels
			for (var i:int = 1; i <= 4; i ++ ) {
				labels[0][i - 1].y = (i * 40);
				labels[1][i - 1].y = (i * 40);
				labels[0][i - 1].x = 200;
				labels[0][i - 1].visible = true;
				labels[1][i - 1].visible = true;
				addChild(labels[0][i - 1]);
				addChild(labels[1][i - 1]);
			}
			
		}
		private function loadLabels():void {
			label_topScale.text = "Top Scale: ";
			label_bottomScale.text = "Bottom Scale: ";
			label_timeDisplayed.text = "Time to Display on X axis: ";
			label_timeMoveBack.text = "Time to move back when Time Displayed is exceeded: ";
		}
		
	}

}