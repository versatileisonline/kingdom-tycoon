--!strict
local Tests = {}
function Tests.Run(Settings: any): ()
	local gui = game.Players.LocalPlayer.PlayerGui:WaitForChild("KingdomHUD")
	local panel = gui.SettingsShade.SettingsPanel
	local art = require(game.ReplicatedStorage.Shared.HudConfig).ART
	assert(
		gui.GoldBadge.CurrencyRow.Coin:IsA("ImageLabel") and gui.GoldBadge.CurrencyRow.Coin.Image == art.Coin,
		"HUD coin artwork missing"
	)
	assert(
		panel.RoyalBanner.Image == art.Banner and panel.GoldCorner1.Image == art.Corner,
		"Royal settings artwork missing"
	)
	local function settle(): ()
		task.wait(0.15)
	end
	Settings.Set("MenuOpen", true)
	settle()
	assert(gui.SettingsShade.Visible, "Settings panel did not open")
	local group = Instance.new("SoundGroup")
	group.Volume = 0.2
	group.Parent = game.SoundService
	local sample = Instance.new("Sound")
	sample.Volume = 0.8
	sample.SoundGroup = group
	sample.Parent = workspace
	settle()
	Settings.Set("Music", 0)
	Settings.Set("WorldSounds", 0.4)
	settle()
	assert(
		game.SoundService.KingdomMusic.Volume == 0 and math.abs(game.SoundService.KingdomWorld.Volume - 0.4) < 0.001,
		"Independent volume controls failed"
	)
	assert(panel.MusicValue.Text == "0%" and panel.WorldSoundsValue.Text == "40%", "Sliders did not update")
	assert(
		sample.SoundGroup == group and math.abs(sample.Volume - 0.32) < 0.001 and math.abs(group.Volume - 0.2) < 0.001,
		"Authored sound group changed"
	)
	sample:Destroy()
	group:Destroy()
	local shadows = game.Lighting.GlobalShadows
	local bloom = game.Lighting:FindFirstChildOfClass("BloomEffect")
	local previous = if bloom then bloom.Enabled else false
	Settings.Set("LowGraphics", true)
	settle()
	assert(not game.Lighting.GlobalShadows and (not bloom or not bloom.Enabled), "Low graphics failed")
	local particle = Instance.new("ParticleEmitter")
	particle.Enabled = true
	particle.Parent = workspace.Terrain
	settle()
	assert(not particle.Enabled, "New effects not reduced")
	Settings.Set("LowGraphics", false)
	settle()
	assert(
		game.Lighting.GlobalShadows == shadows and (not bloom or bloom.Enabled == previous) and particle.Enabled,
		"Graphics not restored"
	)
	particle:Destroy()
	Settings.Set("HelperArrow", false)
	settle()
	assert(not game.Players.LocalPlayer.PlayerGui.FirstPurchaseArrow.Enabled, "Helper setting ignored")
	Settings.Set("Music", 0.25)
	Settings.Set("WorldSounds", 1)
	Settings.Set("HelperArrow", true)
	Settings.Set("MenuOpen", false)
	settle()
	assert(not gui.SettingsShade.Visible, "Settings did not close")
	print("All HUD client checks passed")
end
return Tests
