local BD = require("ui/bidi")
local Blitbuffer = require("ffi/blitbuffer")
local ButtonDialog = require("ui/widget/buttondialog")
local CenterContainer = require("ui/widget/container/centercontainer")
local Device = require("device")
local Screen = Device.screen
local Size = require("ui/size")
local Geom = require("ui/geometry")
local GestureRange = require("ui/gesturerange")
local FrameContainer = require("ui/widget/container/framecontainer")
local InputContainer = require("ui/widget/container/inputcontainer")
local VerticalGroup = require("ui/widget/verticalgroup")
local UIManager = require("ui/uimanager")
local logger = require("logger")
local _ = require("gettext")

local GridView = require("gridview")
local SoftKeyboard = require("softkeyboard")
local Solve = require("solve")

local GameView = InputContainer:new{
    width = nil,
    height = nil,
    puzzle = nil,
    active_direction = Solve.DOWN,
    active_row_num = nil,
    active_col_num = nil,
}

function GameView:init()
    self.dimen = Geom:new{
        w = self.width or Screen:getWidth(),
        h = self.height or Screen:getHeight(),
    }
    -- Initialize the grid.
    self.puzzle:getGrid()
    -- Load the state of the puzzle
    --- @todo: This should be implemented differently... see puzzle:init FMI
    self.puzzle:load()
    -- Set the active clue to first grid element.
    self.active_row_num = 1
    self.active_col_num = 1
    self.active_clue = self.puzzle:getClueByPos(1,1, self.active_direction) or ""
    -- Set the initial active direction
    self.puzzle:setActiveDirection(Solve.DOWN)
    -- Initialize gesture events.
    if Device:isTouchDevice() then
        self.ges_events.Swipe = {
            GestureRange:new{
                ges = "swipe",
                range = self.dimen,
            }
        }
    end
end

function GameView:render()
    -- Build the keyboard.
    self.keyboard_view = SoftKeyboard:new{
        width = Screen:getWidth(),
        clue_value = self.active_clue,
        inputbox = self,
    }
    -- Calculate grid height. Note that grid_height should not exceed screen width.
    local screen_h_minus_keyboard_h = Screen:getHeight() - self.keyboard_view.dimen.h
    local grid_height = screen_h_minus_keyboard_h < Screen:getWidth() and
        screen_h_minus_keyboard_h or
        Screen:getWidth()
    local grid_width = grid_height
    self.grid_view = GridView:new{
        width = grid_width,
        height = grid_height,
        size = {
            cols = self.puzzle.size.cols,
            rows = self.puzzle.size.rows
        },
        grid = self.puzzle:getGrid(),
        on_tap_callback = function(row_num, col_num)
            -- On tap, pass the row and col nums to the active puzzle and return
            -- a clue based on the active direction (i.e.: across or down)
            -- Then update the grid (@todo: display touch feedback) and the clue in
            -- the active grid view. Then refresh this view.
            self.active_row_num = row_num
            self.active_col_num = col_num
            self:refreshGameView()
        end,
    }
    -- Build the container.
    self[1] = FrameContainer:new{
        width = self.dimen.w,
        height = self.dimen.h,
        padding = 0,
        margin = 0,
        bordersize = 0,
        background = Blitbuffer.COLOR_BLACK,
        VerticalGroup:new{
            align = "center",
            background = Blitbuffer.COLOR_GRAY,
            CenterContainer:new{
                dimen = Geom:new{
                    w = self.dimen.w,
                    h = screen_h_minus_keyboard_h,
                },
                padding = 0,
                self.grid_view,
            },
            self.keyboard_view,
        }
    }
    self:refreshGameView()
end

function GameView:refreshGameView()
    -- Refresh is basically called after every action, so makes sense
    -- to have the save method called from here.
    self.puzzle:save()

    local clue_value = self.puzzle:getClueByPos(self.active_row_num, self.active_col_num, self.active_direction)
    if not clue_value then
        self.puzzle:resetActiveSquare()
    else
        self.puzzle:setActiveSquare(self.active_row_num, self.active_col_num)
    end

    self.grid_view:updateGrid(self.puzzle:getGrid())
    self.keyboard_view:updateClue(clue_value)

    self.grid_view:render()
    self.keyboard_view:render()
    -- Setting it dirty works. I don't know enough about UIManager to understand why
    -- UIManager:show doesn't work.
    UIManager:setDirty(self, "ui")
end

