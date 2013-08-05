package com.berry.animation.library {
    import flash.display.MovieClip;
    import flash.display.Sprite;
    import flash.utils.Dictionary;

    import log.logServer.KLog;

    import org.dzyga.events.Action;
    import org.dzyga.events.EnterFrame;
    import org.dzyga.events.IInstruct;
    import org.dzyga.events.Thread;
    import org.dzyga.geom.Rect;

    import umerkiCommon.evens.SimpleEventDispatcher;

    ;

    public class AssetData {
        public function AssetData(query:AssetDataGetQuery = null) {
            /*CONFIG::debug{
             if (query) KLog.log("AssetData:AssetData " + query.fullAnimationName, KLog.CREATE);
             }*/
            _getQuery = query;
        }

        private static var _renderedAndLock:Object = {};
        private static var _stack:Object = {};
        public var sourceClass:Class;
        public var frames:Vector.<AssetFrame> = new Vector.<AssetFrame>(); // чтобы не грузить запросами геттер
        public var dispatcher:SimpleEventDispatcher = new SimpleEventDispatcher();
        private var _useCount:int = 0;
        private var _maxBounds:Rect = new Rect();
        private var _isRenderWork:Boolean = false;
        private var _isRenderFinish:Boolean = false;
        private var _isDestroyed:Boolean = false;
        private var _getQuery:AssetDataGetQuery;
        private var _renderAction:Action;
        private var _movies:Dictionary = new Dictionary();
        private var _isFalled:Boolean;

        public function getMovie():MovieClip {
            var clip:MovieClip = new sourceClass()[getQuery.animation];
            clip.parent.removeChild(clip);
            clip.cacheAsBitmap = true;
            return clip;
        }

        public function finishRender():void {
            _isRenderWork = false;
            _isRenderFinish = true;
            _renderAction = null;
            nextByStack();
            update();
        }

        public function falledRender():void {
            _isRenderWork = false;
            _isRenderFinish = true;
            _renderAction = null;
            _isFalled = true;
            nextByStack();
            update();
        }

        public function startRender(renderInstruct:IInstruct):void {
            if (_isRenderWork) return;

            if (_renderedAndLock[name]) {
                if (!_stack[name]) {
                    _stack[name] = [];
                }
                _stack[name].push([this, renderInstruct]);
                return;
            }

            _renderedAndLock[name] = true;

            renderInstruct.init()
            _isRenderWork = true;
            if (_getQuery.isBitmapRendering) {
                if (_getQuery.asynchRender) {
                    _renderAction = EnterFrame.addThread(-100, 0, renderInstruct);
                    _renderAction.name = "AssetData:startRender";
                } else {
                    while (renderInstruct.execute() == false) {}
                    renderInstruct.finish();
                    renderInstruct = null;
                }
            } else {
                finishRender();
            }
        }

        public function update():void {
            //CONFIG::debug{ KLog.log("AssetData:update " + getQuery.fullAnimationName, KLog.METHODS);}
            updateMaxBounds();
            dispatcher.dispatchEvent(AssetDataEvents.COMPLETE_RENDER, this);
        }

        // не вычищаю из памяти инстансы

        private function nextByStack():void {
            _renderedAndLock[name] = false;
            if (_stack[name]) {
                var data:Array = _stack[name].shift();
                if(data){
                    AssetData(data[0]).startRender(data[1]);
                }
                if (_stack[name] && _stack[name].length == 0) delete _stack[name];
            }
        }

        /**
         * после перерисовки берем максимальные границы анимаций для hittest в рендерере
         */
        private function updateMaxBounds():void {
            if (_isDestroyed) return;
            _maxBounds.clear();
            for each (var assetFrame:AssetFrame in frames) {
                _maxBounds.x = Math.min(assetFrame.x, _maxBounds.x);
                _maxBounds.y = Math.min(assetFrame.y, _maxBounds.y);
                _maxBounds.width = Math.max(assetFrame.bitmap.width, _maxBounds.width);
                _maxBounds.height = Math.max(assetFrame.bitmap.height, _maxBounds.height);
            }
        }

        public function get getQuery():AssetDataGetQuery {return _getQuery;}

        public function get isBitmap():Boolean {
            return _getQuery.isBitmapRendering;
        }

        public function get isDestroyed():Boolean {
            return _isDestroyed;
        }

        public function get isRenderFinish():Boolean {
            return _isRenderFinish;
        }

        public function get maxBounds():Rect {
            return _maxBounds;
        }

        public function get name():String {
            return _getQuery.name;
        }

        public function get useCount():int {
            return _useCount;
        }

        public function set useCount(value:int):void {
            _useCount = value;
        }

        public function get isFalled():Boolean {
            return _isFalled;
        }

        internal function destroy():void {
            CONFIG::debug{
                KLog.log("AssetData:destroy " + getQuery.fullAnimationName, KLog.METHODS);
            }
            _isDestroyed = true;

            for each (var assetFrame:AssetFrame in frames) {
                assetFrame.destroy();
            }

            _isRenderFinish = false;
            _isRenderWork = false;
            dispatcher.clearAllCallbacks();

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
