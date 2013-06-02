package animation.library {
    import dzyga.events.EnterFrame;
    import dzyga.pool.Pool;

    import flash.display.Bitmap;
    import flash.display.DisplayObject;
    import flash.display.MovieClip;
    import flash.utils.Dictionary;

    import log.logServer.KLog;

    public class AssetLibrary {
        /**
         * @author kyzi007
         * хранилище анимаций
         * не предназначено для прямого использования - для этого существует конкретный класс (AssetLibrary) который выполняет специфические для игры действия
         */

        public static const nameDict:Dictionary = new Dictionary();
        private static var _collectionByName:Object = {};
        public static var _sourceByName:Object = {};
        // для вытаскивания дополнительных данных о анимации
        // так как клип все равно тут же дернется для рендеринга сохраняем сюда
        public static var _cachedMcByName:Object = {};
        private static var _cachedMcNameList : Object = {};

        /**
         * получение AssetData
         * если клип для рендеринга не загружен - инициализаирует загрузку, по загрузке / если клип в наличии - запускает рендеринг
         * обновлятся счетчик использований
         * @param query
         * @return
         */
        public static function getAssetData(query:AssetDataGetQuery):AssetData {
            var assetData:AssetData = findAnimation(query.name, query.animation, query.isFullAnimation, query.isAutoClear, query.step, query.rotate, query.position);

            if (!assetData) {
                if(query.preRender){
                    registerCachedAssetSourceName(query.name);
                }
                assetData = new AssetData(query);
                var source:* = getSourceClassByAssetName(query.name);
                /*if (!source) {
                    source = Library.instance.getClass(query.name);
                    if(source) {
                        registerAsset(query.name, source);
                    }
                }*/
                if (source) {
                    onAssetLoaded(source, [assetData]);
                } else {
                    SWFLibraryTemp.loadSource(
                            query.name,
                            query.url,
                            query.objectType,
                            function (data:*):void {
                                onAssetLoaded(data, [assetData]);
                            }
                    );
                }
                addData(assetData);
            } else {
                Pool.put(query);
            }

            if (assetData.isDestroyed) {
                assetData.restore(getSourceByAssetName(assetData.name));
            }

            return assetData;
        }

        public static function registerCachedAssetSourceName(name:String):void{
            _cachedMcNameList[name] = true;
        }

        public static function removeCachedAssetSource(name : String) : void {
            delete _cachedMcNameList[name];
            delete _cachedMcByName[name];
        }

        /**
         * ищем - не закеширована ли анимация
         * @param assetName
         * @param animation
         * @return AssetData
         * @param isFullAnimation
         * @param isAutoClear
         * @param step
         */
        public static function findAnimation(assetName:String, animation:String, isFullAnimation:Boolean, isAutoClear:Boolean, step:uint, rotate:String, position:String):AssetData {
            var collection:Object = _collectionByName[assetName];
            if (!collection) return null;

            for each (var assetData:AssetData in collection) {
                if (
                        assetData.name == assetName
                                && assetData.getQuery.animation == animation
                                && assetData.getQuery.isFullAnimation == isFullAnimation
                                && assetData.getQuery.isAutoClear == isAutoClear
                                && assetData.getQuery.step == step
                                && assetData.getQuery.rotate == rotate
                                && assetData.getQuery.position == position
                        ) {
                    return assetData;
                }
            }
            return null;
        }

        /**
         * получаем новый инстанс клипа для рендеринга
         * @param name
         * @return MovieClip
         */
        public static function getSourceByAssetName(name:String):DisplayObject {
            var clip:MovieClip;
            if(_cachedMcByName[name]){
                clip = _cachedMcByName[name];
                if(!_cachedMcNameList[name]){
                    delete _cachedMcByName[name];
                }
                return clip;
            }
            if (!_sourceByName[name]) {
                return null;
            } else {
                if (_sourceByName[name] is Bitmap) return _sourceByName[name];
                if (_sourceByName[name] is MovieClip) return _sourceByName[name];
                clip = new _sourceByName[name]();
                return clip;
            }
        }

        /**
         * умирают все анимации для ассета
         * @param assetName
         */
        public static function removeAllByName(assetName:String):void {
            var assetsByName:Object = _collectionByName[assetName];
            if (assetName) {
                for each (var assetData:AssetData in assetsByName) {
                    assetData.destroy();
                }
            }
            _collectionByName[assetName] = null;
            delete nameDict[assetData.name];
        }

        public static function registerAsset(name:String, data:*):void {
            _sourceByName[name] = data;

            if(data is MovieClip){
                AnimationLibrary.parseWyseClip(data, name);
            } else if(data is Class){
                _cachedMcByName[name] = new data();
                AnimationLibrary.parseWyseClip(_cachedMcByName[name] as MovieClip, name);
            }
        }

        /**
         * вычищаем коллекцию только для определенной анимации
         * @param assetData
         * @param force - если установлен удаляет данные вне зависимости от использования
         */
        public static function removeAssetData(assetData:AssetData, force:Boolean = false):void {
            if (assetData) {
                if (assetData.useCount < 1) {
                    if (force) {
                        remove(assetData);
                    } else {
                        CONFIG::debug {KLog.log('AssetLibarary : removeAssetData' + assetData.getQuery.toStringShot(), KLog.METHODS);}
                        EnterFrame.scheduleAction(10000 + 10000 * Math.random(), remove, null, assetData).name = "AssetLibarary:removeAssetData " + assetData.name;
                    }
                }
            }
        }

        public static function clearUnusedData():void {
            for (var itemName:String in _collectionByName) {
                var itemAnimations:Object = _collectionByName[itemName];
                if (itemAnimations) {
                    for (var animationName:String in itemAnimations) {
                        var data:AssetData = itemAnimations[animationName];
                        data.checkClean();
                    }
                }
            }
        }

        /**
         * добавляет анимацию
         * сохраняет имя ассета для последующих проверок
         * @param assetData
         */
        private static function addData(assetData:AssetData):void {
            if (!_collectionByName[assetData.name]) {
                _collectionByName[assetData.name] = new Vector.<AssetData>;
            }

            _collectionByName[assetData.name].push(assetData);
            nameDict[assetData.name] = true;
        }

        /**
         * кривая хрень для дубликата вызова onAssetLoaded
         * @param name
         * @return
         */
        private static function getSourceClassByAssetName(name:String):* {
            return _sourceByName[name];
        }

        /**
         * ассет загрузился / пошел запрос на ассет
         * @param data - класс ассета
         * @param params - [assetData]
         */
        private static function onAssetLoaded(data:*, params:Array):void {
            if (params && params[0]) {
                var assetData:AssetData = params[0];
                _sourceByName[assetData.name] = data;
                assetData.startRender(getSourceByAssetName(assetData.name)); // на каждый вызов создается инстанс клипа, после окончания рендера отмирает
                CONFIG::debug{ KLog.log('AssetLibarary : onAssetSWFLoaded' + assetData.getQuery.fullAnimationName, KLog.METHODS); }
            }

        }

        private static function remove(assetData:AssetData):void {
            if (assetData.useCount < 1) {
                assetData.destroy();

                if (_collectionByName[assetData.name]) {
                    delete _collectionByName[assetData.name][assetData.getQuery.animation];
                }

                for (var string:String in _collectionByName[assetData.name]) {
                    return;
                }
                // если нету больше использования типа ассета грохаем имя

                delete nameDict[assetData.name];
                delete _collectionByName[assetData.name];
            }
        }
    }
}
