--!strict
local State = {}
function State.Offer(status: string?, price: number?, available: boolean): (string, boolean)
	if status == "Owned" then
		return "Owned", false
	end
	if status == "Loading" or status == nil then
		return "Loading…", false
	end
	if status == "Unavailable" or not available or price == nil then
		return "Unavailable", false
	end
	return string.format("%d Robux", price), true
end
return State
