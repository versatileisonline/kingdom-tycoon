--!strict
-- Run with the actual ShopPreview source bound to a fake Studio environment.
-- The fake scheduler pauses at waits so startup order is deterministic.
local Tests = {}
function Tests.Run(createPreview: (any) -> any): ()
	local function fixture(entered: boolean)
		local attributes: { [string]: any } = { KingdomEntered = entered }
		local players: any = {}
		local player: any = { Parent = players }
		function player:GetAttribute(key: string): any
			return attributes[key]
		end
		function player:SetAttribute(key: string, value: any): ()
			attributes[key] = value
		end
		function players:GetPlayers(): { any }
			return { player }
		end
		local enabled, staged = true, 0
		local entitlements = {
			IsPreview = function(): boolean
				return enabled
			end,
			SetPreview = function(): () end,
		}
		local server: any = { Services = { EntitlementService = "entitlements" } }
		function server:SetAttribute(_key: string, _value: any): () end
		local preview = createPreview({
			script = { Parent = { Parent = server, TutorialPreview = "tutorial" } },
			game = {
				Players = players,
				ReplicatedStorage = { Shared = { ShopConfig = "config" } },
				GetService = function(_self: any, name: string): any
					assert(name == "Players", "unexpected service dependency")
					return players
				end,
			},
			task = {
				wait = function(): ()
					coroutine.yield()
				end,
			},
			require = function(key: string): any
				if key == "entitlements" then
					return entitlements
				elseif key == "config" then
					return { OFFERS = {} }
				end
				assert(key == "tutorial", "unexpected module dependency")
				return {
					Run = function(): ()
						assert(attributes.KingdomEntered == true, "preview must not claim before menu entry")
						staged += 1
					end,
				}
			end,
		})
		return {
			Thread = coroutine.create(preview.Run),
			Enter = function(): ()
				attributes.KingdomEntered = true
			end,
			Leave = function(): ()
				player.Parent = nil
			end,
			Disable = function(): ()
				enabled = false
			end,
			Staged = function(): number
				return staged
			end,
			Ready = function(): any
				return attributes.ShopPreviewReady
			end,
		}
	end
	local function resume(thread: thread): ()
		local ok, reason = coroutine.resume(thread)
		assert(ok, tostring(reason))
	end
	local pending = fixture(false)
	resume(pending.Thread)
	assert(coroutine.status(pending.Thread) == "suspended" and pending.Staged() == 0, "menu must retain free plot")
	-- Remaining on the menu must not time out or take the only free plot.
	for _ = 1, 1000 do
		resume(pending.Thread)
	end
	pending.Enter()
	resume(pending.Thread)
	assert(pending.Staged() == 1 and pending.Ready() == true, "entry should stage preview once")
	assert(coroutine.status(pending.Thread) == "dead", "preview should finish after entry")
	local entered = fixture(true)
	resume(entered.Thread)
	assert(entered.Staged() == 1 and entered.Ready() == true, "already entered player should proceed")
	for _, cancel in { "Leave", "Disable" } do
		local aborted = fixture(false)
		resume(aborted.Thread)
		aborted[cancel]()
		resume(aborted.Thread)
		assert(coroutine.status(aborted.Thread) == "dead", "cancelled preview should stop waiting")
		assert(aborted.Staged() == 0 and aborted.Ready() == nil, "cancelled preview must not stage or report ready")
	end
	print("All shop preview entry checks passed")
end
return Tests
