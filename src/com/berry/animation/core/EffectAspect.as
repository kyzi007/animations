package com.berry.animation.core {
    import com.berry.animation.library.AnimationModel;
    import com.berry.animation.library.AssetData;

    import flash.display.DisplayObject;
    import flash.display.Sprite;

    import log.logServer.KLog;

    import org.ColorMatrix;
    import org.dzyga.callbacks.Promise;
    import org.dzyga.display.DisplayUtils;
    import org.dzyga.geom.Rect;

    public class EffectAspect implements IAssetViewAspect {
        public function EffectAspect(parent:AssetView) {
            _parent = parent;
        }

        private var _parent:AssetView;
        private var _view:Sprite = new Sprite;
        private var _visible:Boolean;
        private var _effects:Array = [];
        private var _waitPlay:Boolean;
        private var _filter:ColorMatrix;

        public function play():void {
            var effect:AdvancedAssetMovieClip;
            for each (effect in _effects) {
                if(effect.assetMovieClip.view){
                    _view.removeChild(effect.assetMovieClip.view);
                }
                effect.clear();
            }
            if(!_visible || !_parent.data.animationModel){
                _waitPlay = true;
                return;
            }
            var effectModels:Object = _parent.animationLibrary.getAnimationEffects(_parent.assetName, _parent.data.animationModel.currentPart().fullName, _parent.data.stepFrame);
            for each (var animationModel:AnimationModel in effectModels) {
                effect = new AdvancedAssetMovieClip(_parent.assetName + 'effect');
                effect.assetLibrary = _parent.assetLibrary;
                effect.data = _parent.data;
                effect.fullAnimation = _filter ? false : _parent.data.effectMode;
                effect.loadOneFrameFirst = true;
                effect.playAnimationSet(animationModel);
                effect.setVisible(true);
                if (_filter) {
                    effect.applyFilter(_filter);
                }
                _effects.push(effect);
                _view.addChild(effect.assetMovieClip.view);
            }
        }

        public function setVisible(value:Boolean):void {
            _visible = value;
            for each (var effect:AdvancedAssetMovieClip in _effects) {
                effect.setVisible(value);
            }
            if(_waitPlay){
                play();
            }
        }

        public function get view():DisplayObject {
            return _view;
        }

        public function get isRendered():Boolean {
            CONFIG::debug{ KLog.log("EffectAspect : isRendered  "+ 'not work', KLog.CRITICAL); }
            return false;
        }

        public function get finishRenderPromise():Promise {
            CONFIG::debug{ KLog.log("EffectAspect : get finishRenderPromise  " + 'not work', KLog.CRITICAL); }
            return null;
        }

        public function hitTest(globalX:int, globalY:int, checkContainer:Boolean = false):Boolean {
            return DisplayUtils.hitTest(_view, globalX, globalY, checkContainer);
        }

        public function get bounds():Rect {
            CONFIG::debug{ KLog.log("EffectAspect : get bounds" + 'not work', KLog.CRITICAL); }
            return null;
        }

        public function init():void {
        }

        public function clear():void {
            for each (var effect:AdvancedAssetMovieClip in _effects) {
                effect.clear();
            }
        }

        public function get boundsUpdatePromise():Promise {return null;}

        public function set x(value:int):void {CONFIG::debug{ KLog.log("EffectAspect : set x  " + 'not work', KLog.CRITICAL); }}

        public function set y(value:int):void {CONFIG::debug{ KLog.log("EffectAspect : set y  " + 'not work', KLog.CRITICAL); }}

        public function applyFilter(value:ColorMatrix):void {
            _filter = value;
            play();
            /*for each (var effect:AdvancedAssetMovieClip in _effects) {
                effect.applyFilter(value);
                effect.fullAnimation = false;
            }*/
        }

        public function removeFilter():void {
            _filter = null;
            play();
        }

        public function set animationSpeed(value:Number):void {CONFIG::debug{ KLog.log("EffectAspect : animationSpeed  " + 'not work', KLog.CRITICAL); }}
    }
}
