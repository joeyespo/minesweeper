package ui
{
	import net.flashpunk.Entity;
	import net.flashpunk.FP;
	import net.flashpunk.graphics.Text;
	
	/**
	 * ...
	 * @author Joe Esposito
	 */
	public class Notice extends Entity
	{
		protected var text:Text;
		
		public function Notice(message:String, color:int, size:int = 72):void
		{
			Text.size = size;
			text = new Text(message);
			text.color = color;
			
			x = (FP.width - text.width) / 2;
			y = (FP.height - text.height) / 2;
			graphic = text;
		}
	}
}
