package ui
{
	import net.flashpunk.FP;
	import net.flashpunk.graphics.Text;
	import ui.Notice;
	
	/**
	 * ...
	 * @author Joe Esposito
	 */
	public class WinNotice extends Notice
	{
		private var velocity:Number;
		private var ground:int;
		private var isAnimating:Boolean;
		
		public function WinNotice():void
		{
			super("You Win!", 0x33AA33, 128);
			
			ground = (FP.height - Text.size) / 2;
			
			isAnimating = true;
			y = -Text.size;
			velocity = 20;
		}
		
		override public function update():void 
		{
			if (isAnimating)
			{
				velocity += 2;
				y += velocity;
				
				if (y >= ground)
				{
					y -= velocity;
					velocity /= -1.5;
					
					if (Math.abs(velocity) < 0.1)
					{
						velocity = 0;
						isAnimating = false;
					}
				}
			}
			
			super.update();
		}
	}
}
