--!strict
local MAX = 9007199254740991
local copy: { [string]: string } = {}
local Config = {
	BASE_TARGET = 100000,
	TARGET_GROWTH = 2,
	BONUS_PER_REBIRTH = 0.5,
	REMOTE_FOLDER = "KingdomRebirth",
	REQUEST_COOLDOWN = 1,
	REQUEST_TIMEOUT = 10,
	RUN_TESTS_IN_STUDIO = false,
	ART_ATLAS = "rbxassetid://98116548422890",
	UI = table.freeze({ PanelWidth = 840, PanelHeight = 650 }),
	COPY = table.freeze(copy),
}
function Config.Target(rebirths: number): number?
	if rebirths ~= rebirths or rebirths < 0 or rebirths % 1 ~= 0 or rebirths > 36 then
		return nil
	end
	local target = Config.BASE_TARGET * Config.TARGET_GROWTH ^ rebirths
	return if target <= MAX then target else nil
end
function Config.Multiplier(rebirths: number): number
	return 1 + Config.BONUS_PER_REBIRTH * rebirths
end
return table.freeze(Config)
