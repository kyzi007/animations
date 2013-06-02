package dzyga.pool {
	public interface IReusable {
		function reset():void;
		function get reflection():Class;
	}
}