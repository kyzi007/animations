package com.berry.animation.core {
    import com.berry.animation.library.AssetData;

    import flash.display.DisplayObject;
    import flash.display.Sprite;

    import org.ColorMatrix;
    import org.dzyga.callbacks.Promise;
    import org.dzyga.display.DisplayUtils;
    import org.dzyga.geom.Rect;

    public class ClassicMainAspect implements IAssetViewAspect {
        public function ClassicMainAspect(parent:AssetView) {
            _parent = parent;
        }

        private var _parent:AssetView;
        private var _preloader:AssetMovieClip;
        private var _main:AdvancedAssetMovieClip;
        private var _view:Sprite = new Sprite;
        private var _visible:Boolean;

        public function play():void {
            _main.playAnimationSet(_parent.data.animationModel);
            if(!_main.isRenderFinish){
                showPreloader();
                _main.renderCompletePromise.callbackRegister(hidePreloader);
            }
        }

        private function hidePreloader(...params):void {
            _main.renderCompletePromise.callbackRemove(hidePreloader);
            if(_preloader){
                _view.removeChild(_preloader.view);
                _preloader.clear();
                _preloader = null;
            }
        }

        private function showPreloader():void {
            if(_preloader) {
                return;
            }
            var preloaderAssetData:AssetData = _parent.assetLibrary.getPreloader(_parent.data.assetName);
            if(!preloaderAssetData) {
                return;
            }
            _preloader = new AssetMovieClip('preloader');
            _preloader.assetData = preloaderAssetData;
            if(!_preloader.assetData.isRenderFinish){
                _preloader.assetData.completeRenderPromise.callbackRegister(playPreloader);
            } else {
                _preloader.gotoAndPlay(0);
            }
            _view.addChild(_preloader.view);
            _preloader.setVisible(_visible);
        }

        private function playPreloader(...params):void {
            if(_preloader){
                _preloader.gotoAndPlay(0);
                _preloader.assetData.completeRenderPromise.callbackRemove(playPreloader);
            }
        }

        public function setVisible(value:Boolean):void {
            _visible = value;
            if(_preloader){
                _preloader.setVisible(value);
            }
            _main.setVisible(value);
        }

        public function get view():DisplayObject {
            return _view;
        }

        public function get isRendered():Boolean {
            return _main.isRenderFinish;
        }

        public function get finishRenderPromise():Promise {
            return _main.renderCompletePromise;
        }

        public function hitTest(globalX:int, globalY:int, checkContainer:Boolean = false):Boolean {
            if(_main.isRenderFinish) return DisplayUtils.hitTest(_view, globalX, globalY, checkContainer);
            else return true;
        }

        public function get bounds():Rect {
            return _main.bounds;
        }

        public function init():void {
            _main = new AdvancedAssetMovieClip(_parent.data.assetName);
            _main.data = _parent.data;
            _main.assetLibrary = _parent.assetLibrary;
            _view.addChild(_main.assetMovieClip.view);
        }

        public function clear():void {
            if(_preloader){
                _preloader.clear();
            }
            _main.cleanUp();
        }

        public function get boundsUpdatePromise():Promise {
            return _main.assetMovieClip.boundsUpdatePromise;
        }

        public function set x(value:int):void {
            _view.x = value;
        }

        public function set y(value:int):void {
            _view.y = value;
        }

        public function applyFilter(value:ColorMatrix):void {
            _main.applyFilter(value);
        }

        public function removeFilter():void {
            _main.removeFilter();
        }

        public function set animationSpeed(value:Number):void {
            _main.speed = value;
        }
    }
}
