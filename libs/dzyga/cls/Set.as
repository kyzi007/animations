package dzyga.cls {
    import dzyga.utils.ObjectUtils;

    import flash.utils.Dictionary;
    import flash.utils.Proxy;
    import flash.utils.flash_proxy;

    /**
     * mathematic set (many) methods
     */

    public class Set extends Proxy {
        protected var _values:Dictionary = new Dictionary();
        public function Set(iterable:*=null) {
            if (iterable) {
                this.update(iterable);
            }
        }

        public static function coerce(iterable:* = null, target:Set = null):Set {
            if (iterable is Set) {
                return iterable as Set;
            }
            if (ObjectUtils.isSimple(iterable)) {
                throw new ArgumentError('Expected any of Set, Array, Vector, Dictionary, Object type.');
            }
            var set:Set = target || new Set();
            var elem:*;
            if (iterable is Vector || iterable is Array) {
                for each (elem in iterable) {
                    set.add(elem);
                }
            } else {
                for (elem in iterable) {
                    set.add(elem);
                }
            }
            return set;
        }

        public function toArray():Array {
            var re:Array = ObjectUtils.keys(this._values);
            return re;
        }

        private var _valuesList:Array;
        private var _length:int = 0;
        public function get length():int {
            if (!this._valuesList) {
                this._valuesList = this.toArray();
                this._length = this._valuesList.length;
            }
            return this._length;
        }

        public function add(elem:*):void {
            this._values[elem] = true;
            this._valuesList = null;
        }

        public function discard(elem:*):void {
            delete this._values[elem];
            this._valuesList = null;
        }

        public function clear():void {
            ObjectUtils.clear(this._values);
            this._valuesList = null;
        }

        public function pop(elem:* = null):* {
            if (elem === null) {
                for (elem in this._values) {
                    this.discard(elem);
                    return elem;
                }
            } else {
                this.discard(elem);
                return(elem);
            }
        }

        public function find(elem:*):Boolean {
            return this._values[elem];
        }

        public function isSubSet(iterable:Object):Boolean {
            var argument:Set = Set.coerce(iterable);
            for each (var elem:* in this) {
                if (!argument.find(elem)) {
                    return false;
                }
            }
            return true;
        }

        public function isSuperSet(iterable:Object):Boolean {
            var argument:Set = Set.coerce(iterable);
            for each (var elem:* in argument) {
                if (!this.find(elem)) {
                    return false;
                }
            }
            return true;
        }

        public function clone():Set {
            return new Set(this._values);
        }

        public function update(iterable:Object):Set {
            var argument:Set = Set.coerce(iterable);
            for each (var elem:* in argument) {
                this.add(elem);
            }
            return this;
        }

        public function differenceUpdate(iterable:Object):Set {
            var argument:Set = Set.coerce(iterable);
            for each (var elem:* in argument) {
               this.discard(elem);
            }
            return this;
        }

        public function intersectionUpdate(iterable:Object):Set {
            var argument:Set = Set.coerce(iterable);
            for each (var elem:* in this) {
                if (!argument.find(elem)) {
                    this.discard(elem);
                }
            }
            return this;
        }

        public function union(iterable:Object):Set {
            var re:Set = this.clone();
            return re.update(iterable);
        }

        public function difference(iterable:Object):Set {
            var re:Set = this.clone();
            return re.differenceUpdate(iterable);
        }

        public function intersection(iterable:Object):Set {
            var re:Set = this.clone();
            return re.intersectionUpdate(iterable);
        }

        override flash_proxy function nextNameIndex(index:int):int {
            if (!this._valuesList) {
                this._valuesList = this.toArray();
            }
            if (index < this._valuesList.length) {
                return index + 1;
            } else {
                return 0;
            }
        }

        override flash_proxy function nextName(index:int):String {
            return String(index);
        }

        override flash_proxy function nextValue(index:int):* {
            return this._valuesList[index - 1];
        }

        public function toString():String {
            return '{' + this.toArray().join(', ') + '}';
        }
    }
}
