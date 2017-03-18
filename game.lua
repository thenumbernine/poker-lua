local class = require 'ext.class'
local table = require 'ext.table'
local range = require 'ext.range'
local Player = require 'player'
local Deck = require 'cards.deck'
local Game = class()
Game.pot = 0
Game.smallBlind = 5
Game.bigBlind = 10
Game.openValue = 10
function Game:init(args)
	self.deck = Deck():shuffle()
	self.players = range(args and args.numPlayers or 2):map(function()
		return Player{game=self, chips=1500}
	end)
	self.up = table()
end
function Game:play()
	for openingPlayerIndex=1,#self.players do
		self:playRound(openingPlayerIndex)
		break
	end
end
function Game:playRound(openingPlayerIndex)

print'############################## BEGIN ROUND ##############################'
	-- don't reset the pot in case there's something left over from last round (what do you do with those chips anyways?)
	self.up = table()
	
	local players = range(#self.players):map(function(i)
		return self.players[(openingPlayerIndex+i-1)%#self.players+1]
	end)

print('player '..openingPlayerIndex..' deals')
self:print(players)

	while not self:payBlind(players[1], self.smallBlind) do
		players:remove(1)
		if #players == 1 then
			self:winGame(players[1])
			return	
		end
	end
print('player '..self.players:find(players[1])..' pays small blind')
self:print(players)
	players:insert(players:remove(1))

	while not self:payBlind(players[1], self.bigBlind) do
		players:remove(1)
		if #players == 1 then
			self:winGame(players[1])	-- win game?
			return	
		end
	end
print('player '..self.players:find(players[1])..' pays big blind')
self:print(players)
	players:insert(players:remove(1))

	-- round starts at the player after the blinds?  or who deals again?
	local firstPlayer = players[1]

	local opened
	repeat
		self.deck = Deck():shuffle()
		self:dealHands(players)
print'dealing hands...'
self:print(players)

		local i=1
		while i <= #players do
			local player = players[1]
			local play = 
				player.chips >= self.openValue
				and player:checkOrOpen(self.openValue)
				or 'check'
			if play == 'open' then
				opened = true
				player.chips = player.chips - self.openValue
				self.pot = self.pot + self.openValue
				
				-- can you even do this?  open and drive yourself broke, out of the hand, and out of the game?
				if player.chips == 0 then
print('player '..self.players:find(player)..' opened and went broke')
self:print(players)
					if players:remove(1) == firstPlayer then
						firstPlayer = players[1]
					end
					
					break	-- no need to cycle players if we've already removed ourselves
				end
			end
print('player '..self.players:find(player)..' '..play)
self:print(players)
			-- cycle players
			players:insert(players:remove(1))
			if play == 'open' then break end
			i = i + 1
		end
		-- if no one opens then reshuffle and redeal 
	until opened

	for flop=0,3 do
		
		
		-- if flop == 0 then we are continuing off of the open routine above
		-- in fact I could move that in here..
		if flop>0 then
			-- what if the first player folds?  then we should take the next player, otherwise this will crash / infinite loop
			assert(players:find(firstPlayer))
			while players[1] ~= firstPlayer do
				players:insert(players:remove(1))
			end
		end

		if flop==1 then
			self.up:insert(self.deck.cards:remove())
			self.up:insert(self.deck.cards:remove())
			self.up:insert(self.deck.cards:remove())
		elseif flop>1 then
			self.up:insert(self.deck.cards:remove())
		end

print('starting flop '..flop)
print('opening bid is '..self.openValue)
self:print(players)

		local raiseValue = self.openValue

		while true do
			local i=1
			while i <= #players do
				local player = players[1]
				if player.chips < raiseValue then
					-- not enough money -- can't play this round anymore
					if players:remove(1) == firstPlayer then
						firstPlayer = players[1]
					end
print('player.chips',player.chips,'raiseValue',raiseValue)
print('player '..self.players:find(player)..' folds')
self:print(players)
				else
					local newRaiseValue = player:callOrRaise(raiseValue)
					player.chips = player.chips - newRaiseValue
					self.pot = self.pot + newRaiseValue
					local raised = newRaiseValue > raiseValue
assert(not raised)
					raiseValue = newRaiseValue
print('player '..self.players:find(player)..' '..(raised and 'raises to '..raiseValue or 'calls'))					
self:print(players)					
					players:insert(players:remove(1))
					if raised then 
print('breaking out because we raised')						
						break 
					end
					i = i + 1	
				end
			end
			if i > #players then break end
		end
	end

	local playerScores = players:map(function(player,i,t)
		local score, hand = self:scoreBestHand(player)
		return {player=player, score=score, hand=hand},#t+1
	end)
	playerScores:sort(function(a,b) return a.score > b.score end)
	local winningScore = playerScores[1]
	local winners = playerScores:filter(function(a) return a.score == winningScore.score end)
print()
print('#winners: '..#winners)
	for _,winner in ipairs(winners) do
		winner.player.chips = winner.player.chips + math.floor(self.pot / #winners)
print('player '..self.players:find(winner.player)..' won with hand '..winner.hand:map(tostring):concat' '..' '..tostring(winner.score))
	end
	self.pot = self.pot % #winners
self:print(players)
	
	if #players == 1 then
		self:winGame(players[1])
	end

end
function Game:print(playersActive)
	print()
	for i,player in ipairs(self.players) do
		local folded = not playersActive:find(player)
		print('player '..i..' has $'..player.chips
			..', hand '..player.cards:map(tostring):concat' '
			..(folded and ' and has folded' or ''))
	end
	print('cards up:'..self.up:map(tostring):concat' ')
	print('pot: $'..self.pot)
end
function Game:payBlind(player, blind)
	if player.chips < blind then return false end
	player.chips = player.chips - blind
	self.pot = self.pot + blind
	return true
end
function Game:dealHands(players)
	for _,player in ipairs(players) do
		player.cards = range(2):map(function() return self.deck.cards:remove() end)
	end
end
function Game:scoreBestHand(player)
	local cards = table(self.up):append(player.cards)
	local bestScore, bestHand
print()
print('checking score of player '..self.players:find(player)..' from cards '..cards:map(tostring):concat' ')
	for i1=1,#cards-4 do
		for i2=i1+1,#cards-3 do
			for i3=i2+1,#cards-2 do
				for i4=i3+1,#cards-1 do
					for i5=i4+1,#cards do
						local is = table{i1,i2,i3,i4,i5}
						local hand = is:map(function(i) return cards[i] end)
						local score, hand = Game:scoreHand(hand)
print('considering option '..hand:map(tostring):concat' '..' with score '..tostring(score))
						if not bestScore or score > bestScore then
							bestScore = score
							bestHand = hand
						end
					end
				end
			end
		end
	end
print('player '..self.players:find(player)..' best option is '..bestHand:map(tostring):concat' '..' with score '..tostring(bestScore))
	return bestScore, bestHand
end
function Game:winGame(player)
	print('player '..self.players:find(player)..' won with $'..player.chips)
error'here'
end
local Score = class()
function Score:init(...)
	for i=1,select('#',...) do self[i] = select(i, ...) end
end
function Score.__lt(a,b)
	for i=1,math.min(#a,#b) do
		if a[i] < b[i] then return true end
		if a[i] > b[i] then return false end
	end
	return false
end
function Score.__eq(a,b)
	if #a ~= #b then return false end
	for i=1,#a do
		if a[i] ~= b[i] then return false end
	end
	return true
end
Score.names = {
	'high card',
	'pair',
	'two pair',
	'three of a kind',
	'straight',
	'flush',
	'full house',
	'four of a kind',
	'straight flush',
}
function Score:__tostring()
	return self.names[self[1]]..' '..table.concat({table.unpack(self,2)}, '.')
end
function Game:scoreHand(hand)
	local function value(card) return card.value == 1 and 14 or card.value end
	local byValue = table(hand):sort(function(a,b) return value(a) > value(b) end)
	local bySuit = table(hand):sort(function(a,b) return a.suit > b.suit end)

	local flush = #hand:filter(function(card) return card.suit == hand[1].suit end) == 5
	local straight = #byValue:filter(function(card,i) return value(byValue[1]) == value(card) + i-1 end) == 5

	local ofAKind = table()	-- ex: ofAKind[13] = table of all kings
	for _,card in ipairs(hand) do
		ofAKind[card.value] = ofAKind[card.value] or table()
		ofAKind[card.value]:insert(card)
	end
	-- cardPairs[1] is the largest # of any kind
	-- if two pair then cardPairs[1] is the larger of the two pairs
	local cardPairs = ofAKind:values():sort(function(a,b) 
		if #a == #b then return value(a[1]) > value(b[1]) end
		return #a > #b 
	end)

	local valuesOfPairs = cardPairs:map(function(pair) return value(pair[1]) end)

	local sortedHand = table():append(cardPairs:unpack())

	-- royal flush / straight flush
	if flush and straight then return Score(9, valuesOfPairs:unpack()), sortedHand end	-- can't have a pair so byValue:map(value) == valuesOfPairs
	-- four of a kind
	if #cardPairs[1] == 4 then return Score(8, valuesOfPairs:unpack()), sortedHand end
	-- full house
	if #cardPairs[1] == 3 and #cardPairs[2] == 2 then return Score(7, valuesOfPairs:unpack()), sortedHand end
	-- flush
	if flush then return Score(6, valuesOfPairs:unpack()), sortedHand end	-- can't have a pair so likewise
	-- straight
	if straight then return Score(5, valuesOfPairs:unpack()), sortedHand end	-- can't have a pair, so same
	-- three of a kind
	if #cardPairs[1] == 3 then return Score(4, valuesOfPairs:unpack()), sortedHand end
	-- two pair
	if #cardPairs[1] == 2 and #cardPairs[2] == 2 then return Score(3, valuesOfPairs:unpack()), sortedHand end
	-- one pair
	if #cardPairs[1] == 2 then return Score(2, valuesOfPairs:unpack()), sortedHand end
	-- high card
	return Score(1, valuesOfPairs:unpack()), sortedHand
end
return Game
