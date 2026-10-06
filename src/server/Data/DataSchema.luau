--!strict

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Types = require(Shared:WaitForChild("Types"))
local DATA = Config.DATA

local DataSchema = {}

function DataSchema.Create(): Types.PlayerData
	return {
		SchemaVersion = DATA.SCHEMA_VERSION,
		Gold = DATA.STARTING_GOLD,
		Rebirths = DATA.STARTING_REBIRTHS,
		PurchasedBuildings = {},
	}
end

function DataSchema.IsInteger(value: unknown): boolean
	return type(value) == "number"
		and value == value
		and value >= 0
		and value <= DATA.MAX_SAFE_INTEGER
		and value % 1 == 0
end

function DataSchema.Validate(value: unknown): (boolean, string?)
	if type(value) ~= "table" then
		return false, "Profile must be a plain table"
	end
	local data = value :: { [any]: any }
	if getmetatable(data :: any) ~= nil then
		return false, "Profile must be a plain table"
	end
	if data.SchemaVersion ~= DATA.SCHEMA_VERSION then
		return false, "Unsupported SchemaVersion"
	end
	if not DataSchema.IsInteger(data.Gold) or not DataSchema.IsInteger(data.Rebirths) then
		return false, "Gold and Rebirths must be nonnegative safe integers"
	end
	if type(data.PurchasedBuildings) ~= "table" or getmetatable(data.PurchasedBuildings) ~= nil then
		return false, "PurchasedBuildings must be a plain dictionary"
	end
	for key in data do
		if key ~= "SchemaVersion" and key ~= "Gold" and key ~= "Rebirths" and key ~= "PurchasedBuildings" then
			return false, "Unexpected profile field; add a schema migration"
		end
	end
	for id, purchased in data.PurchasedBuildings do
		if type(id) ~= "string" or #id == 0 or #id > DATA.MAX_BUILDING_ID_LENGTH or type(purchased) ~= "boolean" then
			return false, "Invalid purchased building entry"
		end
	end
	return true, nil
end

function DataSchema.Copy(data: Types.PlayerData): Types.PlayerData
	return {
		SchemaVersion = data.SchemaVersion,
		Gold = data.Gold,
		Rebirths = data.Rebirths,
		PurchasedBuildings = table.clone(data.PurchasedBuildings),
	}
end

-- Validate the envelope before ProfileStore gets a chance to repair it. Gameplay
-- code never reads this format; only DataService's persistent-load preflight does.
function DataSchema.ValidateEnvelope(value: unknown): (boolean, string?)
	if type(value) ~= "table" then
		return false, "Invalid stored envelope"
	end
	local envelope = value :: { [string]: any }
	local metadata = envelope.MetaData
	local updates = envelope.GlobalUpdates
	if type(envelope.Data) ~= "table" or type(metadata) ~= "table" or type(updates) ~= "table" then
		return false, "Invalid stored envelope"
	end
	if not DataSchema.IsInteger(metadata.ProfileCreateTime) or not DataSchema.IsInteger(metadata.SessionLoadCount) then
		return false, "Invalid stored session metadata"
	end
	for _, field in { "ActiveSession", "ForceLoadSession" } do
		local session = metadata[field]
		if
			session ~= nil
			and (type(session) ~= "table" or type(session[1]) ~= "number" or type(session[2]) ~= "string")
		then
			return false, "Invalid stored session ownership"
		end
	end
	if not DataSchema.IsInteger(updates[1]) or type(updates[2]) ~= "table" then
		return false, "Invalid stored update metadata"
	end
	return true, nil
end

function DataSchema.Equal(left: Types.PlayerData, right: Types.PlayerData): boolean
	if left.SchemaVersion ~= right.SchemaVersion or left.Gold ~= right.Gold or left.Rebirths ~= right.Rebirths then
		return false
	end
	for id, purchased in left.PurchasedBuildings do
		if right.PurchasedBuildings[id] ~= purchased then
			return false
		end
	end
	for id, purchased in right.PurchasedBuildings do
		if left.PurchasedBuildings[id] ~= purchased then
			return false
		end
	end
	return true
end

return DataSchema
