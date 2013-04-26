package Menu 
{
	import flash.display.Sprite;
	import flash.media.Camera;
	import flash.display.Shape;
	import flash.text.*;
	/**
	 * ...
	 * @author Ben
	 */
	public class MenuButton extends Sprite
	{
		private var _label:String;
		private var _index:String;
		private var locked:Boolean;
		private var bg:Shape = new Shape();
		private var tField:TextField = new TextField();
		public function MenuButton(label:String, index:String) 
		{
			_label = label;
			_index = index;
			buttonMode = true;
            mouseChildren = false;
			this.visible = false;
            draw();
			locked = false;
			this.height = 30;
			this.width = 100;
			
			
		}
		private function draw():void {
			
			
            bg.graphics.beginFill(0xC0C0C0);
            bg.graphics.drawRect(0, 0, 100, 30);
            bg.graphics.endFill();
            addChild(bg);

			
            tField.multiline = false;
            tField.selectable = false;
            tField.text = _label;
			tField.width = 100;
			tField.height = 30;
			var format:TextFormat = new TextFormat();
			format.align = TextFormatAlign.CENTER;
			format.color = 0x000000;
			format.size = 12;
			tField.setTextFormat(format);
			tField.defaultTextFormat = format;
            addChild(tField);
		}
		public function toggleVisibility(_visible:Boolean):void {
			if (locked) { return;}
			this.visible = _visible;
			
		}
		public function getLabel():String {
			return _label;
		}
		public function getIndex():String {
			return _index;
		}
		public function lock():void {
			locked = true;
		}
		public function unLock():void {
			locked = false;
		}
		public function setYCoord(height:int):void {
			this.y = height;
		}
		public function setLabel(label:String):void {
			this._label = label;
			this.tField.text = _label;
		}
		public function  setBackground(bgColor:Number):void {
			removeChild(bg);
			bg.graphics.beginFill(bgColor);
            bg.graphics.drawRect(0, 0, 100, 30);
            bg.graphics.endFill();
            addChildAt(bg, 0);
			
		}
		public function addBorder():void {
			tField.border = true;
			tField.borderColor = 0x000000;
		}
	}
	

}