package com.berry.animation.library {
    import com.berry.animation.data.AnimationSettings;
    import com.berry.events.SimpleEventDispatcher;

    import flash.display.MovieClip;
    import flash.display.Sprite;
    import flash.net.SharedObject;
    import flash.utils.Dictionary;

    import log.logServer.KLog;

    import org.dzyga.events.Action;
    import org.dzyga.events.EnterFrame;
    import org.dzyga.events.IInstruct;
    import org.dzyga.events.Promise;
    import org.dzyga.events.Thread;
    import org.dzyga.geom.Rect;

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
        public var mc:MovieClip;
        public var frames:Vector.<AssetFrame> = new Vector.<AssetFrame>(); // чтобы не грузить запросами геттер
        private var _useCount:int = 0;
        private var _maxBounds:Rect = new Rect();
        private var _isRenderWork:Boolean = false;
        private var _isRenderFinish:Boolean = false;
        private var _isDestroyed:Boolean = false;
        private var _getQuery:AssetDataGetQuery;
        private var _renderAction:Action;
        private var _movies:Dictionary = new Dictionary();
        private var _isFalled:Boolean;
        public var completeRenderPromise:Promise = new Promise();

        public function finishRender():void {
            _isRenderWork = false;
            _isRenderFinish = true;
            _renderAction = null;
            nextByStack();
            update();

            if (AnimationSettings.saveMode) {

                if (!SharedObject.getLocal('midnight_').data['assets']) {
                    SharedObject.getLocal('midnight_').data['assets'] = {};
                }

                var framesForSave:Array = [];
                for (var i:int = 0; i < frames.length; i++) {
                    var frame:AssetFrame = frames[i];
                    framesForSave.push(frame.pack());
                }

                SharedObject.getLocal('midnight_').data['assets'][getQuery.toString()] = framesForSave;
                SharedObject.getLocal('midnight_').flush();
            }
        }

        public function unpackSavedFrames(value:Array):void {
            for (var i:int = 0; i < value.length; i++) {
                var frame:AssetFrame = new AssetFrame(0, 0, null);
                frame.unPack(value[i]);
                frames.push(frame);
            }
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
                /*if (_getQuery.asynchRender) {
                    _renderAction = EnterFrame.addAction(0, renderInstruct);
                    _renderAction.name = "AssetData:render "+name;
                } else if (_getQuery.renderInTread) {*/
                    _renderAction = EnterFrame.addThread(0, 0, renderInstruct);
                    _renderAction.name = "AssetData:render " + name;
                /*} else {
                    while (renderInstruct.execute() == false) {}
                    renderInstruct.finish();
                    renderInstruct = null;
                }*/
            } else {
                finishRender();
            }
        }

        public function update():void {
            //CONFIG::debug{ KLog.log("AssetData:update " + getQuery.fullAnimationName, KLog.METHODS);}
            updateMaxBounds();
            completeRenderPromise.resolve(this);
        }

        // не вычищаю из памяти инстансы

        private function nextByStack():void {
            _renderedAndLock[name] = false;
            if (_stack[name]) {
                var data:Array = _stack[name].shift();
                if (data) {
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

        public function set getQuery(value:AssetDataGetQuery):void {
            _getQuery = value;
        }

       /* public function get isBitmap():Boolean {
            return _getQuery.isBitmapRendering;
        }*/

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
                KLog.log("AssetData:destroy " + getQuery.toString(), KLog.METHODS);
            }
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
