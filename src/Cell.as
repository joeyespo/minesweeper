package  
{
	import flash.geom.Point;
	import flash.text.Font;
	import flash.text.FontStyle;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	import net.flashpunk.Entity;
	import net.flashpunk.Graphic;
	import net.flashpunk.graphics.Image;
	import net.flashpunk.utils.Input;
	import punk.ui.PunkButton;
	
	/**
	 * A cell in a field.
	 * @author Joe Esposito
	 */
	public class Cell extends PunkButton
	{
        // The text colors for cells, the index position represents the number of adjacent mines
        public static const Colors:Array = [
			0x000000,	// (Not used)
			0x0004FF,	// 1
			0x007000,	// 2
			0xFE0100,	// 3
			0x05006C,	// 4
			0x840800,	// 5
			0x008284,	// 6
			0x840084,	// 7
			0x000000,	// 8
		];
		public static const CellSize:int = 24;
		
		public static var FieldOffset:Point = new Point(34, 60);
		
		private var rowIndex:int;
		private var columnIndex:int;
		private var clickHandler:Function;
		
		private var adjacentMineCount:int = 0;
		private var isMine:Boolean = false;
		private var isFlagged:Boolean = false;
		private var isRevealed:Boolean = false;
		
		public function Cell(rowIndex:int, columnIndex:int, clickHandler:Function):void
		{
			super(columnIndex * CellSize + FieldOffset.x, rowIndex * CellSize + FieldOffset.y, CellSize, CellSize, "", onClick);
			
			this.rowIndex = rowIndex;
			this.columnIndex = columnIndex;
			this.clickHandler = clickHandler;
			
			normal = new Image(Assets.CELL_GRAPHIC);
			hover = new Image(Assets.CELL_OVER_GRAPHIC);
			down = new Image(Assets.CELL_DOWN_GRAPHIC);
		}
		
		private function onClick():void
		{
			clickHandler(this);
		}
		
		public function get RowIndex():int
		{
			return rowIndex;
		}
		
		public function get ColumnIndex():int
		{
			return columnIndex;
		}
		
		public function get AdjacentMineCount():int
		{
			return adjacentMineCount;
		}
		
		public function get IsMine():Boolean
		{
			return isMine;
		}
		public function set IsMine(value:Boolean):void
		{
			isMine = value;
		}
		
		public function get IsRevealed():Boolean
		{
			return isRevealed;
		}
		
		public function get IsFlagged():Boolean
		{
			return isMine;
		}
		public function set IsFlagged(value:Boolean):void
		{
			isFlagged = value;
		}
		
		public function IncreaseAdjacentMineCount():void
		{
			++adjacentMineCount;
		}
		
		public function Deactivate():void
		{
			callback = null;
			
			hover = normal;
			down = normal;
		}
		
		public function Reveal(byUser:Boolean = true):void
		{
			callback = null;
			isRevealed = true;
			
			if (isMine)
			{
				if (byUser)
					normal = new Image(Assets.EXPLODED_MINE_CELL_GRAPHIC);
				else
					normal = new Image(Assets.REVEALED_MINE_CELL_GRAPHIC);
			}
			else
			{
				if (adjacentMineCount > 0)
				{
					label.text = String(adjacentMineCount);
					label.color = Colors[adjacentMineCount];
				}
				normal = new Image(Assets.EMPTY_CELL_GRAPHIC);
			}
			hover = normal;
			down = normal;
		}
		
		public function Flag():void
		{
			// TODO: implement
		}
	}
}
