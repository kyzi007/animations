/**
 * ArrayUtils
 * A small set of array utilites
 *
 * @author		Ivan Filimonov
 * @version		0.2
 */


/*
Licensed under the MIT License

Copyright (c) 2009-2010 Ivan Filimonov

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/


package dzyga.utils {

    public final class ArrayUtils {
        private static function _convertToString(obj:Object, deep:Boolean):String {
            return obj.toString();
        }

        public static function repr(arr:Array, deep:Boolean = false):String {
            var mapper:*;
            var mapped:Array;
            if (deep) {
                mapped = ArrayUtils.map(arr, ObjectUtils.repr, null, true);
            } else {
                mapped = ArrayUtils.map(arr, 'toString');
            }
            return '[' + mapped.join(', ') + ']';
        }


		/**
		 * Addes one array to another. Like Array.concat, but without generating
		 * new array instances.
		 * @param arr1
		 * @param arr2
		 * @return
		 *
		 */
        public static function add(arr1:Array, arr2:Array):Array {
            for each (var i:* in arr2) {
                arr1.push(i);
            }
            return arr1;
        }

		/**
		 * Finds the place for the new element in sorted array using binary
		 * search algorithm
		 * @param arr
		 * @param func
		 * @return
		 *
         * @param el
		 */
		public static function search(arr:*, func:Function, el:*):int {
			var length:int = arr.length;
			if (length == 0) {
				return 0;
			}

			var cmp:int = func.call(null, el, arr[length - 1]);
			if (cmp > 0) {
				return length;
			}

			var i:int = 0;
			var j:int = length;
			while (i + 1 < j) {
				var middle:int = int(i + (j - i) / 2);
				cmp = func.call(null, el, arr[middle]);
				if (cmp < 0) {
					j = middle;
				}
				else {
					i = middle;
				}
			}
			if (func.call(null, el, arr[i]) < 0) {
				return i;
			}
			return j;
		}

        public static function map(arr:Array, callback:*, thisArg:* = null, ...args):Array {
            var re:Array = [];
            var m:Function;
            for each (var v:* in arr) {
                if (callback is String) {
                    re.push((v[callback] as Function).apply(thisArg, args));
                } else {
                    var argsArray:Array = [v].concat(args);
                    re.push(callback.apply(thisArg, argsArray));
                }
            }
            return re;
        }

        public static function filter(arr:Array, callback:*, thisArg:* = null, ...args):Array {
            var re:Array = [];
            for each (var v:* in arr) {
                var filtered:*;
                if (callback is String) {
                    filtered = (v[callback] as Function).apply(thisArg || v, args);
                } else {
                    var argsArray:Array = [v].concat(args);
                    filtered = (callback as Function).apply(thisArg, argsArray);
                }
                if (filtered) {
                    re.push(v);
                }
            }
            return re;
        }

        public static function exists(arr:Array, el:*):Boolean {
            return arr.indexOf(el) != -1;
        }
    }
}
