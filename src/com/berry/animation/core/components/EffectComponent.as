package com.berry.animation.core.components {
    import com.berry.animation.core.*;
    import com.berry.animation.core.view.ComplexMoveAssetCanvas;
    import com.berry.animation.library.AnimationModel;
    import com.berry.animation.library.AssetData;

    import flash.display.DisplayObject;
    import flash.display.Sprite;

    import log.logServer.KLog;

    import org.ColorMatrix;
    import org.dzyga.callbacks.Promise;
    import org.dzyga.display.DisplayUtils;
    import org.dzyga.geom.Rect;

    public class EffectComponent implements IAssetViewComponent {
        public function EffectComponent(parent:AssetView) {
            _parent = parent;
        }

        private var _parent:AssetView;
        private var _view:Sprite = new Sprite;
        private var _effects:Array = [];
        private var _waitPlay:Boolean;
        private var _filter:ColorMatrix;
        private var _lock:Boolean;
        private var _smoothing:Boolean;

        public function set smoothing(value:Boolean):void {
            _smoothing = value;
            updateSmoothing();
        }

        private function updateSmoothing():void {
            var effect:ComplexMoveAssetCanvas;
            for each (effect in _effects) {
                effect.smoothing = _smoothing;
            }
        }
        public function play():void {
            var effect:ComplexMoveAssetCanvas;
            for each (effect in _effects) {
                if (effect.parent) {
                    _view.removeChild(effect);
                }
                effect.clear();
            }
            if (_lock || !_parent.data.animationModel) {
                _waitPlay = true;
                return;
            }
            var effectModels:Object = _parent.animationLibrary.getAnimationEffects(_parent.assetName, _parent.data.animationModel.currentPart().fullName, _parent.data.stepFrame);
            for each (var animationModel:AnimationModel in effectModels) {
                effect = new ComplexMoveAssetCanvas(_parent.assetName + 'effect');
                effect.assetLibrary = _parent.assetLibrary;
                effect.data = _parent.data;
                effect.fullAnimation = _filter ? false : _parent.data.effectMode;
                effect.loadOneFrameFirst = true;
                effect.playAnimationSet(animationModel);
                effect.renderPriority = 300;
                effect.drawPriority = 200;
                if (_filter) {
                    effect.applyFilter(_filter);
                }
                effect.smoothing = _smoothing;
                _effects.push(effect);
                _view.addChild(effect);
            }
        }

        public function renderAndDrawLock():void {
            _lock = true;
            for each (var effect:ComplexMoveAssetCanvas in _effects) {
                effect.drawLock();
            }
        }

        public function renderAndDrawUnLock():void {
            _lock = false;
            for each (var effect:ComplexMoveAssetCanvas in _effects) {
                effect.drawUnLock();
            }
            if (_waitPlay) {
                _waitPlay = false;
                play();
            }
        }

        public function get view():DisplayObject {
            return _view;
        }

        public function get isRendered():Boolean {
            CONFIG::debug{ KLog.log("EffectAspect : isRendered  " + 'not work', KLog.CRITICAL); }
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
            for each (var effect:ComplexMoveAssetCanvas in _effects) {
                effect.clear();
            }
        }

        public function get boundsUpdatePromise():Promise {return null;}

        public function set x(value:int):void {CONFIG::debug{ KLog.log("EffectAspect : set x  " + 'not work', KLog.CRITICAL); }}

        public function set y(value:int):void {CONFIG::debug{ KLog.log("EffectAspect : set y  " + 'not work', KLog.CRITICAL); }}

        public function applyFilter(value:ColorMatrix):void {
            _filter = value;
            play();
        }

        public function removeFilter():void {
            _filter = null;
            play();
        }

        public function set animationSpeed(value:Number):void {CONFIG::debug{ KLog.log("EffectAspect : animationSpeed  " + 'not work', KLog.CRITICAL); }}
    }
}
