local class = require 'ext.class'
local table = require 'ext.table'
local range = require 'ext.range'
local Player = require 'player'
local HumanPlayer = require 'humanplayer'
local Card = require 'cards.card'
local Deck = require 'cards.deck'
require 'ext.meta'
	
-- card value
local function value(card) 
	return card.value == 1 and 14 or card.value 
end

local Game = class()

Game.pot = 0
Game.smallBlind = 5
Game.bigBlind = 10
Game.openValue = 10

function Game:init(args)
	self.deck = Deck():shuffle()
	self.players = range(args and args.numPlayers or 2):map(function(index)
		local playerClass = Player
		if index == 1 then playerClass = HumanPlayer end
		return playerClass{game=self, chips=1500, index=index}
	end)
	self.humanPlayers = self.players:filter(HumanPlayer.is)
	if #self.humanPlayers == 0 then self.humanPlayers = nil end
	self.up = table()
	function self.isWild(card)
		return card.value == 2
			or card.value == 3
	end
end

function Game:play()
	while #self.players > 1 do 
		for openingPlayerIndex=1,#self.players do
			self:playRound(openingPlayerIndex)
		end
		self.players = self.players:filter(function(player) return player.chips > 0 end)
	end
end

function Game:playRound(openingPlayerIndex)

	for _,player in ipairs(self.players) do
		player.cards = table()
	end

