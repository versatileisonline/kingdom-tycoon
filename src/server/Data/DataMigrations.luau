--!strict

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Types = require(Shared:WaitForChild("Types"))
local DataSchema = require(script.Parent.DataSchema)

type Migration = (data: { [string]: any }) -> ()

-- A step indexed by N transforms version N into N + 1. No historical saves exist yet.
-- Add each step here when bumping Config.DATA.SCHEMA_VERSION. Never skip a version.
local STEPS: { [number]: Migration } = {}
local DataMigrations = {}

local function copyRaw(value: any, ancestors: { [any]: boolean }, depth: number): any
	if type(value) ~= "table" then
		assert(type(value) == "string" or type(value) == "number" or type(value) == "boolean", "Non-data value")
		return value
	end
	assert(depth <= Config.DATA.MAX_SCHEMA_DEPTH and not ancestors[value], "Cyclic or excessively nested data")
	assert(getmetatable(value) == nil, "Data must not have metatables")
	ancestors[value] = true
	local copy = {}
	for key, child in value do
		assert(type(key) == "string" or type(key) == "number", "Invalid data key")
		copy[key] = copyRaw(child, ancestors, depth + 1)
	end
	ancestors[value] = nil
	return copy
end

function DataMigrations.Prepare(raw: unknown): (Types.PlayerData?, string?)
	if type(raw) ~= "table" then
		return nil, "Profile data is not a table"
	end
	local source = raw :: { [string]: any }
	local version = source.SchemaVersion
	if not DataSchema.IsInteger(version) or version < 1 then
		return nil, "Missing or invalid SchemaVersion"
	end
	if version > Config.DATA.SCHEMA_VERSION then
		return nil, "Profile was saved by a newer schema; refusing to downgrade"
	end
	local ok, result = pcall(function(): Types.PlayerData
		local draft = copyRaw(source, {}, 1)
		while version < Config.DATA.SCHEMA_VERSION do
			local step = STEPS[version]
			assert(step ~= nil, "Missing migration from version " .. tostring(version))
			step(draft)
			version += 1
			draft.SchemaVersion = version
		end
		local valid, reason = DataSchema.Validate(draft)
		assert(valid, reason)
		return draft :: Types.PlayerData
	end)
	if not ok then
		return nil, tostring(result)
	end
	return result, nil
end

return DataMigrations
