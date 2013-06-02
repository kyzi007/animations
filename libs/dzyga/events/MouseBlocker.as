package dzyga.events
{
    import flash.display.DisplayObject;
    import flash.display.DisplayObjectContainer;
    import flash.display.Graphics;
    import flash.display.InteractiveObject;
    import flash.display.Sprite;
    import flash.display.Stage;

    public class MouseBlocker {
		public static function init(root:DisplayObject):void {
			var stage:Stage = root.stage;
			stage.addChild(MouseBlocker.hitArea);
		}
		
		
		public static function block(target:InteractiveObject):void {
			target.mouseEnabled = false;
			var sprite:Sprite = target as Sprite;
			var container:DisplayObjectContainer = target as DisplayObjectContainer;
			if (container) {
				container.mouseChildren = false;
			}
			if (sprite) {
				sprite.hitArea = MouseBlocker.hitArea;
			}
			
		}
		
		public static function unblock(target:InteractiveObject):void {
			var targetSprite:Sprite = target as Sprite;
			if (targetSprite) {
				targetSprite.hitArea = null;
			}
			var targetContainer:DisplayObjectContainer = target as DisplayObjectContainer;
			if (targetContainer) {
				targetContainer.mouseChildren = true;
			}
			target.mouseEnabled = true;
		}
		
		private static var _hitArea:Sprite;
		public static function get hitArea():Sprite {
			if (!_hitArea) {
				_hitArea = new Sprite();
				var gr:Graphics = _hitArea.graphics;
				gr.beginFill(0x009900, 0);
				gr.drawCircle(0, 0, 10);
				gr.endFill();
				
				hitArea.x = -10;
				hitArea.y = -10;
			}
			return _hitArea;
		}
	}
}
