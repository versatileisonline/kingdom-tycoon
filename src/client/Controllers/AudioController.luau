--!strict
local SoundService = game:GetService("SoundService")
local Settings = require(script.Parent.SettingsController)
local Config = require(game:GetService("ReplicatedStorage").Shared.HudConfig)
local MusicPlaylist = require(script.Parent.Parent.Audio.MusicPlaylist)
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
	sound.Looped = false
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
	local playlist = MusicPlaylist.new(Config.MUSIC_IDS)
	local advancing = false
	local function isCurrent(): boolean
		-- A previous Start task must not touch a destroyed Sound after Shutdown/Start.
		return running and music == sound
	end
	local function advance(): ()
		if advancing or not isCurrent() then
			return
		end
		advancing = true
		while isCurrent() do
			local id = playlist.Next()
			if id == nil then
				warn("[KingdomTycoon][AudioController] Background music unavailable")
				break
			end
			sound:Stop()
			sound.SoundId = "rbxassetid://" .. id
			local deadline = os.clock() + Config.MUSIC_LOAD_SECONDS
			repeat
				task.wait(0.1)
			until not isCurrent() or sound.IsLoaded or os.clock() >= deadline
			if not isCurrent() then
				break
			end
			if sound.IsLoaded then
				-- Start only after the new asset is ready; an early Play can be
				-- reset by the asset change after the previous track ends.
				sound.TimePosition = 0
				sound:Play()
				print("[KingdomTycoon][AudioController] Music loaded: " .. id)
				break
			end
			sound:Stop()
			playlist.Fail(id)
			warn("[KingdomTycoon][AudioController] Skipping unavailable music: " .. id)
		end
		advancing = false
	end
	table.insert(
		connections,
		sound.Ended:Connect(function(): ()
			task.spawn(advance)
		end)
	)
	task.spawn(advance)
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
