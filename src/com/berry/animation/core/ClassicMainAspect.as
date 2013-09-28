package com.berry.animation.core {
    import animation.*;
    import com.berry.animation.core.AdvancedAssetMovieClip;
    import com.berry.animation.core.AssetMovieClip;
    import com.berry.animation.library.AssetData;

    import fl.video.ParseResults;

    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.geom.Point;

    import org.dzyga.callbacks.Promise;
    import org.dzyga.display.DisplayUtils;
    import org.dzyga.geom.Rect;

    public class ClassicMainAspect implements IAssetViewAspect {
        public function ClassicMainAspect(parent:AssetViewNew) {
            _parent = parent;
        }

        private var _parent:AssetViewNew;
        private var _preloader:AssetMovieClip;
        private var _main:AdvancedAssetMovieClip;
        private var _view:Sprite = new Sprite;
        private var _visible:Boolean;
        private var _assetData:AssetData;

        public function play():void {
            _main.playAnimationSet(_parent._data.animationModel);
            if(!_main.isRenderFinish){
                showPreloader();
                _main.renderCompletePromise.callbackRegister(hidePreloader);
            }
            _view.addChild(_main.assetMovieClip.view);
        }

        private function hidePreloader(...params):void {
            _main.renderCompletePromise.callbackRemove(hidePreloader);
            _view.removeChild(_preloader.view);
            _preloader.cleanUp();
            _preloader = null;
        }

        private function showPreloader():void {
            _preloader = new AssetMovieClip('preloader');
            _preloader.assetData = _parent._assetLibrary.getPreloader(_parent._data.assetName);
            if(!_preloader.assetData.isRenderFinish){
                _preloader.assetData.completeRenderPromise.callbackRegister(playPreloader);
            } else {
                _preloader.gotoAndPlay(0);
            }
            _view.addChild(_preloader.view);
            _preloader.setVisible(_visible);
        }

        private function playPreloader():void {
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
            return _assetData && _assetData.isRenderFinish;
        }

        public function get finishRenderPromise():Promise {
            return _main.renderCompletePromise;
        }

        public function hitTest(globalX:int, globalY:int, checkContainer:Boolean = false):Boolean {
            if(_main.isRenderFinish) return DisplayUtils.hitTest(_view, globalX, globalY, checkContainer);
            else return true;
        }

        public function get bounds():Rect {
            return _main.isRenderFinish ?_main.bounds : _preloader.bounds;
        }

        public function init():void {
            _main = new AdvancedAssetMovieClip(_parent._data.assetName);
        }

        public function clear():void {
            if(_preloader){
                _preloader.cleanUp();
            }
            _main.cleanUp();
        }

        public function get boundsUpdatePromise():Promise {
            return _main.assetMovieClip.boundsUpdatePromise;
        }
    }
}
