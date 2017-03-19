#!/usr/bin/env luajit
math.randomseed(os.time())
local Game = require 'game'
local game = Game{
	numPlayers = tonumber(... or 2) or 2,
}
game:play()
