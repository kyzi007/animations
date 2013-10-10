package com.berry.animation.core.components {
    import com.berry.animation.core.*;

    import animation.*;

    import com.berry.animation.core.view.AssetCanvas;

    import com.berry.animation.library.AnimationsList;

    import com.berry.animation.library.AssetData;

    import flash.display.Bitmap;
    import flash.display.DisplayObject;

    import log.logServer.KLog;

    import org.ColorMatrix;
    import org.dzyga.callbacks.Promise;
    import org.dzyga.display.DisplayUtils;
    import org.dzyga.geom.Rect;

    public class ShadowComponent implements IAssetViewComponent {
        public function ShadowComponent(parent:AssetView) {
            _parent = parent;
        }

        private var _canvas:AssetCanvas;
        private var _parent:AssetView;
        private var _assetData:AssetData;
        private var _view:Bitmap;
        private var _waitPlay:Boolean;
        private var _lock:Boolean;

        /*
         show after rendering, visible and parent asset body render finish
         */
        public function play():void {
            if (_lock) {
                _waitPlay = true;
                return;
            }
            if (!_parent.mainComponent.isRendered) {
                _parent.mainComponent.finishRenderPromise.callbackRegister(tryPlayCallback);
                _waitPlay = true;
                return;
            }
            _parent.mainComponent.finishRenderPromise.callbackRemove(tryPlayCallback);
            var assetData:AssetData = _parent.assetLibrary.getAssetData(_parent.data.getQuery(AnimationsList.SHADOW));
            if (_assetData && assetData != _assetData) {
                _assetData.useCount--;
            }
            _assetData = assetData;
            _assetData.useCount++;
            if (_assetData.isRenderFinish && _assetData.frames.length) {
                _canvas.draw(_assetData.frames[0]);
                _assetData.completeRenderPromise.callbackRemove(tryPlayCallback);
            } else {
                _assetData.completeRenderPromise.callbackRegister(tryPlayCallback);
            }
        }

        public function hitTest(globalX:int, globalY:int, checkContainer:Boolean = false):Boolean {
            return false;
        }

        public function init():void {
            _canvas = new AssetCanvas(_parent.data.assetName);
            _view = _canvas;
            play();
        }

        public function clear():void {
            _assetData.useCount--;
        }

        public function applyFilter(value:ColorMatrix):void {
            // none
        }

        public function removeFilter():void {
            // none
        }

        private function tryPlayCallback(...patams):void {
            play();
        }

        public function get view():DisplayObject {
            return _view;
        }

        public function get isRendered():Boolean {
            return _assetData.isRenderFinish;
        }

        public function get finishRenderPromise():Promise {
            CONFIG::debug{ KLog.log("ShadowComponent : finishRenderPromise  " + "not work", KLog.ERROR); }
            return null;
        }

        public function get bounds():Rect {
            CONFIG::debug{ KLog.log("ShadowComponent : bounds  " + "not work", KLog.ERROR); }
            return null;
        }

        public function get boundsUpdatePromise():Promise {
            CONFIG::debug{ KLog.log("ShadowComponent : boundsUpdatePromise  " + "not work", KLog.ERROR); }
            return null;
        }

        public function set x(value:int):void {
            _canvas.x = value;
        }

        public function set y(value:int):void {
            _canvas.y = value;
        }

        public function set animationSpeed(value:Number):void {
            CONFIG::debug{ KLog.log("ShadowComponent : animationSpeed  " + "not work", KLog.ERROR); }
        }

        public function renderAndDrawLock():void {
            _lock = true;
            _canvas.drawLock();
        }

        public function renderAndDrawUnLock():void {
            _canvas.drawUnLock();
            _lock = false;
            if (_waitPlay) {
                _waitPlay = false;
                play();
            }
        }

        public function set smoothing(value:Boolean):void {
            _canvas.smoothing = value;
        }
    }
}
