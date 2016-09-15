"""
  - `run(sim::Simulation, until::Event)`
  - `run(sim::Simulation, until::TimeType)`
  - `run(sim::Simulation, period::Period)`
  - `run(sim::Simulation, period::Number)`
  - `run(sim::Simulation)`

Executes [`step`](@ref) until the given criterion `until` is met:

- if it is not specified, the method will return when there are no further events to be processed
- if it is an `Event`, the method will continue stepping until this event has been triggered and will return its value
- if it is a `TimeType`, the method will continue stepping until the simulation’s time reaches until
- if it is a `Period`, the method will continue stepping until the simulation’s time has passed until periods
- if it is a `Number`, the method will continue stepping until the simulation’s time has passed until elementary periods

In the last two cases, the simulation can prematurely stop when there are no further events to be processed.
"""
function run(sim::Simulation, until::Event) :: Any
  append_callback(until, stop_simulation)
  try
    while true
      step(sim)
    end
  catch exc
    if isa(exc, StopSimulation)
      return exc.value
    else
      rethrow(exc)
    end
  end
end

function run(sim::Simulation, period::Period) :: Any
  run(sim, timeout(sim, period))
end

function run(sim::Simulation, period::Number) :: Any
  run(sim, timeout(sim, sim.granularity(period)))
end

function run{T}(sim::Simulation{T}, until::T) :: Any
  run(sim, timeout(sim, now(sim)-until))
end

function run(sim::Simulation) :: Any
  run(sim, timeout(sim, typemax(sim.granularity)))
end

function stop_simulation(sim::Simulation, ev::Event)
  throw(StopSimulation(ev.value))
end

"""
  `now(sim::Simulation) :: TimeType`

Returns the current simulation time.
"""
function now(sim::Simulation) :: TimeType
  return sim.time
end

function active_process(sim::Simulation) :: Process
  get(sim.active_proc)
end

"""
  - `schedule!(sim::Simulation, ev::Event, delay::Period; priority::Bool=false, value::Any=nothing) :: Event`
  - `schedule!(sim::Simulation, ev::Event, delay::Number=0; priority::Bool=false, value::Any=nothing) :: Event`

Schedules an event at time `sim.time + delay` with a `priority` and a `value`.

If the event is already scheduled, the key is updated with the new `delay` and `priority`. The new `value` is also set.

If the event is being processed, an [`EventProcessing`](@ref) exception is thrown.
"""
function schedule!(sim::Simulation, ev::Event, delay::Period; priority::Bool=false, value::Any=nothing) :: Event
  if (ev.state == processing) || (ev.state == processed)
    throw(EventProcessing)
  end
  ev.value = value
  if ev.state == processing
    id = sim.heap[ev].id
  else
    id = sim.sid+=0x1
  end
  sim.heap[ev] = EventKey(sim.time + delay, priority, id)
  ev.state = triggered
  return ev
end

function schedule!(sim::Simulation, ev::Event, delay::Number=0; priority::Bool=false, value::Any=nothing) :: Event
  schedule!(sim, ev, sim.granularity(delay), priority=priority, value=value)
end

"""
  - `schedule(sim::Simulation, ev::Event, delay::Period; priority::Bool=false, value::Any=nothing) :: Event`
  - `schedule(sim::Simulation, ev::Event, delay::Number=0; priority::Bool=false, value::Any=nothing) :: Event`

Schedules an event at time `sim.time + delay` with a `priority` and a `value`.

If the event is already scheduled or is being processed, an [`EventNotIdle`](@ref) exception is thrown.
"""
function schedule(sim::Simulation, ev::Event, delay::Period; priority::Bool=false, value::Any=nothing) :: Event
  if !(ev.state == idle)
    throw(EventNotIdle)
  end
  ev.value = value
  sim.heap[ev] = EventKey(sim.time + delay, priority, sim.sid+=0x1)
  ev.state = triggered
  return ev
end

function schedule(sim::Simulation, ev::Event, delay::Number=0; priority::Bool=false, value::Any=nothing) :: Event
  schedule(sim, ev, sim.granularity(delay), priority=priority, value=value)
end

"""
  `step(sim::Simulation) :: Bool`

Does a simulation step and processes the next event.

Only used internally.
"""
function step(sim::Simulation)
  if isempty(sim.heap)
    throw(EmptySchedule)
  end
  (ev, key) = peek(sim.heap)
  dequeue!(sim.heap)
  sim.time = key.time
  ev.state = processing
  while !isempty(ev.callbacks)
    cb = dequeue!(ev.callbacks)
    cb(sim, ev)
  end
  ev.state = processed
end
