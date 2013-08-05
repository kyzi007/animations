package com.berry.animation.data {
    import com.berry.enums.Enum;

    public class SourceTypeEnum extends Enum {

        public function SourceTypeEnum(defValue:String = SOURCE_SWF) {
            super([SOURCE_PNG, SOURCE_SWF], String);
            setValue(defValue);
        }

        public static const SOURCE_SWF:String = 'swf';
        public static const SOURCE_PNG:String = 'png';
    }
}
