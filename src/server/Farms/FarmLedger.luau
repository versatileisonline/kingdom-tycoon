--!strict

-- Private session accounting. Keys are registered physical bundles in production;
-- tests use standalone tokens. Neither attributes nor client values grant credit.
local FarmLedger = {}

export type Ledger = {
	Register: (token: any, now: number) -> boolean,
	Remove: (token: any, now: number, arrived: boolean) -> boolean,
	Collect: (commit: (number) -> boolean) -> (boolean, number),
	GetBalance: () -> number,
	GetCount: () -> number,
	Clear: () -> (),
}

function FarmLedger.new(cap: number, lifetime: number, value: number, maxBalance: number): Ledger
	local bundles: { [any]: number } = {}
	local count = 0
	local balance = 0
	return {
		Register = function(token: any, now: number): boolean
			if count >= cap or bundles[token] ~= nil then
				return false
			end
			bundles[token] = now + lifetime
			count += 1
			return true
		end,
		Remove = function(token: any, now: number, arrived: boolean): boolean
			local expires = bundles[token]
			if expires == nil then
				return false
			end
			bundles[token] = nil -- Consume before crediting; repeated pit contacts are harmless.
			count -= 1
			if arrived and now < expires and balance <= maxBalance - value then
				balance += value
				return true
			end
			return false
		end,
		Collect = function(commit: (number) -> boolean): (boolean, number)
			local amount = balance
			if amount == 0 or not commit(amount) then
				return false, 0
			end
			-- The production caller uses DataService.Update, which never yields.
			balance -= amount
			return true, amount
		end,
		GetBalance = function(): number
			return balance
		end,
		GetCount = function(): number
			return count
		end,
		Clear = function(): ()
			table.clear(bundles)
			count = 0
			balance = 0
		end,
	}
end

return FarmLedger
