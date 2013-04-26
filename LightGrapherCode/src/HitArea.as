package  
{
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.utils.SetIntervalTimer;
	import mx.controls.RadioButton;
	import mx.controls.RadioButtonGroup;
	
	/**
	 * ...
	 * @author Ben
	 */
	public class HitArea extends Sprite
	{
		public static const CIRCLE:String = "circle";
		public static const SQUARE:String = "square";
		private var xCoord:int;
		private var yCoord:int;
		private var shape:String;
		private const defaultSize:int = 50;
		private var newSize:int = -1;
		
		/* Keep Track of State */
		private var selected:String = CIRCLE;
		private var possibleShapes:Array = new Array();
		private var currentShape:int;			//This is the index in possibleShapes that the current shape is
		public var currentSize:int;			//So we don't constantly have to call possibleShapes[currentShape].getSize()
		
		public function HitArea(shape:String, x:int, y:int, slideStartSize:int) 
		{
			this.currentShape = 2; 			//Arbitrary number, but a good starting place
			this.shape = shape;
			this.xCoord = x;
			this.yCoord = y;
			trace(this.yCoord);
			currentSize = slideStartSize;
			draw();
			
			
		}
		public function draw():void {
			//drawRightColumn();
			//currentSize = 60;// (possibleShapes[currentShape] as CustomShape).getSize() * 10;
			
			this.graphics.clear();
			this.graphics.lineStyle(2, 0x000000, 1);
			trace("Drawing circle");
			this.graphics.drawCircle(xCoord, yCoord, currentSize); // defaultSize);
			
		}
		public function setShape(newShape:String):void {
			if (newShape != CIRCLE && newShape != SQUARE) {
				newShape = CIRCLE;
			}
			this.shape = newShape;
			selected = newShape;
			draw();
		}
		public function setSize(size:int):void {
			newSize = size;
			draw();
		}
		private function changeShape(e:MouseEvent):void {
			trace(((e.target as Sprite).getChildAt(0) as TextField).text);
			switch ((((e.target as Sprite).getChildAt(0) as TextField).text).toLowerCase()) {
				case CIRCLE:
					setShape(CIRCLE);
					break;
				case SQUARE:
					setShape(SQUARE);
					break;
			}
				
		}
		private function showSizes():void {
			possibleShapes = null;
			possibleShapes = new Array();
			var index:int = 0;			//keep track of indecies
			var x1:int = 680, y1:int = 100;
			for (var i:int = 30; i < 200;  i += 15) {
				
				var temp:CustomShape = new CustomShape(i / 10, shape, index);
				if (index == currentShape) {
					temp.drawBackground();
				}
				index++;
				
				/*if (x1 + i / 10 > 730) {
					x1 = 650;
					y1 += (2*i) / 10 + 8;
				}*/
				//temp.x = x1 + (i / 10);
				temp.x = x1;
				temp.y = y1+(i/10);
				temp.width = 2 * (i / 10);
				temp.height = 2 * (i / 10);
				temp.addEventListener(MouseEvent.CLICK, changeShapeSize);
				addChild(temp);
				possibleShapes.push(temp);
				//x1 += (2*i) / 10 + 5;
				y1 += (2*i)/10 + 8
			}
		}
		private function changeShapeSize(e:MouseEvent):void {
			var newShape:CustomShape = (e.target as CustomShape);
			currentShape = newShape.getIndex();
			var newSize:int = newShape.getSize();
			currentSize = newSize;
			draw();
			
		}
		
		public function getHitArea():CustomShape {
			return new CustomShape(currentSize/10,CIRCLE,0);
		}
	}

}