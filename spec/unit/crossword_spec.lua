describe("Crossword plugin module", function()

      local Puzzle
      local GameView
      local Solve
      local path_to_odd_puzzle = "plugins/crossword.koplugin/nyt_crosswords/2009/08/19.json"
      local path_to_even_puzzle = "plugins/crossword.koplugin/nyt_crosswords/2009/08/17.json"
      local odd_puzzle -- Size is 15 rows by 16 columns
      local even_puzzle -- Size is 15 rows by 15 columns
      local game_view

      setup(function()
            orig_path = package.path
            package.path = "plugins/crossword.koplugin/?.lua;" .. package.path
            require("commonrequire")

            GameView = require("gameview")
            Puzzle = require("puzzle")
            Solve = require("solve")

            odd_puzzle = Puzzle:initializePuzzle(path_to_odd_puzzle)
            even_puzzle = Puzzle:initializePuzzle(path_to_even_puzzle)
      end)

      describe("Puzzles", function()
            it("should have correct count of rows", function()
                  assert.are.same(15, odd_puzzle.size.rows)
                  assert.are.same(15, even_puzzle.size.rows)
            end)
            it("should have correct count of columns", function()
                  assert.are.same(16, odd_puzzle.size.cols)
                  assert.are.same(15, even_puzzle.size.cols)
            end)
      end)

      describe("GameView with even Puzzle grids", function()
            it("should update active column when pointer is advanced", function()
                  game_view = GameView:new{
                     puzzle = even_puzzle
                  }
                  game_view:render()
                  
                  game_view.active_row_num = 1
                  game_view.active_col_num = 1
                  game_view.active_direction = Solve.ACROSS
                  game_view:movePointer(1)
                  assert.are.same(2, game_view.active_col_num)

            end)
            it("should move to the first letter position of the next clue when right char event is toggled", function()
                  game_view = GameView:new{
                     puzzle = even_puzzle
                  }
                  game_view:render()
                  game_view:rightChar()
                  assert.are.same(2, game_view.active_col_num)
                  assert.are.same(1, game_view.active_row_num)
            end)
            it("should move to first letter position of the last clue when left char event is toggled", function()
                  game_view = GameView:new{
                     puzzle = even_puzzle
                  }
                  game_view:render()
                  game_view:leftChar()
                  assert.are.same(15, game_view.active_col_num)
                  assert.are.same(13, game_view.active_row_num)
            end)            
            it("should move to next clue position when pointer exceeds current clue length", function()
                  game_view = GameView:new{
                     puzzle = even_puzzle
                  }
                  game_view:render()
                  
                  game_view.active_row_num = 1
                  game_view.active_col_num = 1
                  game_view.active_direction = Solve.DOWN
                  game_view:movePointer(1)
                  game_view:movePointer(1)
                  game_view:movePointer(1)
                  game_view:movePointer(1)
                  game_view:movePointer(1)
                  assert.are.same(2, game_view.active_col_num)
            end)
      end)
      
      describe("GameView with odd Puzzle grids", function()
            it("should update active column when pointer is advanced", function()
                  game_view = GameView:new{
                     puzzle = odd_puzzle
                  }
                  game_view:render()
                  
                  game_view.active_row_num = 1
                  game_view.active_col_num = 1
                  game_view.active_direction = Solve.ACROSS
                  game_view:movePointer(1)
                  assert.are.same(2, game_view.active_col_num)

            end)
            it("should move to the first letter position of the next clue when right char event is toggled", function()
                  game_view = GameView:new{
                     puzzle = odd_puzzle
                  }
                  game_view:render()
                  game_view:rightChar()
                  assert.are.same(2, game_view.active_col_num)
                  assert.are.same(1, game_view.active_row_num)
            end)
            it("should move to first letter position of the last clue when left char event is toggled", function()
                  game_view = GameView:new{
                     puzzle = odd_puzzle
                  }
                  game_view:render()
                  game_view:leftChar()
                  assert.are.same(16, game_view.active_col_num)
                  assert.are.same(12, game_view.active_row_num)
            end)                        
            it("should move to next clue position when pointer exceeds current clue length", function()
                  game_view = GameView:new{
                     puzzle = odd_puzzle
                  }
                  game_view:render()
                  
                  game_view.active_row_num = 1
                  game_view.active_col_num = 1
                  game_view.active_direction = Solve.DOWN
                  game_view:movePointer(1)
                  game_view:movePointer(1)
                  game_view:movePointer(1)
                  game_view:movePointer(1)
                  game_view:movePointer(1)
                  assert.are.same(2, game_view.active_col_num)
            end)
      end)
end)