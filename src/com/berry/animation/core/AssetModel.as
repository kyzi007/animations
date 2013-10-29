package com.berry.animation.core {
    import com.berry.animation.data.RotateEnum;
    import com.berry.animation.data.SourceTypeEnum;
    import com.berry.animation.library.AnimationPart;
    import com.berry.animation.library.AnimationSequenceData;
    import com.berry.animation.library.AssetDataGetQuery;

    import org.dzyga.pool.Pool;

    public class AssetModel {
        public var priority:int = 10;

        public function AssetModel() {
            sourceType.setValue(SourceTypeEnum.SOURCE_SWF);
        }

        public var id:String;
        public var assetName:String;

        public var text:String;
        public var x:Number;
        public var y:Number;

        public var cache:Boolean;

        public var cachedList:Array;
        public var renderInTread:Boolean;

        public var animationModel:AnimationSequenceData;
        public var sourceType:SourceTypeEnum = new SourceTypeEnum();

        private var _rotation:RotateEnum = new RotateEnum(RotateEnum.NONE);

        private var _stepFrame:int = 1;
        private var _effectMode:Boolean = true;
        private var _animation:String;

        public function cleanUp():void {

        }

        public function getQuery(animationPart:AnimationPart, rotateOn:Boolean = true, checkDuplicate:int = 0):AssetDataGetQuery {
            var query:AssetDataGetQuery = Pool.get(AssetDataGetQuery) as AssetDataGetQuery;
            query.setAssetName(assetName)
                    .setSourceType(sourceType.value)
                    .setAnimationName(animationPart.fullName)
                    .setIsCheckDuplicateData(checkDuplicate)
                    .setIsFullAnimation(true)
                    .setText(text)
                    .setStep(_stepFrame)
                    .setRotate(rotateOn ? _rotation.value : RotateEnum.NONE)
                    .setIsAutoClear(!getCache(animation))
                    .setRenderPriority(priority)
            if (!animationPart.isRotateSupport(query.rotate)) {
                query.setRotate(RotateEnum.NONE);
            }

            return query;
        }

        private function getCache(animation:String):Boolean {
            if (!cachedList) {
                return cache;
            }
            return cachedList.indexOf(animation) != -1 ? true : cache;
        }

        public function get stepFrame():int {
            return _stepFrame;
        }

        public function set stepFrame(value:int):void {
            if (_stepFrame != value) {
                _stepFrame = value;
            }
        }

        public function get animation():String {
            return _animation;
        }

        public function set animation(value:String):void {
            if (_animation != value) {
                _animation = value;
            }
        }

        public function get effectMode():Boolean {
            return _effectMode;
        }

        public function set effectMode(value:Boolean):void {
            if (_effectMode != value) {
                _effectMode = value;
            }
        }

        public function get rotation():String {
            return _rotation.value;
        }

        public function set rotation(value:String):void {
            if (_rotation.value != value) {
                _rotation.setValue(value);
            }
        }
    }
}
