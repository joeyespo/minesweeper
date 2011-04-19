package  
{
	import flash.display.MovieClip;
	import flash.utils.Timer;
	import net.flashpunk.FP;
	import net.flashpunk.Graphic;
	import net.flashpunk.graphics.Image;
	import net.flashpunk.graphics.Text;
	import net.flashpunk.Tween;
	import net.flashpunk.tweens.misc.ColorTween;
	import net.flashpunk.tweens.misc.NumTween;
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
		private static const EASY:int = 0;
		private static const MEDIUM:int = 1;
		private static const HARD:int = 2;
		
		private static var FlagButtonGraphic:Image = new Image(Assets.FLAG_BUTTON_GRAPHIC);
		private static var FlagButtonToggledGraphic:Image = new Image(Assets.FLAG_BUTTON_TOGGLED_GRAPHIC);
		private static var DifficultyButtonsWidth:int = 75;
		private static var DifficultyButtonsDistance:int = DifficultyButtonsWidth + 4;
		private static var DifficultyButtonsTime:int = 60;
		private static var NewGameHoverTime:int = 10;
		private static var MaxCellRowCount:int = 16;
		private static var MaxCellColumnCount:int = 24;
		
		private static var InitialDifficulty:int = MEDIUM;
		
		private var winNotice:WinNotice = null;
		private var mineCountLabel:PunkLabel;
		private var flagButton:PunkButton;
		private var newGameButton:PunkButton;
		private var easyButton:PunkButton;
		private var mediumButton:PunkButton;
		private var hardButton:PunkButton;
		private var difficultyButtonsVisible:Boolean;
		private var leftDifficultyButton:PunkButton;
		private var rightDifficultyButton:PunkButton;
		private var difficultyButtonsTween:NumTween;
		private var difficultyButtonsTimeRemaining:int;
		private var newGameHoverCountdown:int;
		// Keep difficulty buttons from being pressed while animating or behind the New Game button
		private var canChangeDifficulty:Boolean = false;
		
		private var difficulty:int;
		private var cellRowOffset:int;
		private var cellColumnOffset:int;
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
			PunkLabel.size = 24;
			mineCountLabel = new PunkLabel("Mines: 0", 4, 4, 300, 32);
			mineCountLabel.color = 0xFFFFFF;
			mineCountLabel.background = false;
			add(mineCountLabel);
			
			easyButton = new PunkButton((FP.width - DifficultyButtonsWidth) / 2, 4, DifficultyButtonsWidth, 36, "", Easy_Clicked);
			easyButton.normal = new Image(Assets.EASY_BUTTON_GRAPHIC);
			easyButton.hover = new Image(Assets.EASY_BUTTON_OVER_GRAPHIC);
			easyButton.down = new Image(Assets.EASY_BUTTON_DOWN_GRAPHIC);
			easyButton.visible = false;
			add(easyButton);
			
			mediumButton = new PunkButton((FP.width - DifficultyButtonsWidth) / 2, 4, DifficultyButtonsWidth, 36, "", Medium_Clicked);
			mediumButton.normal = new Image(Assets.MEDIUM_BUTTON_GRAPHIC);
			mediumButton.hover = new Image(Assets.MEDIUM_BUTTON_OVER_GRAPHIC);
			mediumButton.down = new Image(Assets.MEDIUM_BUTTON_DOWN_GRAPHIC);
			mediumButton.visible = false;
			add(mediumButton);
			
			hardButton = new PunkButton((FP.width - DifficultyButtonsWidth) / 2, 4, DifficultyButtonsWidth, 36, "", Hard_Clicked);
			hardButton.normal = new Image(Assets.HARD_BUTTON_GRAPHIC);
			hardButton.hover = new Image(Assets.HARD_BUTTON_OVER_GRAPHIC);
			hardButton.down = new Image(Assets.HARD_BUTTON_DOWN_GRAPHIC);
			hardButton.visible = false;
			add(hardButton);
			
			newGameButton = new PunkButton((FP.width - 101) / 2, 4, 101, 36, "", NewGame_Clicked);
			newGameButton.normal = new Image(Assets.NEWGAME_BUTTON_GRAPHIC);
			newGameButton.hover = new Image(Assets.NEWGAME_BUTTON_OVER_GRAPHIC);
			newGameButton.down = new Image(Assets.NEWGAME_BUTTON_DOWN_GRAPHIC);
			add(newGameButton);
			
			flagButton = new PunkButton(((FP.width) - 32) - (8), 4, 32, 32, "", FlagButton_Clicked);
			flagButton.normal = FlagButtonGraphic;
			flagButton.hover = new Image(Assets.FLAG_BUTTON_OVER_GRAPHIC);
			flagButton.down = new Image(Assets.FLAG_BUTTON_DOWN_GRAPHIC);
			add(flagButton);
			
			AddAllCells();
			
			UpdateDifficulty(InitialDifficulty, true);
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
				for (var rowIndex:int = 0; rowIndex < MaxCellRowCount; ++rowIndex)
					for (var columnIndex:int = 0; columnIndex < MaxCellColumnCount; ++columnIndex)
						remove(cellRows[rowIndex][columnIndex]);
				cellRows = null;
			}
		}
		
		override public function update():void 
		{
			var mouseX:int = Input.mouseX;
			var mouseY:int = Input.mouseY;
			
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
			
			if (difficultyButtonsTween != null)
			{
				leftDifficultyButton.x = newGameButton.left - difficultyButtonsTween.value;
				rightDifficultyButton.x = (newGameButton.right - DifficultyButtonsWidth) + difficultyButtonsTween.value;
			}
			if (difficultyButtonsTimeRemaining > 0)
			{
				if (mouseY < newGameButton.bottom && mouseX >= newGameButton.x - DifficultyButtonsWidth - 4 && mouseX < newGameButton.right + DifficultyButtonsWidth + 4)
					difficultyButtonsTimeRemaining = DifficultyButtonsTime;
				else if(--difficultyButtonsTimeRemaining <= 0)
					HideDifficultyButtons();
			}
			
			// Check whether to show the new game companion buttons
			if (!difficultyButtonsVisible && mouseX >= newGameButton.x && mouseX < newGameButton.right && mouseY >= newGameButton.y && mouseY < newGameButton.bottom)
			{
				if (newGameHoverCountdown > 0)
				{
					if (--newGameHoverCountdown <= 0)
						ShowDifficultyButtons();
				}
				else
					newGameHoverCountdown = NewGameHoverTime;
			}
			else
			{
				newGameHoverCountdown = 0;
			}
			
			super.update();
		}
		
		private function NewGame_Clicked():void
		{
			// TODO: Confirm, if game is in progress
			
			NewGame();
		}
		
		private function Easy_Clicked():void
		{
			if (!canChangeDifficulty || !easyButton.visible)
				return;
			UpdateDifficulty(EASY);
			ShowDifficultyButtons();
			NewGame();
		}
		
		private function Medium_Clicked():void
		{
			if (!canChangeDifficulty || !mediumButton.visible)
				return;
			UpdateDifficulty(MEDIUM);
			ShowDifficultyButtons();
			NewGame();
		}
		
		private function Hard_Clicked():void
		{
			if (!canChangeDifficulty || !hardButton.visible)
				return;
			UpdateDifficulty(HARD);
			ShowDifficultyButtons();
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
			
			if(!difficultyButtonsVisible)
				ShowDifficultyButtons();
			
			isPlaying = true;
		}
		
		/**
		 * Animates the difficulty buttons.
		 */
		private function ShowDifficultyButtons():void
		{
			AnimateDifficultyButtons();
		}
		
		/**
		 * Animates the difficulty buttons.
		 */
		private function HideDifficultyButtons():void
		{
			AnimateDifficultyButtons(true);
		}
		
		/**
		 * Animates the difficulty buttons.
		 */
		private function AnimateDifficultyButtons(reverse:Boolean=false, duration:Number=0.2):void
		{
			easyButton.visible = false;
			mediumButton.visible = false;
			hardButton.visible = false;
			canChangeDifficulty = false;
			
			// Determine which difficulty buttons to use
			switch(difficulty)
			{
				case EASY:
					leftDifficultyButton = mediumButton;
					rightDifficultyButton = hardButton;
					break;
				case MEDIUM:
					leftDifficultyButton = easyButton;
					rightDifficultyButton = hardButton;
					break;
				case HARD:
					leftDifficultyButton = easyButton;
					rightDifficultyButton = mediumButton;
					break;
			}
			
			leftDifficultyButton.visible = true;
			rightDifficultyButton.visible = true;
			difficultyButtonsVisible = true;
			
			if (difficultyButtonsTween != null)
			{
				removeTween(difficultyButtonsTween);
				difficultyButtonsTween = null;
			}
			difficultyButtonsTween = new NumTween(function():void { AnimateDifficultyButtonsComplete(reverse); } );
			
			var start:int;
			var stop:int;
			if (!reverse)
			{
				start = 0;
				stop = DifficultyButtonsDistance;
				difficultyButtonsTimeRemaining = DifficultyButtonsTime;
			}
			else
			{
				start = DifficultyButtonsDistance;
				stop = 0;
				difficultyButtonsTimeRemaining = 0;
			}
			
			difficultyButtonsTween.tween(start, stop, duration);
			addTween(difficultyButtonsTween);
		}
		
		private function AnimateDifficultyButtonsComplete(reverse:Boolean):void
		{
			if (reverse)
			{
				leftDifficultyButton.x = newGameButton.left;
				rightDifficultyButton.x = newGameButton.right - DifficultyButtonsWidth;
				leftDifficultyButton.visible = false;
				rightDifficultyButton.visible = false;
				difficultyButtonsVisible = false;
			}
			else
			{
				leftDifficultyButton.x = newGameButton.left - (DifficultyButtonsWidth + 4);
				rightDifficultyButton.x = newGameButton.right + 4;
				canChangeDifficulty = true;
			}
			
			difficultyButtonsTween = null;
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
			
			var cellRowStop:int = cellRowOffset + cellRowCount;
			var cellColumnStop:int = cellColumnOffset + cellColumnCount;
			for (var rowIndex:int = cellRowOffset; rowIndex < cellRowStop; ++rowIndex)
			{
				for (var columnIndex:int = cellColumnOffset; columnIndex < cellColumnStop; ++columnIndex)
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
		
		private function UpdateDifficulty(difficulty:int, isFirstGame:Boolean = false):void
		{
			this.difficulty = difficulty;
			
			switch(difficulty)
			{
				case EASY:
					cellRowOffset = 2;
					cellColumnOffset = 4;
					cellRowCount = 12;
					cellColumnCount = 16;
					mineCount = 10;
					break;
				case MEDIUM:
					cellRowOffset = 1;
					cellColumnOffset = 2;
					cellRowCount = 14;
					cellColumnCount = 20;
					mineCount = 25;
					break;
				case HARD:
					cellRowOffset = 0;
					cellColumnOffset = 0;
					cellRowCount = 16;
					cellColumnCount = 24;
					mineCount = 90;
					break;
			}
			
			UpdateAllCells(!isFirstGame);
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
		
		private function AddAllCells():void
		{
			cellRows = [];
			for (var rowIndex:int = 0; rowIndex < MaxCellRowCount; ++rowIndex)
			{
				var column:Array = [];
				for (var columnIndex:int = 0; columnIndex < MaxCellColumnCount; ++columnIndex)
				{
					var cell:Cell = new Cell(rowIndex, columnIndex, Cell_Clicked);
					column.push(cell);
					add(cell);
				}
				cellRows.push(column);
			}
		}
		
		private function UpdateAllCells(animate:Boolean = true):void
		{
			for (var rowIndex:int = 0; rowIndex < MaxCellRowCount; ++rowIndex)
			{
				for (var columnIndex:int = 0; columnIndex < MaxCellColumnCount; ++columnIndex)
				{
					var cell:Cell = cellRows[rowIndex][columnIndex];
					var isInUse:Boolean = rowIndex >= cellRowOffset && rowIndex < cellRowOffset + cellRowCount
						&& columnIndex >= cellColumnOffset && columnIndex < cellColumnOffset + cellColumnCount;
					if(!isInUse)
						cell.Reset();
					cell.SetIsInUse(isInUse, animate);
				}
			}
		}
		
		private function SetupMinefield(startRowIndex:int, startColumnIndex:int):void
		{
			if (mineCount > cellRowCount * cellColumnCount)
				throw new Error("The mine count is greater than the total number of cells.")
			
			for (var mineIndex:int = 0; mineIndex < mineCount; )
			{
				// Get a random cell
				var rowIndex:int = Rand(cellRowCount) + cellRowOffset;
				var columnIndex:int = Rand(cellColumnCount) + cellColumnOffset;
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
			var cellRowStop:int = cellRowOffset + cellRowCount;
			var cellColumnStop:int = cellColumnOffset + cellColumnCount;
			for (var rowIndex:int = cellRowOffset; rowIndex < cellRowStop; ++rowIndex)
			{
				for (var columnIndex:int = cellColumnOffset; columnIndex < cellColumnStop; ++columnIndex)
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
			var cellRowStop:int = cellRowOffset + cellRowCount;
			var cellColumnStop:int = cellColumnOffset + cellColumnCount;
			for (var rowIndex:int = cellRowOffset; rowIndex < cellRowStop; ++rowIndex)
			{
				for (var columnIndex:int = cellColumnOffset; columnIndex < cellColumnStop; ++columnIndex)
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
			if (rowIndex < cellRowOffset || rowIndex >= cellRowOffset + cellRowCount || columnIndex < cellColumnOffset || columnIndex >= cellColumnOffset + cellColumnCount)
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
			if (rowIndex < cellRowOffset || rowIndex >= cellRowOffset + cellRowCount || columnIndex < cellColumnOffset || columnIndex >= cellColumnOffset + cellColumnCount)
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
