package  
{
	import net.flashpunk.FP;
	import net.flashpunk.Graphic;
	import net.flashpunk.graphics.Image;
	import net.flashpunk.graphics.Text;
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
		private var winNotice:WinNotice = null;
		private var mineCountLabel:PunkLabel;
		private var restartButton:PunkButton;
		private var flagButton:PunkButton;
		
		private var difficulty:int;
		private var cellRowCount:int;
		private var cellColumnCount:int;
		private var mineCount:int
		
		private var isPlaying:Boolean = false;
		private var score:int;
		private var cellRows:Array;
		private var isMinefieldSetup:Boolean;
		private var isFlagMode:Boolean;
		private var safeCellCount:int;
		private var revealedCellCount:int;
		
		public function GameWorld():void
		{
		}
		
		override public function begin():void 
		{
			difficulty = 2;
			SetupDifficulty();
			AddCells();
			
			PunkLabel.size = 24;
			mineCountLabel = new PunkLabel("Mines: 0", 4, 4, 128, 32);
			mineCountLabel.color = 0xFFFFFF;
			mineCountLabel.background = false;
			add(mineCountLabel);
			
			restartButton = new PunkButton((FP.width - 60) / 2, 4, 60, 24, "", Restart_Clicked);
			restartButton.normal = new Image(Assets.RESTART_BUTTON_GRAPHIC);
			restartButton.hover = new Image(Assets.RESTART_BUTTON_DOWN_GRAPHIC);
			restartButton.down = restartButton.hover;
			add(restartButton);
			
			flagButton = new PunkButton(((FP.width) - 32) - (8), 4, 32, 32, "", Flag_Clicked);
			flagButton.normal = new Image(Assets.FLAG_BUTTON_GRAPHIC);
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
		
		private function Restart_Clicked():void
		{
			// TODO: Select difficulty
			// TODO: Confirm, if game is in progress
			
			NewGame();
		}
		
		private function Flag_Clicked():void
		{
			isFlagMode = !isFlagMode;
			
		}
		
		private function Cell_Clicked(cell:Cell):void
		{
			if (!isPlaying)
				return;
			if (!isMinefieldSetup)
				SetupMinefield(cell.RowIndex, cell.ColumnIndex);
			
			// Check for flag mode
			if (isFlagMode)
			{
				cell.ToggleFlag();
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
			}
			else
			{
				DeactivateAndRevealAllMines();
			}
		}
		
		private function Reset():void
		{
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
			isFlagMode = false;
			revealedCellCount = 0;
			safeCellCount = 0;
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
					mineCount = 5;
					break;
			}
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
