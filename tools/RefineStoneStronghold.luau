--!strict
-- Refinement for the task-owned first draft. Original kingdom and central castle remain untouched.
assert(not game:GetService("RunService"):IsRunning(), "Stop Play")
local t = game.ServerStorage.KingdomTemplate
assert(game.ServerStorage:FindFirstChild("StoneStrongholdBackup_20261118"), "Missing original backup")
assert(t:GetAttribute("StrongholdRefined") ~= true, "Already refined")
local stone = t.PurchaseUnlocks.StoneWalls
local pivot = t:GetPivot()
-- Lower the tower ring to deck height, opening every wall-walk junction.
for _, v in stone:GetChildren() do
	if v:IsA("BasePart") and v.Name == "TowerMasonry" then
		local frame = pivot:ToObjectSpace(v.CFrame)
		v.Size = Vector3.new(v.Size.X, 24, v.Size.Z)
		v.CFrame = pivot * (frame - Vector3.new(0, 2, 0))
	elseif v:IsA("BasePart") and v.Name == "TowerMerlon" then
		local frame = pivot:ToObjectSpace(v.CFrame)
		v.Size = Vector3.new(v.Size.X, 7, v.Size.Z)
		v.CFrame = pivot * (frame - Vector3.new(0, 2, 0))
	end
end
-- Genuine copies of the central castle's authored masonry details.
local source: BasePart?
for _, v in workspace.Walls:GetDescendants() do
	if v:IsA("Part") and not v:FindFirstChildOfClass("SpecialMesh") then
		source = v
		break
	end
end
assert(source, "No reusable central masonry")
for i, x in { -17, 17 } do
	local cap = source:Clone()
	for _, child in cap:GetChildren() do
		child:Destroy()
	end
	cap.Name = "CastleCopiedCap" .. i
	cap.Size = Vector3.new(8, 1, 10)
	cap.Anchored = true
	cap.CanTouch = false
	cap.CFrame = pivot * CFrame.new(x, 30, 74)
	cap.Parent = stone
end
-- Equip medieval silhouettes using script-free welded props.
for _, rig in t.ResidentTemplates:GetChildren() do
	local head = rig:FindFirstChild("Head") :: BasePart
	local torso = rig:FindFirstChild("UpperTorso") :: BasePart
	local function prop(
		name: string,
		size: Vector3,
		host: BasePart,
		offset: CFrame,
		color: Color3,
		material: Enum.Material
	)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = host.CFrame * offset
		p.Color = color
		p.Material = material
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.Massless = true
		p.Parent = rig
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = host
		weld.Part1 = p
		weld.Parent = p
		return p
	end
	prop(
		"LeatherBelt",
		Vector3.new(2.1, 0.25, 1.1),
		torso,
		CFrame.new(0, -0.8, 0),
		Color3.fromRGB(71, 44, 27),
		Enum.Material.Leather
	)
	if rig.Name == "Archer" then
		prop(
			"IronHelmet",
			Vector3.new(1.25, 0.6, 1.25),
			head,
			CFrame.new(0, 0.4, 0),
			Color3.fromRGB(115, 120, 130),
			Enum.Material.Metal
		)
		prop(
			"HelmetBrow",
			Vector3.new(1.4, 0.18, 1.4),
			head,
			CFrame.new(0, 0.15, 0),
			Color3.fromRGB(150, 150, 158),
			Enum.Material.Metal
		)
		local hand = rig:FindFirstChild("LeftHand") :: BasePart
		for i = -1, 1 do
			prop(
				"BowLimb",
				Vector3.new(0.16, 1, 0.2),
				hand,
				CFrame.new(0, i * 0.8, -0.5) * CFrame.Angles(0, 0, i * 0.4),
				Color3.fromRGB(111, 67, 34),
				Enum.Material.Wood
			)
		end
		prop(
			"BowString",
			Vector3.new(0.035, 2.6, 0.035),
			hand,
			CFrame.new(0.35, 0, -0.5),
			Color3.fromRGB(222, 207, 170),
			Enum.Material.Fabric
		)
		prop(
			"Quiver",
			Vector3.new(0.6, 1.7, 0.6),
			torso,
			CFrame.new(0.5, 0, 0.8) * CFrame.Angles(0, 0, -0.2),
			Color3.fromRGB(92, 55, 29),
			Enum.Material.Leather
		)
	elseif rig.Name == "Worker" then
		prop(
			"Apron",
			Vector3.new(1.6, 1.6, 0.15),
			torso,
			CFrame.new(0, -0.3, -0.55),
			Color3.fromRGB(175, 150, 108),
			Enum.Material.Fabric
		)
	else
		prop(
			"ClothCap",
			Vector3.new(1.3, 0.4, 1.3),
			head,
			CFrame.new(0, 0.55, 0),
			Color3.fromRGB(118, 73, 48),
			Enum.Material.Fabric
		)
	end
end
-- Cardinal openings keep the six-stud wall-walk unobstructed through corner decks.
for _, v in stone:GetChildren() do
	if v:IsA("BasePart") and v.Name == "TowerMerlon" then
		local p = pivot:PointToObjectSpace(v.Position)
		local cx = if p.X < 0 then -106 else 106
		local cz = if p.Z < 0 then -138 else 74
		if math.abs(p.X - cx) < 4 or math.abs(p.Z - cz) < 4 then
			v:Destroy()
		end
	end
end
t:SetAttribute("StrongholdRefined", true)
return "Corner passage height repaired; central masonry copied; medieval props equipped"
