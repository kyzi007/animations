package com.berry.animation.core.components {
    import com.berry.animation.core.*;
    import animation.*;

    import com.berry.animation.core.view.AssetCanvas;

    import com.berry.animation.data.AnimationSettings;

    import com.berry.animation.library.AnimationsList;

    import com.berry.animation.library.AssetData;

    import flash.display.Bitmap;
    import flash.display.DisplayObject;

    import org.ColorMatrix;
    import org.dzyga.callbacks.Promise;
    import org.dzyga.display.DisplayUtils;
    import org.dzyga.geom.Rect;

    public class BodyTileComponent implements IAssetViewComponent {
        public function BodyTileComponent(parent:AssetView) {
            _parent = parent;
        }

        private static const _BOUNDS:Rect = new Rect(
                -AnimationSettings.tileWidth/2,
                -AnimationSettings.tileHeight / 2,
                AnimationSettings.tileWidth,
                AnimationSettings.tileHeight
        );
        private var _canvas:AssetCanvas;
        private var _parent:AssetView;
        private var _assetData:AssetData;

        public function set smoothing(value:Boolean):void {
            _canvas.smoothing = value;
        }
        public function play():void {
            // drawn only once
            if (!_canvas.currentFrameData && _assetData.isRenderFinish) {
                _canvas.draw(_assetData.frames[int(Math.random() * _assetData.frames.length)]);
                _assetData.completeRenderPromise.callbackRemove(renderFinishCallback);
            }
        }

        public function hitTest(globalX:int, globalY:int, checkContainer:Boolean = false):Boolean {
            return DisplayUtils.hitTest(_view, globalX, globalY, checkContainer);
        }

        public function init():void {
            _canvas = new AssetCanvas(_parent.data.assetName);
            _view = _canvas;
            _assetData = _parent.assetLibrary.getAndInitAssetData(_parent.data.getQueryByName(AnimationsList.IDLE));
            _assetData.useCount++;
            if (_assetData.isRenderFinish) {
                play();
            } else {
                _assetData.completeRenderPromise.callbackRegister(renderFinishCallback);
            }
        }

        public function clear():void {
            _assetData.useCount--;
        }

        public function applyFilter(value:ColorMatrix):void {
            // TODO
        }

        public function removeFilter():void {
        }

        private function renderFinishCallback(...patams):void {
            play();
        }

        private var _view:Bitmap;

        public function get view():DisplayObject {
            return _view;
        }

        public function get isRendered():Boolean {
            return _assetData.isRenderFinish;
        }

        public function get finishRenderPromise():Promise {
            return null;
        }

        public function get bounds():Rect {
            return _BOUNDS;
        }

        public function get boundsUpdatePromise():Promise {
            return _canvas.boundsUpdatePromise;
        }

        public function set x(value:int):void {
            _canvas.x = value;
        }

        public function set y(value:int):void {
            _canvas.y = value;
        }

        public function set animationSpeed(value:Number):void {
            // none
        }

        public function renderAndDrawLock():void {
        }

        public function renderAndDrawUnLock():void {
        }
    }
}
