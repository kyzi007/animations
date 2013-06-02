/**
 * StringUtils
 * A small set of string utilites
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
	public final class StringUtils {
		private static const SF_VAR:RegExp = /\{([^:{}]*)(:[^{}]*)?\}/g;
		private static const SF_FLOAT:RegExp = /^:(\+?)(\d*)(?:\.(\d+))?f$/;
		private static const SF_INT:RegExp = /^:(\+?)(\d*)d$/;
		private static const SF_STRING:RegExp = /^:(\-?)(\d*)s$/;
		private static const SF_CHECK_INT:RegExp = /^\d+$/;

        private static var sf_index:int;
        private static var sf_args:Array;
        private static function stringFormat(val:String, name:String, fmt:String, ...args):String {
            var value:*;
            var result:String;
            var prop:Object;
            if (name) {
                var parts:Array = name.split('.');
                var key:String = parts[0];
                if (key) {
                    if (StringUtils.SF_CHECK_INT.test(key)) {
                        value = StringUtils.sf_args[int(key)]
                    }
                    else {
                        value = StringUtils.sf_args[0][key];
                    }
                }
                else {
                    value = StringUtils.sf_args[StringUtils.sf_index++];
                }
                if (parts.length > 1) {
                    for each (key in parts) {
                        value = value[key];
                    }
                }
            }
            else {
                value = StringUtils.sf_args[StringUtils.sf_index++];
            }
            if (fmt) {
                switch(fmt.substr(-1)) {
                    case 'd':
                        prop = StringUtils.SF_INT.exec(fmt);
                        if (!prop) {
                            throw "Wrong format '" + fmt + "'";
                        }
                        result = StringUtils.numFormat(value, prop[1], prop[2], 0);
                        break;
                    case 'f':
                        prop = StringUtils.SF_FLOAT.exec(fmt);
                        if (!prop) {
                            throw "Wrong format '" + fmt + "'";
                        }
                        result =StringUtils.numFormat(value, prop[1], prop[2], prop[3]);
                        break;
                    case 's':
                        prop = StringUtils.SF_STRING.exec(fmt);
                        if (!prop) {
                            throw "Wrong format '" + fmt + "'";
                        }
                        if (prop[2]) {
                            if(prop[1]) {
                                result = StringUtils.fillright(value, prop[2]);
                            }
                            else {
                                result = StringUtils.fillleft(value, prop[2]);
                            }
                        } else {
                            result = value;
                        }
                        break;
                    case 'r':
                        result = value.toString();
                        break;
                    default:
                        throw "Wrong format '" + fmt + "'";
                }
            }
            else {
                result = value;
            }
            return result;

        }

        private static const NF_PLUS:String = '+';
        private static const NF_MINUS:String = '-';
        private static const NF_ZERO:String = '0';
        private static const NF_DOT:String = '.';
        private static function numFormat(value:Number, sign:String, len:String, prec:int):String {
            var result:String = value.toFixed(prec);
            var length:int = int(len);
			if (prec <= 0 && result.charAt(result.length - 1) == StringUtils.NF_DOT) {
				result = result.substr(0, result.length - 1);
			}
            if (length && len.charAt(0) == StringUtils.NF_ZERO) {
                if (value >= 0) {
                    if (sign) {
                        result = StringUtils.NF_PLUS +
                            StringUtils.fillleft(result, length-1, StringUtils.NF_ZERO);
                    }
                    else {
                        result =
                            StringUtils.fillleft(result, length, StringUtils.NF_ZERO);
                    }
                }
                else {
                    result = StringUtils.NF_MINUS +
                        StringUtils.fillleft(result.substr(1), length-1, StringUtils.NF_ZERO);
                }
            }
            else {
                if (sign && value >= 0) {
                    result = StringUtils.NF_PLUS + result;
                }
                result = fillleft(result, length);
            }
            return result;
        }

        public static function format(pattern:String, ...args):String {
            StringUtils.sf_index = 0;
            StringUtils.sf_args = args;
            var result:String = pattern.replace(StringUtils.SF_VAR, StringUtils.stringFormat);
            StringUtils.sf_args = null;
            return result;
        }

		public static function formatArray(pattern:String, arguments:Array):String {
			sf_index = 0;
			sf_args = arguments;
			var result:String = pattern.replace(StringUtils.SF_VAR, StringUtils.stringFormat);
			sf_args = null;
			return result;
		}

        public static function startswith(str:String, prefix:String):Boolean {
            return (str.substr(0, prefix.length) == prefix);
        }

        public static function endswith(str:String, suffix:String):Boolean {
            return (str.substr(-suffix.length) == suffix);
        }

        public static function fillleft(str:String, len:int, fillchar:String=' '):String {
            var length:int = str.length;
            if (length < len) {
                for (var i:int = len - length; i > 0; i--) {
                    str = fillchar + str;
                }
            }
            return str;
        }

        public static function fillright(str:String, len:int, fillchar:String=' '):String {
            var length:int = str.length;
            if (length < len) {
                for (var i:int = len - length; i > 0; i--) {
                    str = str + fillchar;
                }
            }
            return str;
        }

        private static const TRIM_CHECK:RegExp = /(^\s+)|(\s+$)|(\r)/g;
        public static function trim(str:String):String {
            return str.replace(StringUtils.TRIM_CHECK, '');
        }

        public static function random(length:int=5):String {
            var ret:String = Math.random().toFixed(length + 2);
            return ret.substr(2, length);
        }

        private static const TEMPLATE_INTERPOLATE:RegExp = /\{\{\s*(.+?)\s*\}\}/g;
        private static const UNDEFINED_CONTEXT:String = '***';
        private static var _templateContext:Object;
        public static function template(template:String, context:Object):String {
            StringUtils._templateContext = context;
            return template.replace(TEMPLATE_INTERPOLATE, StringUtils._processTemplate);
        }

        private static function _processTemplate(subj:String, key:String, ... args):String {
            var context:Object = StringUtils._templateContext;
            if (context.hasOwnProperty(key)) {
                return context[key];
            }
            else {
                return UNDEFINED_CONTEXT;
            }
        }
	}
}