package com.berry.animation.library {
    public class AnimationsList {
        public static const FEED:String = 'feed';
        public static const WATER:String = 'water';
        public static const CLEAR:String = 'clear';
        public static const HARVEST:String = 'harvest';
        public static const EXPLORE:String = 'common';
        public static const BUILDING:String = 'building';
        public static const INTERACT:String = 'interact';
        public static const HATCHET:String = 'hatchet';
        public static const PICKAXE:String = 'pickaxe';
        public static const SHOVEL:String = 'shovel';
        public static const HAMMER:String = 'hammer';
        public static const FRIGHT:String = 'fright';
        public static const MAGIC_WOOD:String = 'magic_wood';
        public static const MAGIC_WOOD_FIGHT:String = 'magic_wood_fight';
        public static const IDLE:String = 'idle';
        public static const SHADOW:String = 'shadow';

        // main
        public static const SIDE_WALK:String = 'side_walk';

        // move
        public static const BACK_WALK:String = 'backward_walk';
        public static const FORWARD_WALK:String = 'forward_walk';
        public static const BACK_SIDE_WALK:String = 'backward_side_walk';
        public static const FORWARD_SIDE_WALK:String = 'forward_side_walk';
        /**
         * list of possible animations
         */

        // work
        public static const CHOP:String = 'chop';
        public static const MOVE:Array = [SIDE_WALK, BACK_WALK, FORWARD_WALK, BACK_SIDE_WALK, FORWARD_SIDE_WALK];

        public static function isMove(name:String):Boolean {
            switch (name) {
                case SIDE_WALK:
                case BACK_WALK:
                case FORWARD_WALK:
                case BACK_SIDE_WALK:
                case FORWARD_SIDE_WALK:
                    return true;
                default :
                    return false;
            }
        }

        public static function isComplexName(name:String):Boolean {
            switch (name) {
                case SIDE_WALK:
                case BACK_WALK:
                case FORWARD_WALK:
                case BACK_SIDE_WALK:
                case FORWARD_SIDE_WALK:
                case MAGIC_WOOD:
                case MAGIC_WOOD_FIGHT:
                    return true;
                default :
                    return false;
            }
        }
    }
}
