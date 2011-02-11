package  
{
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.text.Font;
	import flash.text.TextFormat;
	import net.flashpunk.graphics.Image;
	import net.flashpunk.graphics.Text;
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
		
		private static var EmptyCellGraphics:Array = CreateNumberedCells();
		private static var CellGraphic:Image = new Image(Assets.CELL_GRAPHIC);
		private static var CellHoverGraphic:Image = new Image(Assets.CELL_OVER_GRAPHIC);
		private static var CellDownGraphic:Image = new Image(Assets.CELL_DOWN_GRAPHIC);
		private static var ExplodedMineCellGraphic:Image = new Image(Assets.EXPLODED_MINE_CELL_GRAPHIC);
		private static var RevealedMineCellGraphic:Image = new Image(Assets.REVEALED_MINE_CELL_GRAPHIC);
		
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
			normal = CellGraphic;
			hover = CellHoverGraphic;
			down = CellDownGraphic;
			
			this.rowIndex = rowIndex;
			this.columnIndex = columnIndex;
			this.clickHandler = clickHandler;
		}
		
		private static function CreateNumberedCells():Array
		{
			var emptyCellGraphics:Array = [];
			for (var index:int = 0; index <= 8; ++index)
				emptyCellGraphics[index] = CreateNumberedCell(index);
			return emptyCellGraphics;
		}
		
		/**
		 * Creates a new empty cell image with the specified number 
		 * @param number The number to draw on the image.
		 * @return The image with the associated number drawn on it.
		 */
		private static function CreateNumberedCell(number:int):Image
		{
			if (number == 0)
				return new Image(Assets.EMPTY_CELL_GRAPHIC);
			
			var emptyCell:Image = new Image(Assets.EMPTY_CELL_GRAPHIC);
			var cellWithText:BitmapData = new BitmapData(CellSize, CellSize, false, 0xFFFFFF);
			Text.font = "default";
			var textImage:Text = new Text(String(number), 6, 3, CellSize, CellSize);
			// Lighten the text slightly, giving it a more pastellish look
			textImage.alpha = .8;
			// Adjustment for the font being used, make the "1" be centered with the other numbers
			if (number == 1)
				++textImage.x;
			// Use the appropriate color, as defined above
			textImage.color = Colors[number];
			
			emptyCell.render(cellWithText, new Point(0, 0), new Point(0, 0));
			textImage.render(cellWithText, new Point(0, 0), new Point(0, 0));
			
			return new Image(cellWithText);
		}
		
		private function onClick():void
		{
			if (clickHandler != null)
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
		
		/**
		 * Deactivates the cell so it no longer responds to the player.
		 */
		public function Deactivate():void
		{
			callback = null;
			
			hover = normal;
			down = normal;
		}
		
		/**
		 * Reveals the cell's contents.
		 * @param byPlayer Whether or not the player caused the revealing.
		 */
		public function Reveal(byPlayer:Boolean = true):void
		{
			if (isRevealed)
				return;
			
			callback = null;
			isRevealed = true;
			
			if (isMine)
			{
				normal = byPlayer
					? ExplodedMineCellGraphic
					: RevealedMineCellGraphic;
			}
			else
			{
				normal = EmptyCellGraphics[adjacentMineCount];
			}
			hover = normal;
			down = normal;
		}
		
		/**
		 * Puts a flag on the cell.
		 */
		public function Flag():void
		{
			// TODO: implement
		}
	}
}
