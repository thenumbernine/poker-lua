local class = require 'ext.class'
local Player = require 'player'
local HumanPlayer = class(Player)

function HumanPlayer:callOrRaise(raiseValue, minRaise)
	while true do
		print(raiseValue..' to you')
		print('what would you like to do? [c]all/check, [r]aise, [f]old?')
		local cmd = io.read'*l':lower():sub(1,1)
		if cmd == 'c' then
			print'calling...'
			return raiseValue
		elseif cmd == 'f' then
			print'folding...'
			return 'fold'
		elseif cmd == 'r' then
			print('raise how much?'..(minRaise and (' (min raise '..minRaise..')') or ''))
			io.write'> '
			io.flush()
			local amountcmd = io.read'*l'
			local amount = tonumber(amountcmd)
			if amount 
			and (not minRaise or amount > minRaise) 
			and amount < self.chips
			then 
				print('raising by '..amount)
				return amount 
			end
			print("can't raise by "..amountcmd)
		else
		print("I don't understand "..cmd)
		end
	end
end

function HumanPlayer:name()
	return 'human '..self.index
end

return HumanPlayer
