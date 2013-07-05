package animation.library {
    import animation.AssetTypes;
    import animation.event.AssetDataEvents;

    import dzyga.events.Action;
    import dzyga.events.EnterFrame;
    import dzyga.events.Thread;
    import dzyga.geom.Rect;

    import flash.display.DisplayObject;
    import flash.display.MovieClip;
    import flash.display.Sprite;
    import flash.utils.Dictionary;

    import log.logServer.KLog;

    import umerkiCommon.evens.SimpleEventDispatcher;

    public class AssetData {

        public function AssetData(query:AssetDataGetQuery = null) {
            CONFIG::debug{
                if (query) KLog.log("AssetData:AssetData " + query.fullAnimationName, KLog.CREATE);
            }
            _getQuery = query;
        }

        public var frames:Vector.<AssetFrame> = new Vector.<AssetFrame>(); // чтобы не грузить запросами геттер
        private var _useCount:int = 0;
        private var _maxBounds:Rect = new Rect();
        private var _isRenderWork:Boolean = false;
        private var _isRenderFinish:Boolean = false;
        private var _isDestroyed:Boolean = false;
        private var _getQuery:AssetDataGetQuery;
        private var _renderAction:Action;
        private var _movies:Dictionary = new Dictionary();
        private static var _renderSelectFunction:Function = defaultSelectFunction;
        private var _isFalled : Boolean;
        public var dispatcher:SimpleEventDispatcher = new SimpleEventDispatcher();


        /**
         * Запускается после смены уровня - если ассет все еще не нужен то удаляем его, игнорируя отключенный isAutoClear
         */
        public function checkClean():void {
            if (_getQuery.objectType != AssetTypes.OBSTACLE) {
                if (_useCount < 1) {
                    AssetLibrary.removeAssetData(this, true);
                }
            }
        }

        public function finishRender():void {
            _isRenderWork = false;
            _isRenderFinish = true;
            _renderAction = null;
            update();
            nextByStack();
        }

        public function falledRender() : void {
            _isRenderWork = false;
            _isRenderFinish = true;
            _renderAction = null;
            _isFalled = true;
            update();
            nextByStack();
        }

        private function nextByStack():void {
            _renderedAndLock[name] = false;
            if(_stack[name]){
                var data:Array = _stack[name].shift();
                AssetData(data[0]).startRender(data[1]);
                if(_stack[name].length == 0) _stack[name] = null;
            }
        }

        public function getMovie(parent:*):MovieClip {
            if (!_movies[parent]) {
                var movie:MovieClip = AssetLibrary.getSourceByAssetName(name) as MovieClip;
                _movies[parent] = movie.getChildByName(_getQuery.animation);
            }

            return _movies[parent];
        }

        public function restore(source:DisplayObject):void {
            _isDestroyed = false;
            startRender(source);
        }

        /**
         * можно перегрузить логику выбора рендера без наследований
         * @param fun (getQuery:AssetDataGetQuery, source:DisplayObject, data:AssetData)
         */
        public static function setRenderSelectLogic(fun:Function):void
        {
            _renderSelectFunction = fun;
        }

        private static function defaultSelectFunction(getQuery:AssetDataGetQuery, source:DisplayObject, data:AssetData):BaseDrawInstruct{
            var instruct:BaseDrawInstruct;
            switch (getQuery.objectType) {
                case AssetTypes.WORKER:
                case AssetTypes.NPC:
                case AssetTypes.ITEM:
                case AssetTypes.OBSTACLE:
                    instruct = new WyseDrawInstruct(data, getQuery, source as MovieClip);
                    break;
                case AssetTypes.TILE:
                    instruct = new TileDrawInstruct(data, getQuery, source);
                    break;
            }
            return instruct;
        }

        private static var _renderedAndLock:Object = {};
        private static var _stack:Object = {};

        public function startRender(source:DisplayObject):void {
            if (_isRenderWork) return;

            if(_renderedAndLock[name]){
                if(!_stack[name]){
                    _stack[name] = [];
                }
                _stack[name].push([this, source]);
                return;
            }

            _renderedAndLock[name] = true;

            _isRenderWork = true;
            if (_getQuery.isBitmapRendering) {
                var instruct:BaseDrawInstruct = _renderSelectFunction(_getQuery, source, this);
                if (_getQuery.asynchRender) {
                    _renderAction = EnterFrame.addThread(-100, 0, instruct);
                    _renderAction.name = "AssetData:startRender";
                } else {
                    while (instruct.execute() == false) {}
                    instruct.finish();
                    instruct = null;
                }
            } else {
                if (_getQuery.objectType == AssetTypes.TILE || _getQuery.objectType == AssetTypes.ITEM || _getQuery.objectType == AssetTypes.OBSTACLE) {
                    throw new Error('vector not supported from ' + _getQuery.objectType);
                }
                finishRender();
            }
        }

        // не вычищаю из памяти инстансы

        public function update():void {

            CONFIG::debug{ KLog.log("AssetData:update " + getQuery.fullAnimationName, KLog.METHODS);}

            updateMaxBounds();
            dispatcher.dispatchEvent(AssetDataEvents.COMPLETE_RENDER);
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

        public function get isLoaded():Boolean {
            return AssetLibrary.isLoad(name);
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

            if (_useCount < 1 && _getQuery.isAutoClear) {
                AssetLibrary.removeAssetData(this);
            }
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


        public function get isFalled() : Boolean {
            return _isFalled;
        }
    }
}
