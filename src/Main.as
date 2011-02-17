package 
{
	import net.flashpunk.Engine;
	import net.flashpunk.FP;
	
	/**
	 * ...
	 * @author Joe Esposito
	 */
	public class Main extends Engine
	{
		public function Main():void
		{
			super(640, 480);
		}
		
		override public function init():void
		{
			// Set the initial world
			FP.world = new GameWorld();
		}
	}
}
