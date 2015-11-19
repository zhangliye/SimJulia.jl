function starter(env::AbstractEnvironment, delay::Float64, func::Function, args...)
  yield(Timeout(env, delay))
  return Process(env, func, args...)
end

"Constructs a delayed :class:`Process`. A :class:`Timeout` event is scheduled with the specified ``delay``. The process function is started from a callback of the timeout event."
function DelayedProcess(env::AbstractEnvironment, delay::Float64, func::Function, args...)
  return Process(env, starter, delay, func, args...)
end
