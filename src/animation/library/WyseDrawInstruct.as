package animation.library {

    import animation.AssetTypes;

    import flash.display.BitmapData;
    import flash.display.MovieClip;
    import flash.display.Sprite;
    import flash.geom.Matrix;
    import flash.geom.Rectangle;

    import log.logServer.KLog;

    internal class WyseDrawInstruct extends BaseDrawInstruct {

        public function WyseDrawInstruct(assetData:AssetData, config:AssetDataGetQuery, source:Sprite) {
            super(assetData, config, source);
        }

        private var _matrix:Matrix = new Matrix();
        private var _render:MovieClip = null;
        private var _timline:Vector.<AssetFrame>;

        override protected function drawFrame(frame:int):Boolean {
            if (!_render) {
                falled();
                return true;
            }
            _render.gotoAndStop(frame + 1);
            var bitmap:BitmapData;

            /*if (frames.length > frame && frames[frame].dublicate != -1) {
             bitmap = frames[_assetData[frame].dublicate].bitmap;
             } else {*/
            var stateRect:Rectangle = _render.getBounds(_source);

            stateRect.top = Math.floor(stateRect.top);
            stateRect.right = Math.ceil(stateRect.right);
            stateRect.bottom = Math.ceil(stateRect.bottom);
            stateRect.left = Math.floor(stateRect.left);

            _matrix.tx = -stateRect.x;
            _matrix.ty = -stateRect.y;

            bitmap = new BitmapData(stateRect.width, stateRect.height, true, 0);
            bitmap.draw(_source, _matrix);
            //}

            /*if (frames.length > frame) {
             frames[frame].bitmap = bitmap;
             } else {
             var duplicateFrame:int = checkDuplicateData(bitmap, stateRect, frame);
             if (duplicateFrame != -1) {
             bitmap.dispose();
             frames[frame] = new AssetFrame(stateRect.x, stateRect.y, frames[duplicateFrame].bitmap);
             frames[frame].dublicate = duplicateFrame;
             } else {*/
            _timline[frame] = new AssetFrame(stateRect.x, stateRect.y, bitmap);
            //}
            //}

            return (frame + 1 == _totalFrames)
        }

        override protected function init():void {
            super.init();

            CONFIG::debug{ KLog.log("WyseDrawInstruct : init  " + _query.animation, KLog.METHODS); }

            _source.gotoAndStop(_query.step);
            _timline = _assetData.frames;

            var name:String = _query.animation + _query.position + _query.rotate;
            _render = _source.getChildByName(name) as MovieClip;

            if (_render != null) {
                setText();
                hideClips();
                _source.x = 0;
                _source.y = 0;
                _totalFrames = _render.totalFrames;
            } else {
                falled();
                CONFIG::debug{ KLog.log("WyseDrawInstruct : init  INVALID ANIMATION " + _query.animation, KLog.ERROR); }
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
                if (_query.objectType == AssetTypes.OBSTACLE) {
                    var textMc:MovieClip = _render[TEXT_MC_NAME];
                    if (textMc) {
                        textMc[TEXT_NAME].text = _query.text;
                        textMc[TEXT_SHADOW_NAME].text = _query.text;
                    }
                } else {
                    throw new Error('text not supported in' + _query.objectType);
                }
            }
        }
    }
}
