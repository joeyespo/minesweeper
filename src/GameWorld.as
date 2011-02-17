package  
{
	import flash.display.MovieClip;
	import net.flashpunk.FP;
	import net.flashpunk.Graphic;
	import net.flashpunk.graphics.Image;
	import net.flashpunk.graphics.Text;
	import net.flashpunk.Tween;
	import net.flashpunk.tweens.misc.ColorTween;
	import net.flashpunk.tweens.motion.LinearMotion;
	import net.flashpunk.utils.Input;
	import net.flashpunk.utils.Key;
	import net.flashpunk.World;
	import punk.ui.PunkButton;
	import punk.ui.PunkLabel;
	import ui.WinNotice;
	
	/**
	 * ...
	 * @author Joe Esposito
	 */
	public class GameWorld extends World
	{
		private static var FlagButtonGraphic:Image = new Image(Assets.FLAG_BUTTON_GRAPHIC);
		private static var FlagButtonToggledGraphic:Image = new Image(Assets.FLAG_BUTTON_TOGGLED_GRAPHIC);
		
		private var winNotice:WinNotice = null;
		private var mineCountLabel:PunkLabel;
		private var restartButton:PunkButton;
		private var flagButton:PunkButton;
		
		private var difficulty:int;
		private var cellRowCount:int;
		private var cellColumnCount:int;
		private var mineCount:int;
		private var activeFlagCount:int;
		
		private var isPlaying:Boolean = false;
		private var score:int;
		private var cellRows:Array;
		private var isMinefieldSetup:Boolean;
		private var isFlagModeByButton:Boolean;
		private var isFlagModeByShift:Boolean;
		private var safeCellCount:int;
		private var revealedCellCount:int;
		private var colorTween:ColorTween;
		
		public function GameWorld():void
		{
		}
		
		override public function begin():void 
		{
			difficulty = 2;
			SetupDifficulty();
			AddCells();
			
			PunkLabel.size = 24;
			mineCountLabel = new PunkLabel("Mines: 0", 4, 4, 300, 32);
			mineCountLabel.color = 0xFFFFFF;
			mineCountLabel.background = false;
			add(mineCountLabel);
			
			restartButton = new PunkButton((FP.width - 60) / 2, 4, 60, 24, "", Restart_Clicked);
			restartButton.normal = new Image(Assets.RESTART_BUTTON_GRAPHIC);
			restartButton.hover = new Image(Assets.RESTART_BUTTON_DOWN_GRAPHIC);
			restartButton.down = restartButton.hover;
			add(restartButton);
			
			flagButton = new PunkButton(((FP.width) - 32) - (8), 4, 32, 32, "", FlagButton_Clicked);
			flagButton.normal = FlagButtonGraphic;
			flagButton.hover = new Image(Assets.FLAG_BUTTON_OVER_GRAPHIC);
			flagButton.down = new Image(Assets.FLAG_BUTTON_DOWN_GRAPHIC);
			add(flagButton);
			
			NewGame(true);
		}
		
		override public function end():void 
		{
			if (isPlaying)
				EndGame(false);
			
			if (winNotice != null)
			{
				remove(winNotice);
				winNotice = null;
			}
			
			if (cellRows != null)
			{
				for (var rowIndex:int = 0; rowIndex < cellRowCount; ++rowIndex)
					for (var columnIndex:int = 0; columnIndex < cellColumnCount; ++columnIndex)
						remove(cellRows[rowIndex][columnIndex]);
				cellRows = null;
			}
		}
		
		override public function update():void 
		{
			if (isPlaying)
			{
				// Check for and set flag mode using the shortcut key
				if (Input.check(Key.SHIFT) != isFlagModeByShift)
				{
					isFlagModeByShift = !isFlagModeByShift;
					FlagModeChanged();
				}
			}
			
			if (colorTween != null)
				FP.screen.color = colorTween.color;
			
			super.update();
		}
		
		private function Restart_Clicked():void
		{
			// TODO: Select difficulty
			// TODO: Confirm, if game is in progress
			
			NewGame();
		}
		
		private function FlagButton_Clicked():void
		{
			if (!isPlaying)
				return;
			
			isFlagModeByButton = !isFlagModeByButton;
			FlagModeChanged();
		}
		
		private function Cell_Clicked(cell:Cell):void
		{
			if (!isPlaying)
				return;
			
			if (!isMinefieldSetup)
				SetupMinefield(cell.RowIndex, cell.ColumnIndex);
			
			// Check for flag mode
			if (IsFlagMode)
			{
				cell.ToggleFlag();
				if (cell.IsFlagged)
					++activeFlagCount;
				else
					--activeFlagCount;
				mineCountLabel.text = "Mines: " + (mineCount - activeFlagCount);
				return;
			}
			// Check whether cell was previously flagged, ignoring the click
			if (cell.IsFlagged)
				return;
			
			cell.Reveal();
			++revealedCellCount;
			
			// Check for the endgames
			if (cell.IsMine)
				EndGame(false);
			else
			{
				if (cell.AdjacentMineCount == 0)
					FloodReveal(cell.RowIndex, cell.ColumnIndex);
				if (revealedCellCount >= safeCellCount)
					EndGame(true);
			}
		}
		
		/**
		 * Starts a new game.
		 * @param isFirstGame Whether this is the first time a new game is played.
		 */
		private function NewGame(isFirstGame:Boolean = false):void
		{
			if (!isFirstGame)
				Reset();
			
			mineCountLabel.text = "Mines: " + mineCount;
			flagButton.active = true;
			
			if ((FP.screen.color & 0x00FFFFFF) != 0x000000)
				FadeToColor(0x000000);
			
			isPlaying = true;
		}
		
		private function EndGame(playerWins:Boolean):void
		{
			isPlaying = false;
			
			if (playerWins)
			{
				DeactivateAndFlagAllMines();
				
				winNotice = new WinNotice();
				add(winNotice);
				
				mineCountLabel.text = "Mines: 0";
				
				FadeToColor(0x88CC88, 1.0);
			}
			else
			{
				DeactivateAndRevealAllMines();
			}
			
			flagButton.normal = FlagButtonGraphic;
			flagButton.active = false;
		}
		
		private function Reset():void
		{
			new MovieClip
			if (winNotice != null)
			{
				remove(winNotice);
				winNotice = null;
			}
			
			for (var rowIndex:int = 0; rowIndex < cellRowCount; ++rowIndex)
			{
				for (var columnIndex:int = 0; columnIndex < cellColumnCount; ++columnIndex)
				{
					var cell:Cell = cellRows[rowIndex][columnIndex];
					cell.Reset();
					cell.Jump();
				}
			}
			
			isMinefieldSetup = false;
			score = 0;
			revealedCellCount = 0;
			safeCellCount = 0;
			activeFlagCount = 0;
			
			isFlagModeByButton = false;
			isFlagModeByShift = false;
			
			FlagModeChanged();
		}
		
		private function SetupDifficulty():void
		{
			// TODO: Tweak these settings
			// TODO: Add/remove or show/hide cells
			
			switch(difficulty)
			{
				case 0:
					cellRowCount = 6;
					cellColumnCount = 12;
					mineCount = 3;
					break;
				case 1:
					cellRowCount = 12;
					cellColumnCount = 16;
					mineCount = 6;
					break;
				default:
					cellRowCount = 16;
					cellColumnCount = 24;
					mineCount = 25;
					break;
			}
		}
		
		private function get IsFlagMode():Boolean
		{
			return isFlagModeByButton || isFlagModeByShift;
		}
		
		private function FlagModeChanged():void
		{
			FadeToColor(IsFlagMode ? 0x444422 : 0x000000);
			
			flagButton.normal = IsFlagMode
				? FlagButtonToggledGraphic
				: FlagButtonGraphic;
		}
		
		private function FadeToColor(color:uint, duration:Number=0.2):void
		{
			if (colorTween != null)
			{
				removeTween(colorTween);
				colorTween = null;
			}
			colorTween = new ColorTween(function():void { colorTween = null; });
			colorTween.tween(duration, FP.screen.color, color);
			addTween(colorTween);
		}
		
		private function AddCells():void
		{
			cellRows = [];
			for (var rowIndex:int = 0; rowIndex < cellRowCount; ++rowIndex)
			{
				var column:Array = [];
				for (var columnIndex:int = 0; columnIndex < cellColumnCount; ++columnIndex)
				{
					var cell:Cell = new Cell(rowIndex, columnIndex, Cell_Clicked);
					column.push(cell);
					add(cell);
				}
				cellRows.push(column);
			}
		}
		
		private function SetupMinefield(startRowIndex:int, startColumnIndex:int):void
		{
			if (mineCount > cellRowCount * cellColumnCount)
				throw new Error("The mine count is greater than the total number of cells.")
			
			for (var mineIndex:int = 0; mineIndex < mineCount; )
			{
				// Get a random cell
				var rowIndex:int = Rand(cellRowCount);
				var columnIndex:int = Rand(cellColumnCount);
				var cell:Cell = cellRows[rowIndex][columnIndex];
				
				// Skip, if this is the first row/column the player clicked on
				if (rowIndex == startRowIndex && columnIndex == startColumnIndex)
					continue;
				// Skip if there's already a mine here
				if (cell.IsMine)
					continue;
				
				// Set the cell at the random row/column to a mine
				cell.IsMine = true;
				
				// Adjust the cell's adjacent cells
				AddAdjacent(rowIndex - 1, columnIndex - 1);
				AddAdjacent(rowIndex - 1, columnIndex    );
				AddAdjacent(rowIndex - 1, columnIndex + 1);
				AddAdjacent(rowIndex    , columnIndex - 1);
				// (Current cell)
				AddAdjacent(rowIndex    , columnIndex + 1);
				AddAdjacent(rowIndex + 1, columnIndex - 1);
				AddAdjacent(rowIndex + 1, columnIndex    );
				AddAdjacent(rowIndex + 1, columnIndex + 1);
				
				// Increase mine count
				++mineIndex;
			}
			safeCellCount = (cellRowCount * cellColumnCount) - mineCount;
			
			isMinefieldSetup = true;
		}
		
		private function DeactivateAndRevealAllMines():void
		{
			for (var rowIndex:int = 0; rowIndex < cellRowCount; ++rowIndex)
			{
				for (var columnIndex:int = 0; columnIndex < cellColumnCount; ++columnIndex)
				{
					var cell:Cell = cellRows[rowIndex][columnIndex];
					if (!cell.IsRevealed)
					{
						if (cell.IsMine || cell.IsFlagged)
							cell.Reveal(false);
						else
							cell.Deactivate();
					}
					cell.Shake();
				}
			}
		}
		
		private function DeactivateAndFlagAllMines():void
		{
			for (var rowIndex:int = 0; rowIndex < cellRowCount; ++rowIndex)
			{
				for (var columnIndex:int = 0; columnIndex < cellColumnCount; ++columnIndex)
				{
					var cell:Cell = cellRows[rowIndex][columnIndex];
					if (cell.IsMine && !cell.IsFlagged)
						cell.ToggleFlag();
					cell.Deactivate();
				}
			}
		}
		
		private function AddAdjacent(rowIndex:int, columnIndex:int):void
		{
			if (rowIndex < 0 || rowIndex >= cellRowCount || columnIndex < 0 || columnIndex >= cellColumnCount)
				return;
			var cell:Cell = cellRows[rowIndex][columnIndex];
			cell.IncreaseAdjacentMineCount();
		}
		
		private function FloodReveal(rowIndex:int, columnIndex:int):void
		{
			var cell:Cell = cellRows[rowIndex][columnIndex];
			
			if (cell.IsFlagged)
				return;
			
			if (!cell.IsRevealed)
			{
				cell.Reveal();
				++revealedCellCount;
			}
			
			// Do no further processing if the cell has adjacent mines
			if (cell.AdjacentMineCount != 0)
				return;
			
			// Adjust the cell's adjacent cells
			FloodRevealAdjacent(rowIndex - 1, columnIndex - 1);
			FloodRevealAdjacent(rowIndex - 1, columnIndex    );
			FloodRevealAdjacent(rowIndex - 1, columnIndex + 1);
			FloodRevealAdjacent(rowIndex    , columnIndex - 1);
			// (Current cell)
			FloodRevealAdjacent(rowIndex    , columnIndex + 1);
			FloodRevealAdjacent(rowIndex + 1, columnIndex - 1);
			FloodRevealAdjacent(rowIndex + 1, columnIndex    );
			FloodRevealAdjacent(rowIndex + 1, columnIndex + 1);
		}
		
		private function FloodRevealAdjacent(rowIndex:int, columnIndex:int):void
		{
			if (rowIndex < 0 || rowIndex >= cellRowCount || columnIndex < 0 || columnIndex >= cellColumnCount)
				return;
			
			// Get non-mine cell and recurse if it's not a mine and not already revealed
			var cell:Cell = cellRows[rowIndex][columnIndex];
			if (!cell.IsMine && !cell.IsRevealed)
				FloodReveal(cell.RowIndex, cell.ColumnIndex);
		}
		
		private function Rand(max:int):int
		{
			return int(Math.floor(Math.random() * max));
		}
	}
}
