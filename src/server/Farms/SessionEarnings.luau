--!strict
-- Private per-owner session balance. Production callers must never yield while crediting/collecting.
local SessionEarnings = {}
export type Account = {
	Credit: (number) -> boolean,
	Collect: ((number) -> boolean) -> (boolean, number),
	GetBalance: () -> number,
	Clear: () -> (),
}
function SessionEarnings.new(maxBalance: number): Account
	local balance = 0
	local collecting = false
	return {
		Credit = function(value: number): boolean
			if value ~= value or value <= 0 or value % 1 ~= 0 or balance > maxBalance - value then
				return false
			end
			balance += value
			return true
		end,
		Collect = function(commit: (number) -> boolean): (boolean, number)
			if collecting or balance == 0 then
				return false, 0
			end
			local amount = balance
			collecting = true
			local ok, accepted = pcall(commit, amount)
			collecting = false
			if not ok or not accepted then
				return false, 0
			end
			balance -= amount
			return true, amount
		end,
		GetBalance = function(): number
			return balance
		end,
		Clear = function(): ()
			balance = 0
		end,
	}
end
return SessionEarnings
