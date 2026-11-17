--!strict

-- Private session accounting. Keys are registered physical bundles in production;
-- tests use standalone tokens. Neither attributes nor client values grant credit.
local SessionEarnings = require(script.Parent.SessionEarnings)
local FarmLedger = {}

export type Ledger = {
	Register: (token: any, now: number) -> boolean,
	Remove: (token: any, now: number, arrived: boolean) -> boolean,
	Collect: (commit: (number) -> boolean) -> (boolean, number),
	GetBalance: () -> number,
	GetCount: () -> number,
	Clear: () -> (),
}

function FarmLedger.new(
	cap: number,
	lifetime: number,
	value: number,
	maxBalance: number,
	sharedAccount: SessionEarnings.Account?
): Ledger
	local bundles: { [any]: number } = {}
	local count = 0
	local account = sharedAccount or SessionEarnings.new(maxBalance)
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
			if arrived and now < expires and account.Credit(value) then
				return true
			end
			return false
		end,
		Collect = account.Collect,
		GetBalance = account.GetBalance,
		GetCount = function(): number
			return count
		end,
		Clear = function(): ()
			table.clear(bundles)
			count = 0
			if sharedAccount == nil then
				account.Clear()
			end
		end,
	}
end

return FarmLedger
