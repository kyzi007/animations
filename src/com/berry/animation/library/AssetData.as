package com.berry.animation.library {
    import com.berry.animation.data.AnimationSettings;
    import com.berry.animation.draw.BaseDrawInstruct;

    import flash.display.Bitmap;

    import flash.display.DisplayObject;

    import flash.display.MovieClip;
    import flash.display.Sprite;
    import flash.net.SharedObject;
    import flash.utils.Dictionary;

    import log.logServer.KLog;

    import org.dzyga.callbacks.Promise;
    import org.dzyga.eventloop.LoopTask;
    import org.dzyga.events.Action;
    import org.dzyga.events.EnterFrame;
    import org.dzyga.events.IInstruct;
    import org.dzyga.events.Thread;
    import org.dzyga.geom.Rect;

    public class AssetData {
        public function AssetData (query:AssetDataGetQuery = null) {
            /*CONFIG::debug{
             if (query) KLog.log("AssetData:AssetData " + query.fullAnimationName, KLog.CREATE);
             }*/
            _getQuery = query;
        }

        public var memory:int;
        public var mc:MovieClip;
        public var frames:Vector.<AssetFrame> = new Vector.<AssetFrame>(); // чтобы не грузить запросами геттер
        public var completeRenderPromise:Promise = new Promise();
        public var renderInitParams:Array;
        public var renderClass:Class;
        public var sourceCallback:Function;
        private var _isRenderWork:Boolean = false;
        private var _renderAction:Action;
        private var _movies:Dictionary = new Dictionary();
        private static const _STACK:Object = {};

        public function finishRender ():void {
            _isRenderWork = false;
            _isRenderFinish = true;
            _renderAction = null;
            update();
            next();
        }

        private function next ():void {
            var index:int = _STACK[name].indexOf(this);
            _STACK[name].splice(index, 1);
            //trace('next', name, _getQuery.animation);
            if (_STACK[name].length) {
                var data:AssetData = _STACK[name].shift();
                data._fromStack = true;
                data.startRender();
            }
        }

        private var _fromStack:Boolean = false;

        public function falledRender ():void {
            _isRenderWork = false;
            _isRenderFinish = true;
            _renderAction = null;
            _isFalled = true;
            update();
            next();
        }

        public function startRender (...args):void {
            if (_isRenderWork || frames.length) return;
            if (!_STACK[name]) {
                _STACK[name] = [];
                _STACK[name].push(this);
            } else {
                var index:int = _STACK[name].indexOf(this);
                if (index == -1) {
                    _STACK[name].push(this);
                }
            }
            if (_STACK[name].length > 1 && !_fromStack) {
                return;
            }
            _isRenderWork = true;

            var source:DisplayObject = sourceCallback(name);

            var renderInstruct:BaseDrawInstruct = new renderClass(this, getQuery, source);
            renderInstruct.init(renderInitParams);
            if (!_isFalled) {
                _renderAction = EnterFrame.addThread(_getQuery.renderPriority, 0, renderInstruct);
                _renderAction.name = "AssetData:render " + name;
            }
        }

        public function update ():void {
            //CONFIG::debug{ KLog.log("AssetData:update " + getQuery.fullAnimationName, KLog.METHODS);}
            updateMaxBounds();
            completeRenderPromise.resolve(this);
        }

        /**
         * после перерисовки берем максимальные границы анимаций для hittest в рендерере
         */
        private function updateMaxBounds ():void {
            if (_isDestroyed) return;
            _maxBounds.clear();
            for each (var assetFrame:AssetFrame in frames) {
                _maxBounds.x = Math.min(assetFrame.x, _maxBounds.x);
                _maxBounds.y = Math.min(assetFrame.y, _maxBounds.y);
                _maxBounds.width = Math.max(assetFrame.bitmap.width, _maxBounds.width);
                _maxBounds.height = Math.max(assetFrame.bitmap.height, _maxBounds.height);
            }
        }

        private var _useCount:int = 0;

        public function get useCount ():int {
            return _useCount;
        }

        // TODO: move

        public function set useCount (value:int):void {
            _useCount = value;
        }

        private var _maxBounds:Rect = new Rect();

        // не вычищаю из памяти инстансы

        public function get maxBounds ():Rect {
            return _maxBounds;
        }

        private var _isRenderFinish:Boolean = false;

        public function get isRenderFinish ():Boolean {
            return _isRenderFinish;
        }

        private var _isDestroyed:Boolean = false;


        public function get isDestroyed ():Boolean {
            return _isDestroyed;
        }

        private var _getQuery:AssetDataGetQuery;

        public function get getQuery ():AssetDataGetQuery {
            return _getQuery;
        }

        public function set getQuery (value:AssetDataGetQuery):void {
            _getQuery = value;
        }

        private var _isFalled:Boolean;

        public function get isFalled ():Boolean {
            return _isFalled;
        }

        public function get name ():String {
            return _getQuery.name;
        }

        internal function destroy ():void {
            CONFIG::debug{
                KLog.log("AssetData:destroy " + getQuery.toString(), KLog.METHODS);
            }
            //trace("AssetData:destroy " + getQuery.toString());
            _isDestroyed = true;

            for each (var assetFrame:AssetFrame in frames) {
                assetFrame.destroy();
            }

            _isRenderFinish = false;
            _isRenderWork = false;
            completeRenderPromise.clear();

            for each (var sprite:Sprite in _movies) {
                if (sprite.parent) {
                    sprite.parent.removeChild(sprite)
                }
            }
            _movies = new Dictionary();

            EnterFrame.removeThread(_renderAction as Thread);
            _renderAction = null;
        }

    }
}
