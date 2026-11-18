--!strict
local Config = require(game:GetService("ReplicatedStorage").Shared.RebirthConfig)
local State = {}
function State.Requests()
	local serial = 0
	local activeId: number? = nil
	local activeRebirths: number? = nil
	return {
		Begin = function(rebirths: number): number?
			if activeId ~= nil then
				return nil
			end
			serial += 1
			activeId = serial
			activeRebirths = rebirths
			return serial
		end,
		Resolve = function(id: number, rebirths: number): boolean
			if activeId ~= id or activeRebirths ~= rebirths then
				return false
			end
			activeId = nil
			activeRebirths = nil
			return true
		end,
		Busy = function(): boolean
			return activeId ~= nil
		end,
	}
end
function State.Presentation(
	ready: boolean,
	gold: number,
	rebirths: number,
	doubleGold: boolean,
	alive: boolean,
	hasKingdom: boolean,
	busy: boolean
)
	local target = Config.Target(rebirths)
	local multiplier = if doubleGold then 2 else 1
	local available = ready and target ~= nil and gold >= target and alive and hasKingdom
	local status = if not ready
		then "Loading your progress…"
		elseif target == nil then "Maximum rebirth target reached"
		elseif not alive then "Respawn to rebirth"
		elseif not hasKingdom then "Claim a kingdom to rebirth"
		elseif gold < target then "Collect more Gold to rebirth"
		else "Ready to rebirth"
	return {
		Target = target,
		Progress = if ready and target then math.clamp(gold / target, 0, 1) else 0,
		Enabled = available and not busy,
		CurrentMultiplier = Config.Multiplier(rebirths) * multiplier,
		NextMultiplier = Config.Multiplier(rebirths + 1) * multiplier,
		Status = if busy then "Rebirthing…" else status,
	}
end
return State