print()
print'#### BEGIN ROUND ####'
	-- don't reset the pot in case there's something left over from last round (what do you do with those chips anyways?)
	self.up = table()
	
	local players = range(#self.players):map(function(i)
		return self.players[(openingPlayerIndex+i-1)%#self.players+1]
	end)

print(players[1]:name()..' is dealer')

	while not self:payBlind(players[1], self.smallBlind) do
		players:remove(1)
		if #players == 1 then
			self:winGame(players[1])
self:print(players)
			return	
		end
	end
print(players[1]:name()..' pays small blind')
self:print(players)
	players:insert(players:remove(1))

	while not self:payBlind(players[1], self.bigBlind) do
		players:remove(1)
		if #players == 1 then
			self:winGame(players[1])	-- win game?
self:print(players)
			return	
		end
	end
print(players[1]:name()..' pays big blind')
self:print(players)
	players:insert(players:remove(1))

	-- round starts at the player after the blinds.  this is the dealer.
	-- keep track of the last player to raise.  once it gets back around to him, the round is over.
	local firstPlayer = players[1]
	
	for stage=0,3 do
				
		-- if stage == 0 then we are continuing off of the open routine above
		-- in fact I could move that in here..
		if stage>0 then
			-- what if the last player to raise folds?  then we should take the next player, otherwise this will crash / infinite loop
			assert(players:find(firstPlayer))
			while players[1] ~= firstPlayer do
				players:insert(players:remove(1))
			end
		end

		if stage==0 then
			self.deck = Deck():shuffle()
			self:dealHands(players)
		elseif stage==1 then
			self.up:insert(self.deck.cards:remove())
			self.up:insert(self.deck.cards:remove())
			self.up:insert(self.deck.cards:remove())
		elseif stage>1 then
			self.up:insert(self.deck.cards:remove())
		end


		self:predictHands(players)

print()
print('starting stage '..stage)
self:print(players)
		local raiseValue = 0	-- when checking.  this will be overridden for stage==0 when we open.

		local lastPlayerToRaise = players[1]

		while true do
			local player = players[1]
				
			local newRaiseValue = player.chips < raiseValue 
				and 'fold' 
				or player:callOrRaise(raiseValue, raiseValue == 0 and self.openValue or nil)
			
			if newRaiseValue == 'fold' then
print(player:name()..' folds')
				if players:remove(1) == firstPlayer then
print('first player '..firstPlayer:name()..' folded, setting new first player to '..players[1]:name())								
					firstPlayer = players[1]
				end
self:print(players)
				if #players == 1 then 
print('all players have folded')						
					break 
				end
			else
				player.chips = player.chips - newRaiseValue
				self.pot = self.pot + newRaiseValue
				local raised = newRaiseValue > raiseValue
				raiseValue = newRaiseValue
print(player:name()..' '..(raised and 'raises to '..raiseValue or 'calls'))
self:print(players)					
				
				if raised then
					lastPlayerToRaise = players[1]
				end

				players:insert(players:remove(1))
	
				if not raised then
					if players[1] == lastPlayerToRaise then
print'all players have called'					
						break
					end
				end
			end
			
			if #players == 1 then break end
		end
		if #players == 1 then break end
	
	end

	assert(#players > 0)
	
	local winners
	if #players > 1 then

		local playerScores = players:map(function(player,i,t)
			local hand = table(self.up):append(player.cards)
			local score, hand = self:scoreBestHand(hand)
			print(player:name()..' best hand '..hand:map(tostring):concat' '..' '..score)
			return {player=player, score=score, hand=hand},#t+1
		end)
		playerScores:sort(function(a,b) return a.score > b.score end)
		local winningScore = playerScores[1]
		winners = playerScores:filter(function(a) return a.score == winningScore.score end)
	else
		winners = table{
			{ 
				player = players[1],
			}
		}
	end
	self:winGame(winners:map(function(winner) return winner.player end))
	self:print(players)
end

function Game:print(playersActive)
	io.write('pot: $',self.pot)
	if #self.up > 0 then io.write(', up: ',self.up:map(tostring):concat' ') end
	for i,player in ipairs(self.players) do
		local folded = not playersActive:find(player)
		if not self.humanPlayers or not folded then
			io.write(', ',player:name(),' $',player.chips,
				#player.cards > 0 
					and (not self.humanPlayers or self.humanPlayers:find(player))
					and (' '..player.cards:map(tostring):concat' ') or '',
				folded and ' folded' or '')
		end
	end
	print()
end

function Game:payBlind(player, blind)
	if player.chips < blind then 
		self.pot = self.pot + player,chips 
		player.chips = 0
		return false 
	end
	player.chips = player.chips - blind
	self.pot = self.pot + blind
	return true
end

function Game:dealHands(players)
	for _,player in ipairs(players) do
		player.cards = range(2):map(function() return self.deck.cards:remove() end)
	end
end


local ReplaceCard = class(Card)

function ReplaceCard:init(args)
	ReplaceCard.super.init(self, args)
	self.original = args.original
end

function Game:replaceWildCards(hand)
	hand = table(hand)
	local wild = table()
	for i=#hand,1,-1 do
		if self.isWild(hand[i]) then
			wild:insert(hand:remove(i))
		end
	end
	if #wild == 0 then return hand end

	local byValue = table(hand):sort(function(a,b) return value(a) > value(b) end)
	local bySuit = table(hand):sort(function(a,b) return a.suit > b.suit end)

	local flush = #hand:filter(function(card) return card.suit == hand[1].suit end) == 5

	--local straight = #byValue:filter(function(card,i) return value(byValue[1]) == value(card) + i-1 end) == 5
-- TODO how to detect intermediately spaced straights?
-- I can handle sequential
-- but what of 2 3 5 6 + Joker ? 
-- first sort by value, then increment along and see if any holes can be filled
	local straightHand = table()
	if #byValue > 0 then	 -- if you have 5 wildcards then it's a 5-of-a-kind and won't be a straight
		local tmpByValue = table(byValue)
		local tmpWild = table(wild)
		local v = value(tmpByValue:last())
		straightHand:insert(tmpByValue:remove())
		for i=1,4 do
			v = v + 1
			if v > 14 then
				if #tmpWild > 0 then
					straightHand:insert(ReplaceCard{suit=byValue[1].suit, value=value(straightHand:last())-1, original=tmpWild:remove()})
				else
					-- if we were counting off a straight and we surpassed 14
					-- and there are still non-wild cards remaining
					-- then we must have a pair somewhere
					-- and can't have a straight
					straightHand = nil
					break
				end
			elseif #tmpByValue > 0 and value(tmpByValue:last()) == v then
				-- found a value card
				straightHand:insert(1, tmpByValue:remove())
			elseif #tmpWild > 0 then
				-- found a wildcard
				straightHand:insert(1, ReplaceCard{suit=byValue[1].suit, value=v, original=tmpWild:remove()})
			else
				straightHand = nil
				break
			end
		end
	end

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

	local function setPairs()
		local firstPair = #cardPairs > 0 and cardPairs[1][1]
		hand:append(wild:map(function(card)
			return not firstPair 
				and ReplaceCard{value=14, suit=1, original=card} 
				or ReplaceCard{value=firstPair.value, suit=firstPair.suit, original=card}
		end))
	end

	-- five of a kind
	if (#cardPairs > 0 and #cardPairs[1] or 0) + #wild >= 5 then 
		setPairs()
	-- royal flush / straight flush
	elseif flush and straightHand then 
		hand = straightHand
	-- four of a kind
	elseif (#cardPairs > 0 and #cardPairs[1] or 0) + #wild == 4 then
		-- can't be 4 cards and 1 wild or 4 wild and 1 card because that would be a 5-of-a-kind
		-- must 3+1, 2+2, or 1+2 cards+wild
		-- in all cases, copy the cardPairs
		setPairs()
	-- full house
	elseif (#cardPairs > 0 and #cardPairs[1] or 0) + (#cardPairs > 1 and #cardPairs[2] or 0) + #wild == 5 then
		-- when can wildcards give you a full house and not a four-of-a-kind?
		-- when you only have 1 wildcard and two-pair
		assert(#wild == 1)
		setPairs()
	-- flush
	elseif flush and #hand + #wild == 5 then
		hand:append(wild:map(function(card) return ReplaceCard{suit=hand[1].suit, value=14, original=card} end))
	-- straight
	elseif straightHand then
		hand = straightHand
	-- three of a kind
	elseif (#cardPairs > 0 and #cardPairs[1] or 0) + #wild == 3 then
		-- can only happen with high card + 2 wild, or pair + 1 wild
		setPairs()
	-- two pair can't appear.  if you have a pair and a wild then it becomes a 3 of a kind
	-- pair appears when you have high card + 1 wild 
	elseif (#cardPairs > 0 and #cardPairs[1] or 0)  + #wild == 2 then
		assert(#wild == 1)
		assert(#cardPairs[1] == 1)
		setPairs()
	end

	return hand
end

function Game:scoreBestHand(cards)
	assert(#cards >= 5)
	local bestScore, bestHand
	for i1=1,#cards-4 do
		for i2=i1+1,#cards-3 do
			for i3=i2+1,#cards-2 do
				for i4=i3+1,#cards-1 do
					for i5=i4+1,#cards do
						local is = table{i1,i2,i3,i4,i5}
						local hand = is:map(function(i) return cards[i] end)
						-- TODO hand now has wildcards replaced.  keep track of the original cards somewhere?
						hand = self:replaceWildCards(hand)
						local score, hand = self:scoreHand(hand)
						for i=1,#hand do hand[i] = hand[i].original or hand[i] end	-- replace best-replacement with original wildcards for displaying 
						if not bestScore or score > bestScore then
							bestScore = score
							bestHand = hand
						end
					end
				end
			end
		end
	end
	return bestScore, bestHand
end

function Game:winGame(winners)
	for _,winner in ipairs(winners) do
		winner.chips = winner.chips + math.floor(self.pot / #winners)
		print(winner:name()..' is a winner')
	end
	self.pot = self.pot % #winners

	for _,player in ipairs(self.players) do player.predictScore = nil end
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
	'five of a kind',
}

function Score:__tostring()
	return self.names[self[1]]..' '..table.concat({table.unpack(self,2)}, '.')
end


function Game:scoreHand(hand)
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
	
	-- five of a kind
	if #cardPairs[1] == 5 then return Score(10, valuesOfPairs:unpack()), sortedHand end
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

--[[
don't allow players to see each other.
for each player, consider their cards vs guessed cards, and give them their own self-score accordingly
--]]
function Game:predictHands(players)
	if not self.humanPlayers then
		print()
	end
	for _,player in ipairs(players) do
		local wins = 0
		local total = 1000
		for tries=1,total do
			local deck = Deck(self.deck)
			local function pickCard() return deck.cards:remove(math.random(#deck.cards)) end
			local up = table(self.up)
			while #up < 5 do up:insert(pickCard()) end	-- guess what cards will come up 
			local otherCards = table{pickCard(), pickCard()}
			
			local score, hand = self:scoreBestHand(table(player.cards):append(up))
			local otherScore, otherHand = self:scoreBestHand(table(otherCards):append(up))
		
			if score > otherScore then
				wins = wins + 1
			end
		end
		player.predictScore = wins / total
		if not self.humanPlayers then
			print(player:name()..' predicts his hand to be '..player.predictScore)
		end
	end
	if not self.humanPlayers then
		print()
	end
end

return Game
