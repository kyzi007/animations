package dzyga.events {
    public interface IProcessor {
        function get onComplete():Queue;
        function get onError():Queue;
        function get active():Boolean;
        
        function exec():void;
        function cleanUp():void;
    }
}