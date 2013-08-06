package com.berry.animation.draw {
    import com.berry.animation.data.AnimationSettings;
    import com.berry.animation.library.AssetData;
    import com.berry.animation.library.AssetDataGetQuery;
    import com.berry.animation.library.AssetFrame;

    import flash.display.BitmapData;
    import flash.display.DisplayObject;
    import flash.geom.Matrix;

    public class TileDrawInstruct extends BaseDrawInstruct {

        public function TileDrawInstruct(assetData:AssetData, config:AssetDataGetQuery, source:DisplayObject) {
            super(assetData, config, source);
        }

        private static const WIDTH:int = 95;

        override protected function drawFrame(frame:int):Boolean {
            super.drawFrame(frame);
            var matrix:Matrix = new Matrix();
            var bitmap:BitmapData = new BitmapData(WIDTH, _source.height, true, 0);
            matrix.identity();
            matrix.tx = -WIDTH * frame;
            bitmap.draw(_source, matrix);

            _assetData.frames[frame] = new AssetFrame(-bitmap.width / 2, -bitmap.height / 2, bitmap);
            return (frame + 1 == _totalFrames);
        }

        override public function init():void {
            super.init();
            _totalFrames = _source.width / AnimationSettings.tileWidth;
        }
    }
}