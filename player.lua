local class = require 'ext.class'
local table = require 'ext.table'
local range = require 'ext.range'
local Stack = require 'cards.stack'
local Deck = require 'cards.deck'

local Player = class(Stack)

function Player:init(args)
	Player.super.init(self, args)
	self.chips = args.chips 
	self.game = args.game
	self.index = args.index
end

-- simplest AI
-- raiseValue == 0 means you're opening
-- returning 0 means you're checking
-- return 'fold' to fold
-- minRaise is only set when raiseValue == 0, then it is the minimum that you can raise by
-- TODO specify the raise increments
function Player:callOrRaise(raiseValue, minRaise)
	if raiseValue == 0 then return minRaise end
	if raiseValue > self.chips then return 'fold' end
	if self.predictScore < .2 then return 'fold' end
	if self.predictScore > .7 then 
		if minRaise and minRaise > self.chips then return raiseValue end
		return math.max(minRaise or 0, raiseValue + 10)
	end
	return raiseValue
end

function Player:name()
	return 'player '..self.index
end

return Player
