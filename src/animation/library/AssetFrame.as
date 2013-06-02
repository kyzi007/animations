package animation.library {
    import flash.display.BitmapData;
    import flash.display.MovieClip;

    public class AssetFrame {
        public var x : int;
        public var y : int;

        public var bitmap      : BitmapData;
        public var isDestroyed : Boolean = false;

        public var movie       : MovieClip;

        public function AssetFrame(x : int, y : int, bitmap : BitmapData) {
            this.x = x;
            this.y = y;
            this.bitmap = bitmap;
        }

        public var dublicate:int = -1;

        public function destroy() : void {
            this.bitmap.dispose();
            isDestroyed = true;
        }

        public function clone():AssetFrame
        {
            var frame:AssetFrame = new AssetFrame(x, y, bitmap.clone());
            return frame;
        }
    }
}
