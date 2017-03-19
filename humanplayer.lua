local class = require 'ext.class'
local Player = require 'player'
local HumanPlayer = class(Player)

function HumanPlayer:callOrRaise(currentBid, minRaise)
	while true do
		print(currentBid..' to you')
		io.write('what would you like to do? ([c]all/check), [r]aise, [f]old? ')
		io.flush()

		local parts = io.read'*l':trim():split'%s+'
		local cmd = parts:remove(1)
		cmd = cmd:lower():sub(1,1)

		if cmd == '' then cmd = 'c' end	-- default call/check

		if cmd == 'c' then
			print'calling...'
			return currentBid
		elseif cmd == 'f' then
			print'folding...'
			return 'fold'
		elseif cmd == 'r' then
			local amountcmd
			if #parts > 0 then
				amountcmd = parts:remove(1)
			else
				io.write('raise to how much?'..(minRaise and (' (min raise '..minRaise..')') or '')..' ')
				io.flush()
				amountcmd = io.read'*l'
			end
			local amount = tonumber(amountcmd)
			if amount and (amount >= minRaise or amount == self.chips) then 
				print('raising by '..amount)
				return currentBid + amount 
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
