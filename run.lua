#!/usr/bin/env luajit
math.randomseed(os.time())
local Game = require 'game'
local game = Game()
game:play()
