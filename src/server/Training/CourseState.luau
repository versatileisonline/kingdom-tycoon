--!strict
export type Run = { Active: boolean, Checkpoint: number, Started: number, Best: number?, Result: number? }
local State = {}
function State.New(): Run
	return { Active = false, Checkpoint = 0, Started = 0, Best = nil, Result = nil }
end
function State.Start(s: Run, now: number): boolean
	if s.Active then
		return false
	end
	s.Active, s.Checkpoint, s.Started, s.Result = true, 0, now, nil
	return true
end
function State.Checkpoint(s: Run, index: number): boolean
	if not s.Active or index ~= s.Checkpoint + 1 then
		return false
	end
	s.Checkpoint = index
	return true
end
function State.Elapsed(s: Run, now: number): number
	return if s.Active then math.max(0, now - s.Started) else s.Result or 0
end
function State.Finish(s: Run, now: number, count: number): number?
	if not s.Active or s.Checkpoint ~= count then
		return nil
	end
	local elapsed = State.Elapsed(s, now)
	s.Active, s.Result = false, elapsed
	s.Best = math.min(s.Best or math.huge, elapsed)
	return elapsed
end
function State.Cancel(s: Run): ()
	s.Active, s.Checkpoint, s.Result = false, 0, nil
end
return State
