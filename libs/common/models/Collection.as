/**
 * Created by IntelliJ IDEA.
 * User: sunrize
 * Date: 21.11.11
 * Time: 22:49
 * To change this template use File | Settings | File Templates.
 */
package common.models {
    import dzyga.utils.StringUtils;

    import flash.errors.IllegalOperationError;

    import org.puremvc.as3.interfaces.IProxy;
    import org.puremvc.as3.patterns.proxy.Proxy;

    public class Collection extends Proxy {
        public function Collection(proxyName:String, data:Object) {
            super(proxyName, data);
        }

        public function getEntry(id:String):Object {
            return this.getData()[id];
        }

        protected function get modelClass():Class {
            throw new IllegalOperationError('modelClass not specified');
        }

        override public function setData(data:Object ):void {
            for (var id:String in this.data) {
                var proxy:IProxy = this.facade.retrieveProxy(id);
                if (proxy) {
                    this.facade.removeProxy(id);
                }
            }
            super.setData(data);
        }

        private static const ID_PATTERN_FIELD:String = 'ID_PATTERN';
        public function getProxy(id:String):IProxy {
            var cls:Class = this.modelClass;
            var proxyID:String;
            if (cls.hasOwnProperty(ID_PATTERN_FIELD)) {
                proxyID = StringUtils.format(cls[ID_PATTERN_FIELD], id);
            } else {
                proxyID = id;
            }
            var proxy:IProxy = this.facade.retrieveProxy(proxyID);
            if (proxy) {
                return proxy;
            } else {
                var data:Object = this.getEntry(id);
                if (data) {
                    proxy = new cls(data);
                    this.facade.registerProxy(proxy);
                    return proxy;
                } else {
                    return null;
                }
            }

        }

        private static const ID_FIELD:String = 'ID_PROP';
        private static const DEFAULT_ID_PROP:String = '_id';
        public function get _id_prop():String {
            var cls:Class = this.modelClass;
            if (cls.hasOwnProperty(ID_FIELD)) {
                return cls[ID_FIELD];
            }
            return DEFAULT_ID_PROP;
        }


        public function add(data:Object):void {
            var id:String = data[this._id_prop];
            if (!id) {
                throw new ArgumentError('Cannot find id field');
            }
            this.data[id] = data;
        }

        public function all():Object {
            var re:Object = {};
            for (var id:String in this.data) {
                re[id] = this.getProxy(id);
            }
            return re;
        }

        public function list():Array {
            var re:Array = [];
            for (var id:String in this.data) {
                re.push(this.getProxy(id));
            }
            return re;
        }

        public function sort(sorter:Function):Array {
            var re:Array = this.list();
            re.sort(sorter);
            return re;
        }

        public function filter(filter:Function, thisArg:* = null, ...args):Array {
            var re:Array = [];
            for (var id:String in this.data) {
                var proxy:IProxy = this.getProxy(id);
                var filterArgs:Array = [proxy].concat(args);
                if (filter.apply(thisArg, filterArgs)) {
                    re.push(proxy);
                }
            }
            return re;
        }

        public function search(filter:Function, thisArg:* = null, ...args):IProxy {
            for (var id:String in this.data) {
                var proxy:IProxy = this.getProxy(id);
                var filterArgs:Array = [proxy].concat(args);
                if (filter.apply(thisArg, filterArgs)) {
                    return proxy;
                }
            }
            return null;
        }

        public static function findInPath(obj:Object, ...keys):* {
            var res:* = obj;
            for (var i:int = 0; i < keys.length; i++) {
                var key:String = keys[i];
                res = res.hasOwnProperty(key) ? res[key] : null;
                if (res == null || res == undefined) return null;
            }
            return res;
        }

        public static function findClassInstance(obj:Object, classId:Class, ...keys):* {
            if(!obj){
                return null;
            }
            var res:* = obj;
            if (res is classId) return res;
            for (var i:int = 0; i < keys.length; i++) {
                var key:String = keys[i];
                res = res.hasOwnProperty(key) ? res[key] : null;
                if (res == null || res == undefined) return null;
                if (res is classId) return res;
            }
            return null;
        }
    }
}
