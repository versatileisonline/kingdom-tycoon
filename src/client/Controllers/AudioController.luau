--!strict
local SoundService = game:GetService("SoundService")
local Settings = require(script.Parent.SettingsController)
local Config = require(game:GetService("ReplicatedStorage").Shared.HudConfig)
local Controller = {}
local connections: { RBXScriptConnection } = {}
local originals: { [Sound]: { Group: SoundGroup?, Volume: number } } = {}
local music: Sound? = nil
local musicGroup: SoundGroup? = nil
local worldGroup: SoundGroup? = nil
local running = false
function Controller.Init(): () end
function Controller.Start(): ()
	if running then
		return
	end
	running = true
	local mg = Instance.new("SoundGroup")
	mg.Name = "KingdomMusic"
	mg.Parent = SoundService
	musicGroup = mg
	local wg = Instance.new("SoundGroup")
	wg.Name = "KingdomWorld"
	wg.Parent = SoundService
	worldGroup = wg
	local sound = Instance.new("Sound")
	sound.Name = "KingdomBackgroundMusic"
	sound.Looped = true
	sound.Volume = 1
	sound.SoundGroup = mg
	sound.Parent = SoundService
	music = sound
	local function volumes(): ()
		mg.Volume = Settings.Get("Music") :: number
		wg.Volume = Settings.Get("WorldSounds") :: number
		for item, original in originals do
			if original.Group ~= nil then
				item.Volume = original.Volume * wg.Volume
			end
		end
	end
	local function route(item: Instance): ()
		if item:IsA("Sound") and item ~= sound and originals[item] == nil then
			originals[item] = { Group = item.SoundGroup, Volume = item.Volume }
			if item.SoundGroup == nil then
				item.SoundGroup = wg
			else
				item.Volume = item.Volume * (Settings.Get("WorldSounds") :: number)
			end
		end
	end
	volumes()
	table.insert(
		connections,
		Settings.Observe(function(): ()
			volumes()
		end)
	)
	for _, root in { workspace, SoundService } do
		for _, item in root:GetDescendants() do
			route(item)
		end
		table.insert(connections, root.DescendantAdded:Connect(route))
		table.insert(
			connections,
			root.DescendantRemoving:Connect(function(item: Instance): ()
				if item:IsA("Sound") then
					local original = originals[item]
					if original then
						item.SoundGroup = original.Group
						item.Volume = original.Volume
						originals[item] = nil
					end
				end
			end)
		)
	end
	task.spawn(function(): ()
		for _, id in Config.MUSIC_IDS do
			if not running then
				return
			end
			sound.SoundId = "rbxassetid://" .. id
			sound:Play()
			local deadline = os.clock() + Config.MUSIC_LOAD_SECONDS
			repeat
				task.wait(0.1)
			until not running or sound.IsLoaded or os.clock() >= deadline
			if not running then
				return
			end
			if sound.IsLoaded then
				print("[KingdomTycoon][AudioController] Music loaded: " .. id)
				return
			end
			sound:Stop()
		end
		warn("[KingdomTycoon][AudioController] Background music unavailable")
	end)
	table.insert(connections, script.Destroying:Connect(Controller.Shutdown))
end
function Controller.Shutdown(): ()
	running = false
	for _, c in connections do
		c:Disconnect()
	end
	table.clear(connections)
	for sound, original in originals do
		sound.SoundGroup = original.Group
		sound.Volume = original.Volume
	end
	table.clear(originals)
	if music then
		music:Destroy()
		music = nil
	end
	if musicGroup then
		musicGroup:Destroy()
		musicGroup = nil
	end
	if worldGroup then
		worldGroup:Destroy()
		worldGroup = nil
	end
end
return Controller
