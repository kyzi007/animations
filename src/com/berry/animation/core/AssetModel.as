package com.berry.animation.core {
    import com.berry.animation.data.RotateEnum;
    import com.berry.animation.data.SourceTypeEnum;
    import com.berry.animation.library.AnimationModel;
    import com.berry.animation.library.AssetDataGetQuery;

    import org.dzyga.pool.Pool;

    public class AssetModel {
        public var cachedList:Array;
        public function AssetModel() {
            sourceType.setValue(SourceTypeEnum.SOURCE_SWF);
        }

        public var id:String;
        public var name:String;
        public var animationModel:AnimationModel;
        public var cache:Boolean;
        public var x:Number;
        public var y:Number;
        public var vectorMode:Boolean;
        public var sourceType:SourceTypeEnum = new SourceTypeEnum();
        public var text:String;
        public var visible:Boolean;
        private var _rotation:RotateEnum = GameObjectView.ROTATE_NONE;
        private var _animation:String;
        private var _stepFrame:int = 1;
        private var _effectMode:Boolean = false;
        private var _stepFrameUpdated:Boolean;
        private var _animationUpdated:Boolean;
        private var _effectModeUpdated:Boolean;
        private var _rotationUpdated:Boolean;

        public function cleanUp():void {

        }

        public function getQuery(animation:String, rotateOn:Boolean = true, checkDuplicate:int = AssetDataGetQuery.CHECK_DUPLICATE_NONE):AssetDataGetQuery {
            var query:AssetDataGetQuery = Pool.get(AssetDataGetQuery) as AssetDataGetQuery;
            query.setAssetName(name)
                    .setSourceType(sourceType.value)
                    .setAnimationName(animation)
                    .setIsCheckDuplicateData(checkDuplicate)
                    .setIsFullAnimation(true)
                    .setIsBitmapRendering(!vectorMode)
                    .setText(text)
                    .setStep(_stepFrame)
                    .setRotate(rotateOn ? _rotation.value : RotateEnum.NONE)
                    .setIsAutoClear(!getCache(animation))
            return query;
        }

        private function getCache(animation:String):Boolean {
            if(!cachedList) {
                return cache;
            }
            return cachedList.indexOf(animation) != -1 ? true : cache;
        }

        public function clearUpdates():void {
            _stepFrameUpdated = false;
            _animationUpdated = false;
            _effectModeUpdated = false;
            _rotationUpdated = false;
        }

        public function get stepFrame():int {
            return _stepFrame;
        }

        public function set stepFrame(value:int):void {
            if (_stepFrame != value) {
                _stepFrameUpdated = true;
                _stepFrame = value;
            }
        }

        public function get animation():String {
            return _animation;
        }

        public function set animation(value:String):void {
            if (_animation != value) {
                _animationUpdated = true;
                _animation = value;
            }
        }

        public function get effectMode():Boolean {
            return _effectMode;
        }

        public function set effectMode(value:Boolean):void {
            /*if (_effectMode != value) {
                _effectModeUpdated = true;
                _effectMode = value;
            }*/
        }

        public function get rotation():RotateEnum {
            return _rotation;
        }

        public function set rotation(value:RotateEnum):void {
            if (_rotation.value != value.value) {
                _rotationUpdated = true;
                _rotation = value;
            }
        }
    }
}
