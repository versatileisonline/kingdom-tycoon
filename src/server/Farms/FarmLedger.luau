--!strict

-- Private session accounting. Keys are registered physical bundles in production;
-- tests use standalone tokens. Neither attributes nor client values grant credit.
local SessionEarnings = require(script.Parent.SessionEarnings)
local FarmLedger = {}

export type Ledger = {
	Register: (token: any, now: number) -> boolean,
	ApplyUpgrade: (token: any, upgraderId: string, multiplier: number, now: number) -> boolean,
	GetValue: (token: any) -> number?,
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
	local bundles: { [any]: { Expires: number, Value: number, Applied: { [string]: boolean } } } = {}
	local count = 0
	local account = sharedAccount or SessionEarnings.new(maxBalance)
	return {
		Register = function(token: any, now: number): boolean
			if count >= cap or bundles[token] ~= nil then
				return false
			end
			bundles[token] = { Expires = now + lifetime, Value = value, Applied = {} }
			count += 1
			return true
		end,
		ApplyUpgrade = function(token: any, upgraderId: string, multiplier: number, now: number): boolean
			local record = bundles[token]
			if
				record == nil
				or now ~= now
				or now >= record.Expires
				or #upgraderId == 0
				or record.Applied[upgraderId]
				or multiplier ~= multiplier
				or multiplier <= 1
				or multiplier % 1 ~= 0
				or record.Value > maxBalance / multiplier
			then
				return false
			end
			record.Value *= multiplier
			record.Applied[upgraderId] = true
			return true
		end,
		GetValue = function(token: any): number?
			local record = bundles[token]
			return if record then record.Value else nil
		end,
		Remove = function(token: any, now: number, arrived: boolean): boolean
			local record = bundles[token]
			if record == nil then
				return false
			end
			bundles[token] = nil -- Consume before crediting; repeated pit contacts are harmless.
			count -= 1
			if arrived and now < record.Expires and account.Credit(record.Value) then
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
