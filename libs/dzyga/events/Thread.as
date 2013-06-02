package dzyga.events {
    public class Thread extends Action {
        public var threads:int=0;
        public function Thread(
            priority:int=0, threads:int=0,
            action:Function=null, thisObject:*=null, ...args) {
            this.threads = threads;
            super(priority, action, thisObject, args);
        }
        
        /*override public function reset():void {
            this.threads = 0;
            super.reset();
        }*/
    }
}
