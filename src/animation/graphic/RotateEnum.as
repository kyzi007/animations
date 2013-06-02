package animation.graphic {
    import umerkiCommon.enums.DynamicEnum;

    public class RotateEnum extends DynamicEnum {

        public function RotateEnum() {
            super([FLIP, NONE, BACK, CORNER, BACK_ROTATE, CORNER_ROTATE], String);
            setValue(NONE);
        }

        public static const NONE:String = '';
        public static const FLIP:String = '_rotate';
        public static const BACK:String = '_back';
        public static const CORNER:String = '_corner';
        public static const BACK_ROTATE:String = '_back_rotate';
        public static const CORNER_ROTATE:String = '_corner_rotate';

    }
}
