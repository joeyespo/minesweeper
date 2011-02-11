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
			//FP.console.enable();
			
			//var s:Splash=new Splash();
            //FP.world.add(s);
            //s.start(on_splash_completed);
			
			// Set the initial world
			FP.world = new GameWorld();
		}
	}
}
