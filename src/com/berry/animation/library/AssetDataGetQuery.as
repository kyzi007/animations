package com.berry.animation.library {
    import com.berry.animation.data.SourceTypeEnum;

    import org.dzyga.pool.IReusable;

    public class AssetDataGetQuery implements IReusable {

        public function AssetDataGetQuery() {
        }

        public static const CHECK_DUPLICATE_NONE:uint = 0;
        public static const CHECK_DUPLICATE_ONE_FRAME:uint = 1;
        public static const CHECK_DUPLICATE_ALL_FRAMES:uint = 2;
        private var _name:String;
        private var _sourceType:String;
        private var _wears:Object;
        private var _animation:String;
        private var _isFullAnimation:Boolean;
        private var _isAutoClear:Boolean = true;
        private var _checkDuplicateDataMode:uint;
        private var _isBitmapRendering:Boolean = true;
        private var _text:String = null;
        private var _asynchRender:Boolean = true;
        private var _step:uint = 1;
        private var _rotate:String = '';
        private var _position:String = '';
        private var _renderInTread:Boolean;
        
        public function get renderInTread ():Boolean
        {
        	return _renderInTread;
        }
        
        public function setRenderInTread (value:Boolean):AssetDataGetQuery
        {
        	_renderInTread = value;
        	return this;
        }

        public function reset():void {
            _rotate = '';
            _name = null;
            _animation = null;
            _asynchRender = true;
            _checkDuplicateDataMode = CHECK_DUPLICATE_NONE;
            _isAutoClear = true;
            _isBitmapRendering = true;
            _isFullAnimation = true;
            _sourceType = SourceTypeEnum.SOURCE_SWF;
            _step = 1;
            _text = null;
            _wears = null;
            _position = '';
        }

        public function setPosition(value:String):AssetDataGetQuery {
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

        public function setWears(value:Object):AssetDataGetQuery {
            _wears = value;
            return this;
        }

        public function toString():String {
            return "name=" + String(_name)
                    +",sourceType=" + String(_sourceType)
                    + ",animation=" + String(_animation)
                    + ",isFullAnimation=" + String(_isFullAnimation)
                    + ",isAutoClear=" + String(_isAutoClear)
                    + ",isBitmapRendering=" + String(_isBitmapRendering)
                    + ",text=" + String(_text)
                    + ",step=" + String(_step)
                    + ",rotate=" + String(_rotate)
                    + ",position=" + String(_position);
        }

        public function get position():String {
            return _position;
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

        public function get reflection():Class {
            return AssetDataGetQuery;
        }

        public function get rotate():String {
            return _rotate;
        }

        public function get step():uint {
            return _step;
        }

        public function get text():String {
            return _text;
        }

        public function get wears():Object {
            return _wears;
        }

        public function get sourceType():String {
            return _sourceType;
        }
    }
}
