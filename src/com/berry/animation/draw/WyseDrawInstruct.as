package com.berry.animation.draw {
    import com.berry.animation.library.AssetData;
    import com.berry.animation.library.AssetDataGetQuery;
    import com.berry.animation.library.AssetFrame;

    import flash.display.BitmapData;
    import flash.display.MovieClip;
    import flash.display.Sprite;
    import flash.geom.Matrix;
    import flash.geom.Rectangle;
    import flash.utils.getTimer;

    import log.logServer.KLog;

    public class WyseDrawInstruct extends BaseDrawInstruct {

        public function WyseDrawInstruct(assetData:AssetData, config:AssetDataGetQuery, source:Sprite) {
            super(assetData, config, source);
        }

        private var _matrix:Matrix = new Matrix();
        private var _render:MovieClip = null;
        private var _timline:Vector.<AssetFrame>;
        private var _time:int;

        override public function finish():void {
            //CONFIG::debug{ KLog.log("com.berry.animation.draw.WyseDrawInstruct : finish  " + _query.name + " " + _query.animation, KLog.METHODS); }
            _render = null;
            trace(getTimer() - _time, _query.name, _query.animation, _query.rotate)
            super.finish();
        }

        override protected function drawFrame(frame:int):Boolean {
            super.drawFrame(frame);
            if (!_render) {
                falled();
                return true;
            }

            _render.gotoAndStop(frame + 1);
            var bitmap:BitmapData;

            var stateRect:Rectangle = _render.getBounds(_source);

            stateRect.top = Math.floor(stateRect.top);
            stateRect.right = Math.ceil(stateRect.right);
            stateRect.bottom = Math.ceil(stateRect.bottom);
            stateRect.left = Math.floor(stateRect.left);

            _matrix.tx = -stateRect.x;
            _matrix.ty = -stateRect.y;

            bitmap = new BitmapData(stateRect.width, stateRect.height, true, 0);
            bitmap.draw(_source, _matrix);

            var duplicateFrame:int = checkDuplicateData(bitmap, stateRect, frame);
            if (duplicateFrame != -1) {
                bitmap.dispose();
                _timline[frame] = new AssetFrame(stateRect.x, stateRect.y, _timline[duplicateFrame].bitmap);
                _timline[frame].dublicate = duplicateFrame;
            } else {
                _timline[frame] = new AssetFrame(stateRect.x, stateRect.y, bitmap);
            }

            return (frame + 1 == _totalFrames)
        }

        override public function init():void {
            super.init();
            _time = getTimer();
            //CONFIG::debug{ KLog.log("com.berry.animation.draw.WyseDrawInstruct : init  " + _query.name + " " + _query.animation, KLog.METHODS); }

            _source.gotoAndStop(_query.step);

            _timline = _assetData.frames;

            var name:String = _query.animation + _query.position + _query.rotate;
            _render = _source.getChildByName(name) as MovieClip;

            if (_render != null) {
                setText();
                hideClips();
                _source.x = 0;
                _source.y = 0;
                _totalFrames = _query.isFullAnimation ?_render.totalFrames : 1;
            } else {
                falled();
                CONFIG::debug{ KLog.log("com.berry.animation.draw.WyseDrawInstruct : init  INVALID ANIMATION " + _query.animation, KLog.ERROR); }
            }
        }

        private function hideClips():void {
            for (var i:int = 0; i < _source.numChildren; i++) {
                var item:MovieClip = _source.getChildAt(i) as MovieClip;
                item.visible = item == _render;
                item.stop();
            }
        }

        private function setText():void {
            if (_query.text != null) {
                var textMc:MovieClip = _render[TEXT_MC_NAME];
                if (textMc) {
                    textMc[TEXT_NAME].text = _query.text;
                    textMc[TEXT_SHADOW_NAME].text = _query.text;
                }
            }
        }
    }
}
