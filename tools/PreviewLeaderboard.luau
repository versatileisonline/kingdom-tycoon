--!strict
-- Run in the Client Command Bar during Studio Play, after opening Ranks.
-- Unmapped, client-only fixture. X removes it; Stop discards all preview state.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
assert(RunService:IsStudio() and RunService:IsClient(), "Use a Studio Play client")
local player = Players.LocalPlayer
assert(player:GetAttribute("KingdomEntered") == true, "Enter the game before opening the preview")
local gui = player:WaitForChild("PlayerGui")
assert(not gui:FindFirstChild("KingdomLeaderboardPreview"), "Close the existing preview first")
local live = gui:WaitForChild("KingdomLeaderboard") :: ScreenGui
local livePanel = live:WaitForChild("Panel") :: Frame
assert(live.Enabled and livePanel.Visible, "Open Ranks before running the preview")
local client = player.PlayerScripts:WaitForChild("Client")
local State = require(client.UI.LeaderboardState)
local View = require(client.UI.LeaderboardView)
local view = View.new(gui, player.UserId)
view.Screen.Name = "KingdomLeaderboardPreview"
view.Screen.DisplayOrder += 1
view.Screen:SetAttribute("SimulatedEntryCount", Players.MaxPlayers)
local names = { "Aldric", "Rowan", "Eleanor", "Cedric", "Isolde", "Thorne", "Maribel", "Gareth" }
local entries: { State.Entry } = {}
for rank = 1, Players.MaxPlayers do
	table.insert(entries, {
		UserId = if rank == 1 then player.UserId else math.min(0, player.UserId) - rank,
		Name = if rank == 1
			then player.DisplayName
			elseif rank == 2 then "TheLongestKnightNameInTheKingdom"
			else names[(rank - 1) % #names + 1] .. "_" .. rank,
		LifetimeGold = if rank == 1 then 9007199254740991 else (Players.MaxPlayers - rank) * 1240500,
		Rebirths = if rank == 1 then 999999 else Players.MaxPlayers - rank,
	})
end
local portraits = {}
local row = livePanel.Players:FindFirstChild(tostring(player.UserId))
if row then
	portraits[player.UserId] = row.Avatar.Image
end
view.Render(State.Sort(entries), portraits)
-- fit() hides subtitle/footer on short screens; the banner remains visible.
view.Panel.RoyalBanner.Title.Text = "PREVIEW: " .. Players.MaxPlayers .. " PLAYERS"
local subtitle = view.Panel.Subtitle :: TextLabel
subtitle.Text = "PREVIEW: " .. Players.MaxPlayers .. " simulated players"
local footer = view.Panel.Footer :: TextLabel
footer.Text = "Simulated list | Tab: close | X: exit preview"
local connections: { RBXScriptConnection } = {}
local function closeWithLiveMenu(): ()
	if not live.Enabled or not livePanel.Visible then
		view.Screen:Destroy()
	end
end
-- Observe the real GUI: Command Bar and gameplay scripts can have separate
-- require caches, so requiring a controller here would create unrelated state.
table.insert(connections, livePanel:GetPropertyChangedSignal("Visible"):Connect(closeWithLiveMenu))
table.insert(connections, live:GetPropertyChangedSignal("Enabled"):Connect(closeWithLiveMenu))
table.insert(connections, view.Screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(view.Fit))
table.insert(
	connections,
	view.Close.Activated:Connect(function()
		view.Screen:Destroy()
	end)
)
view.Screen.Destroying:Once(function()
	for _, connection in connections do
		connection:Disconnect()
	end
end)
view.SetOpen(true)
view.Fit()
print("[LeaderboardPreview] " .. Players.MaxPlayers .. " simulated entries; X exits; saved data untouched")
