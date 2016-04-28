type Variable <: AbstractEvent
  id :: Int
  name :: UTF8String
  bev :: BaseEvent
  f :: UTF8String
  Δabs :: Float64
  Δrel :: Float64
  x :: Vector{Float64}
  t :: Float64
  function Variable(f::AbstractString, x₀::Float64, Δabs::Float64=1e-6, Δrel::Float64=1e-6)
    var = new()
    var.f = f
    var.x = [x₀]
    var.Δabs = Δabs
    var.Δrel = Δrel
    return var
  end
end

type Continuous
  names :: Dict{UTF8String, Int}
  vars :: Vector{Variable}
  function Continuous(names::AbstractString...; args...)
    cont = new()
    cont.names = Dict{UTF8String, Int}()
    for i = 1:length(names)
      cont.names[names[i]] = i
    end
    cont.vars = Array(Variable, length(names))
    return cont
  end
end

function Continuous{I<:AbstractIntegrator} (::Type{I}, env::AbstractEnvironment, names::AbstractString...; args...)
  cont = Continuous(names...; args...)
  integrator = I(cont; args...)
  ev = Event(env)
  append_callback(ev, initialize, env, integrator)
  schedule(ev, true)
  return cont
end

function setindex!(cont::Continuous, var::Variable, name::AbstractString)
  i = cont.names[name]
  cont.vars[i] = var
  var.id = i
  var.name = name
end
