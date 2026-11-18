--!strict
-- Non-yielding request policy shared by the live service and deterministic tests.
local Session = {}
function Session.new(cooldown: number, ready: () -> boolean, place: () -> (boolean, string))
	local entered = false
	local previous = -math.huge
	return {
		Entered = function(): boolean
			return entered
		end,
		Request = function(action: unknown, now: number): (boolean, string)
			if action ~= "Play" then
				return false, "Invalid entry request."
			end
			if entered then
				return true, "Welcome to your kingdom."
			end
			if now - previous < cooldown then
				return false, "Please wait before trying again."
			end
			previous = now
			if not ready() then
				return false, "Your character or progress is still loading."
			end
			local success, message = place()
			entered = success
			return success, message
		end,
	}
end
return Session
