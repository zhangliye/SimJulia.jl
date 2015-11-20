"""
Start a process function. Only used internally by :class:`Process`.
This event is automatically triggered when it is created.
"""
type Initialize <: AbstractEvent
  bev :: BaseEvent
  function Initialize(env::AbstractEnvironment, callback)
    init = new()
    init.bev = BaseEvent(env)
    push!(init.bev.callbacks, callback)
    schedule(init, true)
    return init
  end
end

"""
A :class:`Process` is an abstraction for an event yielding function, a process function.

The process function can suspend its execution by yielding an :class:`AbstractEvent`. The :class:`Process` will take care of resuming the process function with the value of that event once it has happened. The exception of failed events is also thrown into the process function.

A :class:`Process` itself is an event, too. It is triggered, once the process functions returns or raises an exception. The value of the process is the return value of the process function or the exception, respectively.
"""
type Process <: AbstractEvent
  name :: AbstractString
  task :: Task
  target :: AbstractEvent
  bev :: BaseEvent
  resume :: Function
  function Process(env::AbstractEnvironment, name::AbstractString, func::Function, args...)
    proc = new()
    proc.name = name
    proc.task = Task(()->func(env, args...))
    proc.bev = BaseEvent(env)
    proc.resume = (ev)->execute(env, ev, proc)
    proc.target = Initialize(env, proc.resume)
    return proc
  end
end

"""
Constructs an interruption event. Only used internally by :class:`Interrupt`.
This event is automatically triggered with priority when it is created.
"""
type Interruption <: AbstractEvent
  bev :: BaseEvent
  function Interruption(proc::Process, cause::Any=nothing)
    inter = new()
    inter.bev = BaseEvent(proc.bev.env)
    push!(inter.bev.callbacks, proc.resume)
    schedule(inter, true, InterruptException(cause))
    delete!(proc.target.bev.callbacks, proc.resume)
    return inter
  end
end

"Immediately schedules an :class:`Interruption` event with as value an instance of :class:`InterruptException`. The process function of ``proc`` is added to its callbacks. An :class:`Interrupt` event is returned. This event is automatically triggered when it is created."
type Interrupt <: AbstractEvent
  bev :: BaseEvent
  function Interrupt(proc::Process, cause::Any=nothing)
    inter = new()
    env = proc.bev.env
    inter.bev = BaseEvent(env)
    active_proc = active_process(env)
    if !istaskdone(proc.task) && !is(proc, active_proc)
      Interruption(proc, cause)
    end
    schedule(inter)
    return inter
  end
end

type InterruptException <: Exception
  cause :: Any
  function InterruptException(cause::Any)
    inter = new()
    inter.cause = cause
    return inter
  end
end

"Constructs a :class:`Process`. The argument ``func`` is the process function and has the following signature :func:``func(env::AbstractEnvironment, args...) <func>``. If the ``name`` argument is missing, the name of the process is a combination of the name of the process function and the event id of the process. An :class:`Initialize` event is scheduled immediately to start the process function."
function Process(env::AbstractEnvironment, func::Function, args...)
  name = "$func"
  proc = Process(env, name, func, args...)
  proc.name = "SimJulia.Process $(proc.bev.id): $func"
  return proc
end

function show(io::IO, proc::Process)
  print(io, proc.name)
end

function show(io::IO, inter::InterruptException)
  print(io, "InterruptException: $(inter.cause)")
end

"Returns ``true`` if the process function returned or an exception was thrown."
function is_process_done(proc::Process)
  return istaskdone(proc.task)
end

function cause(inter::InterruptException)
  return inter.cause
end

function execute(env::AbstractEnvironment, ev::AbstractEvent, proc::Process)
  try
    env.active_proc = Nullable(proc)
    value = consume(proc.task, ev.bev.value)
    env.active_proc = Nullable{Process}()
    if istaskdone(proc.task)
      schedule(proc, value)
    end
  catch exc
    env.active_proc = Nullable{Process}()
    if !isempty(proc.bev.callbacks)
      schedule(proc, exc)
    else
      rethrow(exc)
    end
  end
end

"Passes the control flow back to the simulation. If the yielded event is triggered , the simulation will resume the function after this statement. The return value is the value from the yielded event."
function yield(ev::AbstractEvent)
  if ev.bev.state == EVENT_PROCESSED
    return ev.bev.value
  end
  proc = active_process(ev.bev.env)
  proc.target = ev
  push!(ev.bev.callbacks, proc.resume)
  value = produce(nothing)
  if isa(value, Exception)
    throw(value)
  end
  return value
end
