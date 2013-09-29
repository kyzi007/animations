package com.berry.animation.library {
    import flash.display.BitmapData;
    import flash.geom.Rectangle;
    import flash.utils.ByteArray;

    public class AssetFrame {
        public function AssetFrame(x:int, y:int, bitmap:BitmapData) {
            this.x = x;
            this.y = y;
            this.bitmap = bitmap;
        }

        public var x:int;
        public var y:int;
        public var bitmap:BitmapData;
        public var isDestroyed:Boolean = false;
        public var dublicate:int = -1;

        public function destroy():void {
            this.bitmap.dispose();
            isDestroyed = true;
        }

        public function pack():Object {
            return {x: x, y: y, width: bitmap.width, height: bitmap.height, bitmap: bitmap.getPixels(new Rectangle(0, 0, bitmap.width, bitmap.height))};
        }

        public function unPack(obj:Object):void {
            x = obj.x;
            y = obj.y;
            bitmap = new BitmapData(obj.width, obj.height, true,  0);
            bitmap.setPixels(new Rectangle(0,0, obj.width, obj.height), obj.bitmap as ByteArray);
        }
    }
}
