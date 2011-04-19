package  
{
	import flash.display.BitmapData;
	import flash.filters.ConvolutionFilter;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.text.Font;
	import flash.text.TextFormat;
	import net.flashpunk.FP;
	import net.flashpunk.graphics.Image;
	import net.flashpunk.graphics.Text;
	import net.flashpunk.tweens.motion.LinearMotion;
	import punk.ui.PunkButton;
	
	/**
	 * A cell in a field.
	 * @author Joe Esposito
	 */
	public class Cell extends PunkButton
	{
        /**
         * The text colors for cells, the index position represents the number of adjacent mines
         */
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
		
		/**
		 * The size of each cell. This should be the same size as the cell's images.
		 */
		public static const CellSize:int = 24;
		
		/**
		 * The cell's offset to be considered in the field.
		 */
		public static const FieldOffset:Point = new Point(34, 60);
		
		private static var CellGraphic:Image = new Image(Assets.CELL_GRAPHIC);
		private static var CellHoverGraphic:Image = new Image(Assets.CELL_OVER_GRAPHIC);
		private static var CellDownGraphic:Image = new Image(Assets.CELL_DOWN_GRAPHIC);
		private static var FlaggedCellGraphic:Image = new Image(Assets.FLAGGED_CELL_GRAPHIC);
		private static var EmptyCellGraphics:Array = CreateNumberedCells();
		private static var ExplodedMineCellGraphic:Image = new Image(Assets.EXPLODED_MINE_CELL_GRAPHIC);
		private static var RevealedMineCellGraphic:Image = new Image(Assets.REVEALED_MINE_CELL_GRAPHIC);
		private static var FlaggedWrongCellGraphic:Image = new Image(Assets.FLAGGED_WRONG_CELL_GRAPHIC);
		private static var jumpGravity:Number = 1;
		
		private var isInUse:Boolean = true;
		private var rowIndex:int;
		private var columnIndex:int;
		private var clickHandler:Function;
		
		private var isJumping:Boolean = false;
		private var isFalling:Boolean = false;
		private var isRestoring:Boolean = false;
		private var velocity:Number;
		
		private var adjacentMineCount:int = 0;
		private var isMine:Boolean = false;
		private var isFlagged:Boolean = false;
		private var isRevealed:Boolean = false;
		private var isDeactivated:Boolean = false;
		
		private var location:Point;
		private var shakeCount:int = 0;
		private var shakeOffsetX:Number = 0;
		private var shakeOffsetY:Number = 0;
		
		public function Cell(rowIndex:int, columnIndex:int, clickHandler:Function):void
		{
			super(columnIndex * CellSize + FieldOffset.x, rowIndex * CellSize + FieldOffset.y, CellSize, CellSize, "", onClick);
			
			this.location = new Point(x, y);
			this.rowIndex = rowIndex;
			this.columnIndex = columnIndex;
			this.clickHandler = clickHandler;
			
			Reset();
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
		
		override public function update():void
		{
			super.update();
			
			// Velocity-related motion
			if (isRestoring)
			{
				// Determine which direction the cell is being restored from amd update the position
				var fromTop:Boolean = y < location.y;
				y -= velocity;
				// Check whether restoring is complete
				if ((fromTop && y >= location.y) || (!fromTop && y <= location.y))
				{
					y = location.y;
					isRestoring = false;
				}
			}
			else if (isJumping)
			{
				y -= velocity;
				velocity -= jumpGravity;
				if (y >= location.y)
				{
					isJumping = false;
					y = location.y;
				}
			}
			else if (isFalling)
			{
				y -= velocity;
				velocity -= jumpGravity;
				if (y >= FP.height + (rowIndex * CellSize))
				{
					y = FP.height + (rowIndex * CellSize);
					isFalling = false;
				}
			}
			
			if (shakeCount > 0)
			{
				x = location.x;
				y = location.y;
				if ( --shakeCount > 0 )
				{
					x += shakeOffsetX * (shakeCount % 4 > 1 ? 1 : -1);
					y += shakeOffsetY * (shakeCount % 4 > 1 ? 1 : -1);
					if (shakeCount % 2 == 0)
					{
						shakeOffsetX /= 1.3;
						shakeOffsetY /= 1.3;
					}
				}
			}
		}
		
		private function onClick():void
		{
			if (isDeactivated || !isInUse)
				return;
			
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
			return isFlagged;
		}
		
		public function IncreaseAdjacentMineCount():void
		{
			++adjacentMineCount;
		}
		
		/**
		 * Resets the cell.
		 * @param shake Whether or not to shake.
		 */
		public function Reset():void
		{
			isDeactivated = false;
			
			adjacentMineCount = 0;
			isMine = false;
			isFlagged = false;
			isRevealed = false;
			
			normal = CellGraphic;
			hover = CellHoverGraphic;
			down = CellDownGraphic;
		}
		
		/**
		 * Deactivates the cell so it no longer responds to the player.
		 */
		public function Deactivate():void
		{
			isDeactivated = true;
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
			
			isRevealed = true;
			isDeactivated = true;
			
			if (isMine)
			{
				if (!isFlagged)
				{
					normal = byPlayer
						? ExplodedMineCellGraphic
						: RevealedMineCellGraphic;
				}
			}
			else
			{
				normal = isFlagged
					? FlaggedWrongCellGraphic
					: EmptyCellGraphics[adjacentMineCount];
			}
			hover = normal;
			down = normal;
		}
		
		/**
		 * Makes the cell "jump" with a random initial velocity.
		 */
		public function Jump():void
		{
			if (isRestoring)
				return;
			shakeCount = 0;
			x = location.x;
			y = location.y;
			
			velocity = 1 + Math.random() * 5;
			isJumping = true;
		}
		
		/**
		 * Makes the cell "shake" at a random direction.
		 */
		public function Shake(power:int = 6, duration:int = 20):void
		{
			shakeCount = duration;
			shakeOffsetX = ((Math.random() * power) + 4) * Math.pow(2, -Math.round(Math.random()));
			shakeOffsetY = ((Math.random() * power) + 4) * Math.pow(2, -Math.round(Math.random()));
		}
		
		/**
		 * Puts a flag on the cell.
		 */
		public function ToggleFlag():void
		{
			if (isRevealed || isDeactivated)
				return;
			
			isFlagged = !isFlagged;
			
			if (isFlagged)
			{
				normal = FlaggedCellGraphic;
				hover = normal;
				down = normal;
			}
			else
			{
				normal = CellGraphic;
				hover = CellHoverGraphic;
				down = CellDownGraphic;
			}
		}
		
		/**
		 * Sets whether or not to use the cell.
		 */
		public function SetIsInUse(isInUse:Boolean, animate:Boolean = true):void
		{
			var wasInUse:Boolean = this.isInUse;
			
			this.isInUse = isInUse;
			
			if (!isInUse && wasInUse)
				Fall(animate);
			else if (isInUse && !wasInUse)
				Restore(animate);
		}
		
		private function Fall(animate:Boolean = true):void
		{
			isRestoring = false;
			velocity = 0;
			shakeCount = 0;
			x = location.x;
			
			if (animate)
			{
				if(y == location.y)
					Jump();
				isFalling = true;
			}
			else
			{
				y = FP.height + (rowIndex * CellSize);
				isFalling = false;
			}
		}
		
		private function Restore(animate:Boolean = true):void
		{
			isFalling = false;
			isJumping = false;
			shakeCount = 0;
			x = location.x;
			
			if (animate)
			{
				velocity = 20 + Math.random() * 30;
				isRestoring = true;
			}
			else
			{
				y = location.y;
				isRestoring = false;
			}
		}
	}
}
