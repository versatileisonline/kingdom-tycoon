--!strict
local Tests = {}
function Tests.Run(State: any): ()
	local ready = { Sprinting = true, Alive = true, Grounded = true, Moving = true, Blocked = false }
	assert(State.ShouldPlay(ready), "Grounded sprint did not animate")
	for _, field in { "Sprinting", "Alive", "Grounded", "Moving" } do
		local c = table.clone(ready)
		c[field] = false
		assert(not State.ShouldPlay(c), "Animation continued without " .. field)
	end
	local menu = table.clone(ready)
	menu.Blocked = true
	assert(not State.ShouldPlay(menu), "Menu did not stop sprint animation")
	assert(State.ShouldPlay(ready), "Landing/resuming did not re-enable animation")
	print("All sprint animation state checks passed")
end
return Tests
