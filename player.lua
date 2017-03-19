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
function Player:callOrRaise(currentBid, minRaise)
	-- opening
	if currentBid == 0 then return minRaise end	

	-- bad hand - fold
	if self.predictScore < .2 then return 'fold' end
	
	-- good hand - raise
	if self.predictScore > .7 then 
		-- TODO only raise so far based on how good the hand is
		-- that means keep track of what your best hand is from the probability section
		if currentBid > minRaise * 3 then return currentBid + minRaise end
	end
	
	-- call
	return currentBid
end

function Player:name()
	return 'player '..self.index
end

return Player