function GameView:addChars(chars)
    --- @todo: move the direction toggle into its own method thing. This is a sloppy
    -- hack to make work, and I would like to do better.
    if chars == "direction" then
        self:toggleDirection()
    else
        self.puzzle:setLetterForGuess(chars, self.puzzle:getActiveSquare())
        -- Advance the pointer
        self:movePointerForward()
        self:refreshGameView()
    end
    return true
end

-- This method (and its sister method, GameView:leftChar) should advance the player's active
-- square to the next square that belongs to the next clue. The clue should advance either
--down or across depending on which direction is active.
function GameView:rightChar()
    local row, col = self.puzzle:getNextCluePos(self.active_row_num, self.active_col_num, self.active_direction)
    self.active_row_num = row
    self.active_col_num = col
    self:refreshGameView()
end

function GameView:leftChar()
    local row, col = self.puzzle:getPrevCluePos(self.active_row_num, self.active_col_num, self.active_direction)
    self.active_row_num = row
    self.active_col_num = col
    self:refreshGameView()
end

function GameView:movePointerForward()
    if self.active_direction == Solve.DOWN then
        if self.active_row_num >= self.puzzle.size.rows then
            self.active_row_num = 1
            self.active_col_num = self.active_col_num + 1
            if self.active_col_num > self.puzzle.size.cols then
                self.active_col_num = 1
            end
        else
            self.active_row_num = self.active_row_num + 1
        end
    elseif self.active_direction == Solve.ACROSS then
        if self.active_col_num >= self.puzzle.size.cols then
            self.active_col_num = 1
            self.active_row_num = self.active_row_num + 1
            if self.active_row_num > self.puzzle.size.rows then
                self.active_row_num = 1
            end
        else
            self.active_col_num = self.active_col_num + 1
        end
    end
    -- Check to see if advancement landed on a non-active grid square.
    if not self.puzzle:getClueByPos(self.active_row_num, self.active_col_num, self.active_direction) then
        self:movePointerForward()
    end
end

function GameView:movePointerBackward()
    if self.active_direction == Solve.DOWN then
        if self.active_row_num <= 1 then
            self.active_row_num = self.puzzle.size.rows
            self.active_col_num = self.active_col_num - 1
            if self.active_col_num < 1 then
                self.active_col_num = self.puzzle.size.cols
            end
        else
            self.active_row_num = self.active_row_num - 1
        end
    elseif self.active_direction == Solve.ACROSS then
        if self.active_col_num <= 1 then
            self.active_col_num = self.puzzle.size.cols
            self.active_row_num = self.active_row_num - 1
            if self.active_row_num < 1 then
                self.active_row_num = self.puzzle.size.rows
            end
        else
            self.active_col_num = self.active_col_num - 1
        end
    end
    -- Check to see if advancement landed on a non-active grid square.
    if not self.puzzle:getClueByPos(self.active_row_num, self.active_col_num, self.active_direction) then
        self:movePointerBackward()
    end
end

-- This method should 1) delete the character in the active square, 2) move to the previous
-- square in the row or column.
function GameView:delChar()
    if self.puzzle:getLetterForSquare(self.puzzle:getActiveSquare()) ~= "" then
        self.puzzle:setLetterForGuess("", self.puzzle:getActiveSquare())
    else
        self:movePointerBackward()
    end
    self:refreshGameView()
end

function GameView:toggleDirection()
    if self.active_direction == Solve.DOWN then
        self.active_direction = Solve.ACROSS
    elseif self.active_direction == Solve.ACROSS then
        self.active_direction = Solve.DOWN
    end
    self.puzzle:setActiveDirection(self.active_direction)
    self:refreshGameView()
end

function GameView:onSwipe(arg, ges_ev)
    local direction = BD.flipDirectionIfMirroredUILayout(ges_ev.direction)
    if direction == "south" then
        -- See readerhighlight.lua for more ideas about how to use ButtonDialog.
        local game_dialog
        game_dialog = ButtonDialog:new{
            buttons = {
                {
                    {
                        text = _("Check Square"),
                        enabled = false,
                        callback = function()

                        end,
                    },
                    {
                        text = _("Check Word"),
                        enabled = false,
                        callback = function()

                        end,
                    },
                    {
                        text = _("Check Puzzle"),
                        callback = function()
                            self.puzzle:checkPuzzle()
                            UIManager:close(game_dialag)
                            self:refreshGameView()
                        end,
                    },
                },
                {
                    {
                        text = _("Saved"),
                        enabled = false,
                        callback = function()

                        end,
                    },
                    {
                        text = _("Exit"),
                        callback = function()

                        end,
                    },
                }
            },
            tap_close_callback = function()
                UIManager:close(game_dialag)
            end,
        }
        UIManager:show(game_dialog)
    end
end

return GameView
