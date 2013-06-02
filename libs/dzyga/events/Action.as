package dzyga.events {
    import dzyga.pool.IReusable;

    public class Action implements IReusable{
        public var priority     : int;
        public var action       : *;
        public var thisObject   : *;
        public var args         : Array;
        public var name         : String;
        public var instruct     : IInstruct;

        public function Action(priority : int = 0, action : Function = null, thisObject : * = null, ...args) {
            this.priority   = priority;
            this.action     = action;
            this.thisObject = thisObject;
            this.args       = args;
        }

        public function run() : * {
            if (this.instruct) {
                var finish : Boolean = this.instruct.execute();
                if (finish) {
                    this.instruct.finish();
                    if (this is Thread) {
                        EnterFrame.removeThread(this as Thread);
                    } else {
                        EnterFrame.removeAction(this);
                    }
                    instruct = null;
                }
                return finish;
            } else if (this.action) {
                return this.action.apply(this.thisObject, this.args);
            }
        }

        public function get reflection():Class {
            return Action;
        }

        public function reset():void {
            this.priority   = 0;
            this.action     = null;
            this.thisObject = null;
            this.args       = null;
            this.instruct   = null;
            this.name       = null;
        }
        
        public function toString():String {
            return "<Action: " + this.priority + ">";
        }
    }
}
