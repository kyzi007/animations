package dzyga.events {
    import dzyga.pool.Pool;
    import dzyga.utils.ArrayUtils;

    public class Queue {
        public var queue:Vector.<Action> = new <Action>[];
        
        public function addAction(priority:int, func:*, thisObject:*=null, ...args):Action {
            
            var action:Action = new Action(); //Pool.get(Action) as Action;
            action.priority = priority;
            action.action = func;
            action.thisObject = thisObject;
            action.args = args;
            
            this.put(action);
            return action;
        }
        
        public function put(action:Action):int {
            var index:int = ArrayUtils.search(this.queue, Queue.sort, action);
            this.queue.splice(index, 0, action);
            return index;
        }
        
        public function pop(action:Action, keep:Boolean=false):void {
            if (action) {
                var index:int = this.queue.indexOf(action);
                if (index != -1) {
                    this.queue.splice(index, 1);
                    if (index < this._pointer) {
                        this._pointer--;
                    }
                    
                    /*if (!keep) {
                        Pool.put(action);                    
                    }*/
                }
            }
        }
        
        public function clear():void {
            for each (var action:Action in this.queue) {
                Pool.put(action);
            }
            this.queue.length = 0;
        }
        
        private var _pointer:int;
        public function run():void {
            this._pointer = 0;
            while (this._pointer < this.queue.length) {
                this.queue[this._pointer++].run();
            }
        }
        
        public function get length():int {
            return this.queue.length;
        }
        
        public static function sort(act1:Action, act2:Action):int {
            if (act1.priority > act2.priority) return 1;
            if (act2.priority > act1.priority) return -1;
            return 0;
            
        }
        
        public static function shuffle(act1:Action, act2:Action):int {
            if (act1.priority > act2.priority) return -1;
            if (act2.priority > act1.priority) return 1;
            return Math.round(Math.random() * 2 - 1);
        }
        
        
        
    }
}
