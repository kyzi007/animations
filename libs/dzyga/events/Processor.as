package dzyga.events {
    

	public class Processor implements IProcessor {
	
        private var _active:Boolean = false;
        public function get active():Boolean {
            return this._active;
        }
        
        public function set active(value:Boolean):void {
            this._active = value;
        }

		
        private var _onComplete:Queue = new Queue();
        public function get onComplete():Queue {
            return this._onComplete;
        }
        
        private var _onError:Queue = new Queue();
        public function get onError():Queue {
            return this._onError;
        }


		public function exec():void {
			this.active = true;
		}
		
		public function complete():void {
			this.active = false;
			this.onComplete.run();
		}
		
		public function error():void {
			this.active = false;
			this.onError.run();
		}
		
		public function cleanUp():void {
			this.active = false;
			this.onComplete.clear();
			this.onError.clear();
		}

	}
}