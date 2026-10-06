--!strict

local Config = require(script.Parent.Config)

export type ScopedLogger = {
	Info: (message: string) -> (),
	Warn: (message: string) -> (),
}

local Logger = {}

function Logger.new(scope: string): ScopedLogger
	local prefix = string.format("[%s][%s]", Config.LOG_PREFIX, scope)

	return table.freeze({
		Info = function(message: string): ()
			print(string.format("%s %s", prefix, message))
		end,
		Warn = function(message: string): ()
			warn(string.format("%s %s", prefix, message))
		end,
	})
end

return table.freeze(Logger)
