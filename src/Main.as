package 
{
	import net.flashpunk.Engine;
	import net.flashpunk.FP;
	import splash.Splash;
	
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
			
			// Show splash screen
			//var s:Splash = new Splash();
            //FP.world.add(s);
            //s.start(onSplashCompleted);
			onSplashCompleted();
		}
		
		private function onSplashCompleted():void
		{
			// Set the initial world
			FP.world = new GameWorld();
		}
	}
}
