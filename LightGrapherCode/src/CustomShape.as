package  
{
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	/**
	 * ...
	 * @author Ben
	 */
	public class CustomShape extends Sprite
	{
		private var radius:int;
		private var shape:String;
		private var drawFunction:Function;
		private var index:int;
		public function CustomShape(value:int, shape:String, index:int) 
		{
			buttonMode = true;
			radius = value;
			this.index = index;
			this.width = 2 * value;
			this.height = 2 * value;
			this.shape = shape;
			
			this.graphics.lineStyle(2, 0x000000);
			this.graphics.beginFill(0xFFFFFF);
			switch (shape) {
				case HitArea.CIRCLE:
					trace("hello");
					this.graphics.drawCircle(0, 0, radius);
					break;
				case HitArea.SQUARE:
					this.graphics.drawRect(0, 0, radius * 2, 2 * radius);
					break;
			}
			this.graphics.endFill();
			
		}
		public function getSize():int {
			return radius;
		}
		public function getIndex():int {
			return index;
		}
		public function drawBackground():void {
			this.graphics.beginFill(0xC0DBE4, .7);
			if (shape == HitArea.CIRCLE) {
				this.graphics.drawRect( -radius - 3, -radius - 3, radius * 2 + 6, radius * 2 + 6);
			} else {
				this.graphics.drawRect( -3, -3, radius * 2 + 6, radius * 2 + 6);
			}
			this.graphics.endFill();
		}
	}

}