package animation.library {
    import animation.AnimationSettings;

    import flash.display.BitmapData;
    import flash.display.DisplayObject;
    import flash.geom.Matrix;

    internal class TileDrawInstruct extends BaseDrawInstruct {

        public function TileDrawInstruct(assetData:AssetData, config:AssetDataGetQuery, source:DisplayObject) {
            super(assetData, config, source);
        }

        private static const WIDTH:int = 95;

        override protected function drawFrame(frame:int):Boolean {
            var matrix:Matrix = new Matrix();
            var bitmap:BitmapData = new BitmapData(WIDTH, _source.height, true, 0);
            matrix.identity();
            matrix.tx = -WIDTH * frame;
            bitmap.draw(_source, matrix);

            _assetData.frames[frame] = new AssetFrame(-bitmap.width / 2, -bitmap.height / 2, bitmap);
            return (frame + 1 == _totalFrames);
        }

        override protected function init():void {
            _totalFrames = _source.width / AnimationSettings.tileWidth;
        }
    }
}
