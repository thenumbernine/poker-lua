local class = require 'ext.class'
local Stack = require 'cards.stack'
local Player = class(Stack)
function Player:init(args)
	Player.super.init(self, args)
	self.chips = args.chips 
	self.game = args.game
end
function Player:checkOrOpen(price)
	return 'open'
end
function Player:callOrRaise(raiseValue)
	return raiseValue
end
return Player
