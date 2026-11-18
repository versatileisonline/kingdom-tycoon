--!strict
local Tests = {}
function Tests.Run(): ()
	local Players = game:GetService("Players")
	local Shared = game:GetService("ReplicatedStorage").Shared
	local Data = require(script.Parent.Parent.Services.DataService)
	local Plots = require(script.Parent.Parent.Services.PlotService)
	assert(
		game:GetService("RunService"):IsStudio() and Data.GetStorageMode() == "Mock",
		"Entry tests require Studio Mock"
	)
	require(script.Parent.EntrySessionTests).Run(require(script.Parent.Parent.Entry.EntrySession))
	local deadline = os.clock() + 15
	local player: Player? = nil
	repeat
		player = Players:GetPlayers()[1]
		if
			player
			and player.Character
			and player.Character:FindFirstChild("HumanoidRootPart")
			and Data.GetSnapshot(player)
		then
			break
		end
		task.wait(0.1)
	until os.clock() >= deadline
	assert(player and player.Character, "No ready test player")
	assert(Plots.GetPlotId(player) == nil, "Run entry tests before claiming")
	local character = player.Character
	local original = character:GetPivot()
	local count = workspace.Plots:GetAttribute("AvailablePlotCount")
	local ok, reason = pcall(function()
		assert(Plots.TryEnter(player :: Player), "No safe free-plot placement")
		assert(Plots.GetPlotId(player :: Player) == nil, "Entry claimed land")
		assert(workspace.Plots:GetAttribute("AvailablePlotCount") == count, "Entry reserved land")
		local found = false
		for _, plot in workspace.Plots:GetChildren() do
			local marker = plot:FindFirstChild("ClaimMarker")
			if marker and marker:IsA("BasePart") then
				local delta = character:GetPivot().Position - marker.Position
				local distance = Vector3.new(delta.X, 0, delta.Z).Magnitude
				if distance > 8 and distance <= require(Shared.MainMenuConfig).ENTRY_OFFSET + 1 then
					found = true
				end
			end
		end
		assert(found, "Arrival is not safely beside a Claim plate")
	end)
	character:PivotTo(original)
	assert(ok, tostring(reason))
	print("All main menu placement checks passed")
end
return Tests
