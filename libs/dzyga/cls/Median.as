/*
 Licensed under the MIT License

 Copyright (c) 2009-2012 Ivan Filimonov

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

package dzyga.cls {
    import dzyga.utils.ArrayUtils;

    /**
     * Utility class to simplify some statistical calculation for list of values, i.e. median, average value, etc.
     */
    public class Median {
        private var _values:Vector.<Number> = new <Number>[];

        /**
         * Current values collection
         */
        public function get values():Vector.<Number> {
            return this._values;
        }

        /**
         * Add value to collection.
         * @param {Number} value value to add to values collection
         * @return {Number} index for value in sorted values collection
         */
        public function add(value:Number):Number {
            var index:int = ArrayUtils.search(this._values, Median._sort, value);
            this._values.splice(index, 0, value);
            return index;
        }

        /**
         * Get the minimum value in current collection.
         */
        public function get min():Number {
            if (this._values.length) {
                return this._values[0];
            } else {
                return 0;
            }
        }

        /**
         * Get the maximum value in current collection.
         */
        public function get max():Number {
            var values:Vector.<Number> = this.values;
            var length:int = values.length;
            if (length) {
                return values[length-1];
            } else {
                return 0;
            }
        }

        /**
         * Length of values collection
         */
        public function get length():Number {
            return this.values.length;
        }

        /**
         * Sum of all values in current collection.
         */
        public function get sum():Number {
            var sum:Number = 0;
            for each (var i:Number in this.values) {
                sum += i;
            }
            return sum;
        }

        /**
         * Arithmetic mean of values in current collection.
         */
        public function get mean():Number {
            var length:Number = this.length;
            if (length) {
                return this.sum / length;
            } else {
                return 0;
            }
        }

        /**
         * Median for values in current collection.
         */
        public function get median():Number {
            var length:Number = this.length;
            if (length) {
                return this.values[int(length/2)];
            } else {
                return 0;
            }
        }

        /**
         * Empty current values collection.
         */
        public function reset():void {
            this._values.length = 0;
        }


        private static function _sort(a:Number, b:Number):Number {
            return a - b;
        }

    }
}
