--!strict
local Tests = {}
function Tests.Run(State: any): ()
	local input = {
		{ UserId = 3, Name = "Loading" },
		{ UserId = 2, Name = "Second", LifetimeGold = 20, Rebirths = 8 },
		{ UserId = 1, Name = "First", LifetimeGold = 20, Rebirths = 0 },
		{ UserId = 4, Name = "Last", LifetimeGold = 0, Rebirths = 0 },
	}
	local sorted = State.Sort(input)
	assert(sorted[1].UserId == 1 and sorted[2].UserId == 2, "Gold ties must use stable UserId order")
	assert(sorted[3].UserId == 4 and sorted[4].LifetimeGold == nil, "Loading players rank after ready players")
	assert(input[1].UserId == 3, "Sorting mutated source")
	assert(State.Format(1240500) == "1,240,500" and State.Format(0) == "0", "Exact Gold formatting")
	assert(State.Format(nil) == "...", "Loading must not appear as zero")
	assert(#State.Sort({}) == 0, "Empty server")
	local full = {}
	for id = 60, 1, -1 do
		table.insert(full, { UserId = id, Name = "Player" .. id, LifetimeGold = id * 100, Rebirths = id })
	end
	local ranked = State.Sort(full)
	assert(#ranked == 60 and ranked[1].UserId == 60 and ranked[60].UserId == 1, "Full-server ranking")
	full[60].LifetimeGold = 9007199254740991
	assert(State.Sort(full)[1].UserId == 1, "Live earnings must change rank")
	table.remove(full, 60)
	assert(#State.Sort(full) == 59, "Departure must remove an entry")
	assert(State.Format(9007199254740991) == "9,007,199,254,740,991", "Large totals must retain exact digits")
	print("[LeaderboardClientTests] All checks passed")
end

-- Explicit, isolated client-engine checks; no fake Players or saved data changes.
function Tests.RunView(View: any, State: any, parent: Instance, capacity: number): ()
	local view = View.new(parent, 1)
	view.Screen.Name = "KingdomLeaderboardViewTest"
	local ok, message = xpcall(function()
		view.SetOpen(true)
		local list = view.Panel.Players :: ScrollingFrame
		local entries = {}
		for id = 1, capacity do
			table.insert(entries, {
				UserId = id,
				Name = if id == 1 then "AnExtremelyLongPlayerDisplayName" else "Knight" .. id,
				LifetimeGold = (capacity - id) * 100,
				Rebirths = id,
			})
		end
		view.Render(State.Sort(entries), {})
		task.wait(0.2)
		local first = list:FindFirstChild("1") :: Frame
		local stroke = first:FindFirstChildOfClass("UIStroke") :: UIStroke
		local halfStroke = stroke.Thickness * view.Panel.UIScale.Scale / 2
		assert(first.AbsolutePosition.Y - list.AbsolutePosition.Y >= halfStroke, "First row outline clipped")
		assert(first.AbsolutePosition.X - list.AbsolutePosition.X >= halfStroke, "Left row outline clipped")
		assert(list.AbsoluteCanvasSize.Y > list.AbsoluteWindowSize.Y, "Full server must overflow vertically")
		assert(list.ScrollingDirection == Enum.ScrollingDirection.Y, "List must only scroll vertically")
		list.CanvasPosition = Vector2.new(0, list.AbsoluteCanvasSize.Y)
		task.wait(0.2)
		local last = list:FindFirstChild(tostring(capacity)) :: Frame
		assert(last.AbsolutePosition.Y >= list.AbsolutePosition.Y, "Last row cannot be fully reached")
		assert(
			last.AbsolutePosition.Y + last.AbsoluteSize.Y + halfStroke
				<= list.AbsolutePosition.Y + list.AbsoluteWindowSize.Y + 0.5,
			"Last row outline clipped"
		)
		local position = list.CanvasPosition
		local headerPosition = view.Panel.LifetimeGold.AbsolutePosition
		entries[1].LifetimeGold = 9007199254740991
		view.Render(State.Sort(entries), {})
		task.wait(0.2)
		assert(list:FindFirstChild("1") == first and first.LayoutOrder == 1, "Update replaced or misranked row")
		assert((list.CanvasPosition - position).Magnitude < 1, "Score update reset scroll position")
		assert(view.Panel.LifetimeGold.AbsolutePosition == headerPosition, "Column header scrolled with rows")
		table.remove(entries, capacity)
		view.Render(State.Sort(entries), {})
		assert(list:FindFirstChild(tostring(capacity)) == nil, "Departure retained a stale row")
		view.Render({ { UserId = 1, Name = "Loading" } }, {})
		task.wait(0.2)
		assert(first.Gold.Text == "..." and first.Rank.Text == "-", "Loading entry presented as ready")
		assert(list.CanvasPosition.Y < 1, "Shrinking to one player left the list scrolled out of view")
		view.Render({}, {})
		assert(list:FindFirstChild("1") == nil, "Empty server retained a row")
		view.SetOpen(false)
		assert(not view.Panel.Visible and view.Launcher.Visible, "Close did not restore launcher")
	end, debug.traceback)
	view.Screen:Destroy()
	assert(ok, message)
	print("[LeaderboardViewTests] All " .. capacity .. "-entry layout checks passed")
end
return Tests
