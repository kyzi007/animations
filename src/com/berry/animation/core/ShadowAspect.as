package com.berry.animation.core {
    import animation.*;

    import com.berry.animation.library.AssetData;

    import flash.display.Bitmap;
    import flash.display.DisplayObject;

    import org.ColorMatrix;
    import org.dzyga.callbacks.Promise;
    import org.dzyga.display.DisplayUtils;
    import org.dzyga.geom.Rect;

    public class ShadowAspect implements IAssetViewAspect {
        public function ShadowAspect(parent:AssetView) {
            _parent = parent;
        }

        private var _assetSprite:AssetSprite;
        private var _parent:AssetView;
        private var _assetData:AssetData;
        private var _visible:Boolean;
        private var _view:Bitmap;
        private var _waitPlay:Boolean;

        /*
        show after rendering, visible and parent asset body render finish
         */
        public function play():void {
            if (!_visible) {
                _waitPlay = true;
                return;
            }
            if(!_parent.mainAspect.isRendered){
                _parent.mainAspect.finishRenderPromise.callbackRegister(tryPlayCallback);
                _waitPlay = true;
                return;
            }
            _waitPlay = false;
            _parent.mainAspect.finishRenderPromise.callbackRemove(tryPlayCallback);
            var assetData:AssetData = _parent.assetLibrary.getAssetData(_parent.data.getQuery(AnimationsList.SHADOW));
            if (_assetData && assetData != _assetData) {
                _assetData.useCount--;
            }
            _assetData = assetData;
            _assetData.useCount++;
            if (_assetData.isRenderFinish && _assetData.frames.length) {
                _assetSprite.draw(_assetData.frames[0]);
                _assetData.completeRenderPromise.callbackRemove(tryPlayCallback);
            } else {
                _assetData.completeRenderPromise.callbackRegister(tryPlayCallback);
            }
        }

        public function setVisible(value:Boolean):void {
            _visible = value;
            _assetSprite.setVisible(value);
            if (_waitPlay) {
                play();
            }
        }

        public function hitTest(globalX:int, globalY:int, checkContainer:Boolean = false):Boolean {
            return false;
        }

        public function init():void {
            _assetSprite = new AssetSprite(_parent.data.assetName);
            _view = _assetSprite.view;
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
            return null;
        }

        public function get bounds():Rect {
            return null;
        }

        public function get boundsUpdatePromise():Promise {
            return null;
        }

        public function set x(value:int):void {
            _assetSprite.x = value;
        }

        public function set y(value:int):void {
            _assetSprite.y = value;
        }

        public function set animationSpeed(value:Number):void {
            // none
        }
    }
}
