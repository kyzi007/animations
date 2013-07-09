package com.berry.animation.logic {

    import com.berry.animation.AnimationModel;
    import com.berry.animation.AnimationSettings;
    import com.berry.animation.AssetTypes;
    import com.berry.animation.event.AssetDataEvents;
    import com.berry.animation.graphic.AssetSprite;
    import com.berry.animation.graphic.RotateEnum;
    import com.berry.animation.library.AnimationLibrary;
    import com.berry.animation.library.AssetData;
    import com.berry.animation.library.AssetDataGetQuery;
    import com.berry.animation.library.AssetLibrary;

    import log.logServer.KLog;

    import org.dzyga.pool.Pool;

    public class Generator {
        /**
         * Создает либо целую анимацию либо один кадр, одномоментно у предметов могут существовать до двух анимаций / кадров. Как только новая анимация / кадр отрендерится - старая попытается самоубится.
         * для персонажей создает пачку анимаций
         *
         * Для получения ассета из библиотеки необходимо создать обьект с данными и передать его (ну не хочу я делать дофигище параметров в методе)
         * Первый идентичный инстанс конфига (пока идентичность считается только по полям name, animation, isFullAnimation, isAutoClear) уйдет в AssetData, остальные умрут.
         *
         * в самых больших картах таких обьектов за сессию будет создаваться не более 5тыс за игровую сессию, в маленьких - несколько сотен, так что кеширование не делаю
         */
        public function Generator (assetName:String, itemType:String, isBitmapGenerate:Boolean = true, text:String = null) {
            _assetName = assetName;
            _assetType = itemType;
            _isBitmapGenerate = isBitmapGenerate;
            _text = text;

            _animations = {};
            _oneFrame = {};
            _isWorker = _assetType == AssetTypes.WORKER || _assetType == AssetTypes.NPC;
            _isTile = _assetType == AssetTypes.TILE;
        }

        public var rotationLogicOn:Boolean = true;
        private var _preloader:AssetData;

        // asset data
        private var _animations:Object;
        private var _oneFrame:Object;

        // asset config
        private var _assetName:String;
        private var _assetType:String;
        private var _isTile:Boolean = false;
        private var _isWorker:Boolean = false;
        private var _text:String;
        private var _isBitmapGenerate:Boolean = true;
        private var _lastAnimation:String = '';
        private var _lastFrame:String = '';
        private var _allLoadCallback:Function;
        private var _preloadList:Array;
        private var _step:uint = 1;
        private var _rotateEnum:RotateEnum = new RotateEnum();
        private var _baseAnimations:Array;

        /**
         * попытка уничтожить все созданное
         */
        public function cleanUp ():void {
            CONFIG::debug{
                KLog.log("AssetCollection:cleanUp " + _assetName, KLog.METHODS);
            }

            var key:String;
            for (key  in _animations) {
                AssetData(_animations[key]).useCount--;
                delete _animations[key];
            }

            for (key in _oneFrame) {
                AssetData(_oneFrame[key]).useCount--;
                delete _oneFrame[key];
            }

            _preloadList = null;
        }

        /**
         * запрашивает анимацию степа предмета / движения персонажа
         * @param name
         * @return
         * @param cache
         */
        public function getAnimation (name:String, cache:Boolean = false):AssetData {
            var assetData:AssetData = _animations[name + _step + _rotateEnum.value];
            if (!assetData || assetData.isDestroyed) {

                var query:AssetDataGetQuery = Pool.get(AssetDataGetQuery) as AssetDataGetQuery;
                query.setAssetName(_assetName)
                    .setObjectType(_assetType)
                    .setSourceType(_assetType == AssetTypes.TILE ? AssetSprite.SOURCE_PNG : AssetSprite.SOURCE_SWF)
                    .setAnimationName(name)
                    .setIsCheckDuplicateData(_isWorker ? AssetDataGetQuery.CHECK_DUPLICATE_NONE : AssetDataGetQuery.CHECK_DUPLICATE_ONE_FRAME)
                    .setIsFullAnimation(true)
                    .setIsBitmapRendering(_isBitmapGenerate)
                    .setText(_text)
                    .setPreRender(cache)
                    .setStep(_step)
                    .setRotate(rotationLogicOn ? _rotateEnum.value : RotateEnum.NONE)
                    .setIsAutoClear(false);

                assetData = AssetLibrary.getAssetData(query);
                _animations[name + _step + _rotateEnum.value] = assetData;

                if (!_isWorker && _lastAnimation != '' && name != _lastAnimation) {
                    // только одна анимация или кадр

                    assetData.dispatcher.setEventListener(true, AssetDataEvents.COMPLETE_RENDER, function (e:*):void {
                        clearAnimation(_lastAnimation);
                        _lastAnimation = name;
                    });
                }

                assetData.useCount++;
            }
            return assetData;
        }

        /**
         * создает первый кадр степа
         * для воркеров не выполняется
         * @param name
         * @return
         */
        public function getFirstFrame (name:String):AssetData {
            var assetData:AssetData = _oneFrame[name + _step + _rotateEnum.value];

            if (!assetData || assetData.isDestroyed) {

                var query:AssetDataGetQuery = Pool.get(AssetDataGetQuery) as AssetDataGetQuery;
                query.setAssetName(_assetName)
                    .setObjectType(_assetType).setSourceType(_assetType == AssetTypes.TILE ? AssetSprite.SOURCE_PNG : AssetSprite.SOURCE_SWF)
                    .setAnimationName(name)
                    .setText(_text)
                    .setStep(_step)
                    .setRotate(rotationLogicOn ? _rotateEnum.value : RotateEnum.NONE)
                    .setIsBitmapRendering(_isBitmapGenerate)
                    .setIsFullAnimation(false);

                assetData = AssetLibrary.getAssetData(query);
                _oneFrame[name + _step + _rotateEnum.value ] = assetData;

                if (name != _lastFrame) {
                    // только одна анимация или кадр
                    if (_lastFrame) {
                        assetData.dispatcher.setEventListener(true, AssetDataEvents.COMPLETE_RENDER, function (e:*):void {
                            clearFrame(_lastFrame);
                            _lastFrame = name;
                        });
                    }
                    _lastFrame = name;
                }

                if (_lastAnimation != '') {
                    assetData.dispatcher.setEventListener(true, AssetDataEvents.COMPLETE_RENDER, function (e:*):void {
                        clearAnimation(_lastAnimation);
                        _lastAnimation = '';
                    });
                }
                assetData.useCount++;
            }
            else {
                if (_lastAnimation != '') {
                    clearAnimation(_lastAnimation);
                    _lastAnimation = '';
                }
            }
            return assetData;
        }

        /**
         * при создании запускает рендеринг для основных анимаций
         * @return
         */
            // TODO запускать все стейты для врагов
        public function getPreCacheQueryList ():Array {
            if (_isBitmapGenerate && !AnimationSettings.previewMode) {
                if (_baseAnimations) {
                    // перебираем все части анимации которые должны быть закешены при старте
                    var preloadFullList:Array = [];
                    _preloadList = [];
                    var names:Array = [];
                    for each (var animationShotName:String in _baseAnimations) {
                        if (AnimationLibrary.hasAnimationQuery(_assetName, animationShotName)) {
                            var animationList:AnimationModel = AnimationLibrary.getAnimationQueryInstance(_assetName, animationShotName);
                            while (!animationList.isListEnd) {
                                preloadFullList.push(animationList.fullPartAnimationName);
                                animationList.nextPreset();
                            }
                        }
                    }

                    for (var i:int = 0; i < preloadFullList.length; i++) {
                        var assetData:AssetData = _animations[preloadFullList[i]];
                        if (!assetData || assetData.isDestroyed) {
                            names.push(preloadFullList[i]);
                        }
                    }
                }
            }

            for each (var name:String in names) {
                var query:AssetDataGetQuery = Pool.get(AssetDataGetQuery) as AssetDataGetQuery;
                query.setAssetName(_assetName)
                    .setObjectType(_assetType)
                    .setSourceType(AssetTypes.TILE ? AssetSprite.SOURCE_PNG : AssetSprite.SOURCE_PNG)
                    .setAnimationName(name)
                    .setIsCheckDuplicateData(_isWorker ? AssetDataGetQuery.CHECK_DUPLICATE_NONE : AssetDataGetQuery.CHECK_DUPLICATE_ONE_FRAME)
                    .setIsFullAnimation(true)
                    .setIsBitmapRendering(_isBitmapGenerate)
                    .setStep(_step)
                    .setRotate(rotationLogicOn ? _rotateEnum.value : RotateEnum.NONE)
                    .setIsAutoClear(false);
                _preloadList.push(query);
            }

            return _preloadList;
        }

        public function removeAllLoadCallbacks ():void {
            _allLoadCallback = null;
        }

        public function setAllLoadCallback (value:Function):Generator {
            if (_preloadList.length == 0) {
                value();
            } else {
                _allLoadCallback = value;
            }
            return this;
        }

        public function setStep (value:uint):Generator {
            _step = value;
            return this;
        }

        public function setRotate (value:String):void {
            if (_rotateEnum.value == value) return;
            _rotateEnum.setValue(value);
            cleanUp();
        }

        private function clearAnimation (name:String):void {
            if (_animations[name + _step]) {
                AssetData(_animations[name + _step]).useCount--;
                delete _animations[name + _step];
            }
        }

        private function clearFrame (name:String):void {
            if (_oneFrame[name + _step]) {
                AssetData(_oneFrame[name + _step]).useCount--;
                delete _oneFrame[name + _step];
            }
        }

        internal function get isTile ():Boolean {
            return _isTile;
        }

        public function get isWorker ():Boolean {
            return _isWorker;
        }

        public function get step ():uint {
            return _step;
        }

        public function get rotate ():String {
            return _rotateEnum.value;
        }

        public function set baseAnimations (baseAnimations:Array):void {
            _baseAnimations = baseAnimations;
        }
    }
}
