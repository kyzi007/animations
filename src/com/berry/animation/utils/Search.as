package com.berry.animation.utils {

    public class Search {
        /**
         *
         * @param data
         * @param prototype
         * @param conditionFunction
         * @param hasOwnPropertyList
         * @return
         */
        public static function findClassInstance(data:Object, prototype:Class, conditionFunction:Function, ...hasOwnPropertyList):* {
            if (!data) {
                return null;
            }
            var res:* = data;
            if (res is prototype && (conditionFunction == null || conditionFunction(res))) return res;
            for (var i:int = 0; i < hasOwnPropertyList.length; i++) {
                var key:String = hasOwnPropertyList[i];
                res = res.hasOwnProperty(key) ? res[key] : null;
                if (res == null || res == undefined) return null;
                if (res is prototype && (conditionFunction == null || conditionFunction(res))) return res;
            }
            return null;
        }
    }
}
