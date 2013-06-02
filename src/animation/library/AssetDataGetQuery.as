package animation.library {
    import animation.graphic.AssetSprite;
    import animation.graphic.RotateEnum;

    import dzyga.pool.IReusable;

    import umerkiCommon.enums.Enum;

    public class AssetDataGetQuery implements IReusable {

        public function AssetDataGetQuery() {
        }

        public static const CHECK_DUPLICATE_NONE:uint = 0;
        public static const CHECK_DUPLICATE_ONE_FRAME:uint = 1;
        public static const CHECK_DUPLICATE_ALL_FRAMES:uint = 2;
        private var _name:String;
        private var _objectType:String;
        private var _sourceType:String = AssetSprite.SOURCE_SWF;
        private var _wears:Object;
        private var _animation:String = '';
        private var _isFullAnimation:Boolean = false;
        private var _isAutoClear:Boolean = true;
        private var _url:String;
        private var _checkDuplicateDataMode:uint = CHECK_DUPLICATE_NONE;
        private var _preRender:Boolean;
        private var _isBitmapRendering:Boolean;
        private var _text:String = null;
        private var _asynchRender:Boolean = true;
        private var _step:uint = 1;
        private var _rotate:String = '';

        public static function getUrl(objectType:String, assetName:String, assetFormat:String):String {
            if (assetFormat == AssetSprite.SOURCE_SWF) {
                return  "" + assetName + ".swf";
            }
            return  "" + assetName + ".png";
        }

        public function reset():void {
            _rotate = '';
            _name = null;
            _animation = null;
            _asynchRender = true;
            _checkDuplicateDataMode = CHECK_DUPLICATE_NONE;
            _url = null;
            _isAutoClear = true;
            _isBitmapRendering = true;
            _isFullAnimation = true;
            _objectType = null;
            _preRender = false;
            _sourceType = AssetSprite.SOURCE_SWF;
            _step = 1;
            _text = null;
            _wears = null;
            _position = '';
        }
        
        private var _position:String = '';
        
        public function get position ():String
        {
        	return _position;
        }
        
        public function setPosition (value:String):AssetDataGetQuery
        {
        	_position = value;
        	return this;
        }

        /**
         * степ / анимация
         * @param value
         * @return
         */
        public function setAnimationName(value:String):AssetDataGetQuery {
            _animation = value;
            return this;
        }

        public function setAssetName(value:String):AssetDataGetQuery {
            _name = value;
            return this;
        }

        public function setAsynchRender(value:Boolean):AssetDataGetQuery {
            _asynchRender = value;
            return this;
        }

        /**
         * устанавливается в Generator для того чтобы не чистить основные анимации персонажей
         * @param value - если = false (по умолчанию true) при неиспользовании не уничтожается
         * @return
         */
        public function setIsAutoClear(value:Boolean):AssetDataGetQuery {
            _isAutoClear = value;
            return this;
        }

        public function setIsBitmapRendering(value:Boolean):AssetDataGetQuery {
            _isBitmapRendering = value;
            return this;
        }

        /**
         * устанавливает тип проверки - нет (CHECK_DUPLICATE_NONE), только для предыдущего кадра (CHECK_DUPLICATE_ONE_FRAME), для всех кадров (CHECK_DUPLICATE_ALL_FRAMES)
         * @param value - по умолчанию CHECK_DUPLICATE_NONE
         * @return
         */
        public function setIsCheckDuplicateData(value:uint):AssetDataGetQuery {
            _checkDuplicateDataMode = value;
            return this;
        }

        /**
         * для генерации одного кадра в "экономных" обьектах
         * @param value
         * @return
         */
        public function setIsFullAnimation(value:Boolean):AssetDataGetQuery {
            _isFullAnimation = value;
            return this;
        }

        public function setObjectType(value:String):AssetDataGetQuery {
            _objectType = value;
            return this;
        }

        public function setPreRender(value:Boolean):AssetDataGetQuery {
            _preRender = value;
            return this;
        }

        public function setRotate(value:String):AssetDataGetQuery {
            _rotate = value;
            return this;
        }

        public function setSourceType(value:String):AssetDataGetQuery {
            _sourceType = value;
            return this;
        }

        public function setStep(value:uint):AssetDataGetQuery {
            _step = value;
            return this;
        }

        public function setText(value:String):AssetDataGetQuery {
            _text = value;
            return this;
        }

        public function setUrl(value:String):AssetDataGetQuery {
            _url = value;
            return this;
        }

        public function setWears(value:Object):AssetDataGetQuery {
            _wears = value;
            return this;
        }

        public function toString():String {
            return "AssetDataGetQuery{_name=" + String(_name) + ",_objectType=" + String(_objectType) + ",_animation=" + String(_animation) + ",_step=" + String(_step) + "}";
        }

        public function toStringShot():String {
            return "AssetGenerateConfig{_name=" + String(_name) + ",fullName=" + String(fullAnimationName) + "}";
        }

        public function get animation():String {
            return _animation;
        }

        public function get asynchRender():Boolean {
            return _asynchRender;
        }

        public function get checkDuplicateDataMode():uint {
            return _checkDuplicateDataMode;
        }

        public function get fullAnimationName():String {
            return _name + '_' + (_isFullAnimation ? 'anim' : 'one frame') + '__' + animation;
        }

        public function get isAutoClear():Boolean {
            return _isAutoClear;
        }

        public function get isBitmapRendering():Boolean {
            return _isBitmapRendering;
        }

        public function get isFullAnimation():Boolean {
            return _isFullAnimation;
        }

        public function get name():String {
            return _name;
        }

        public function get objectType():String {
            return _objectType;
        }

        public function get preRender():Boolean {
            return _preRender;
        }

        public function get reflection():Class {
            return AssetDataGetQuery;
        }

        public function get rotate():String {
            return _rotate;
        }

        /*public function toString():String {
         return "AssetGenerateConfig{_name=" + String(_name) + ",_type=" + String(_objectType) + ",_sourceType=" + String(_sourceType) + ",_wears=" + String(_wears) + ",_animation=" + String(_animation) + ",_isFullAnimation=" + String(_isFullAnimation) + ",_isAutoClear=" + String(_isAutoClear) + ",fullName=" + String(fullAnimationName) + ",_checkDuplicateDataMode=" + String(_checkDuplicateDataMode) + "}";
         }*/

        public function get shotName():String {return _name.split('_')[0];}

        public function get step():uint {
            return _step;
        }

        public function get text():String {
            return _text;
        }

        public function get url():String {
            return _url ? _url : getUrl(_objectType, _name, _sourceType);
        }

        public function get wears():Object {
            return _wears;
        }
    }
}
