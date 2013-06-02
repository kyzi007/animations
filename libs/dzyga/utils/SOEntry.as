package dzyga.utils {
    public final class SOEntry {
        public var name:String;
        public var id:String;
        public var time:Date;
        
        [Transient]
        public var data:*;
                
        public function SOEntry() {
        }
    }
}