using Polynomials

type Variable <: AbstractEvent
  id :: Int
  name :: UTF8String
  bev :: BaseEvent
  f :: UTF8String
  Δabs :: Float64
  Δrel :: Float64
  x :: Poly
  previous :: Float64
  function Variable(f::AbstractString, x0::Float64, Δabs::Float64=1e-6, Δrel::Float64=1e-6)
    var = new()
    var.f = f
    var.x = Poly([x0])
    var.Δabs = Δabs
    var.Δrel = Δrel
    return var
  end
end

type Continuous{I<:AbstractIntegrator}
  names :: Dict{UTF8String, Int}
  vars :: Vector{Variable}
  integrator :: I
  function Continuous(names::AbstractString...; args...)
    cont = new()
    cont.names = Dict{UTF8String, Int}()
    for i = 1:length(names)
      cont.names[names[i]] = i
    end
    cont.vars = Array(Variable, length(names))
    cont.integrator = I(cont; args...)
    return cont
  end
end

function Continuous{I<:AbstractIntegrator} (::Type{I}, env::AbstractEnvironment, names::AbstractString...; args...)
  cont = Continuous{I}(names...; args...)
  ev = Event(env)
  append_callback(ev, initialize, env, cont)
  schedule(ev, true)
  return cont
end

function initialize(ev::AbstractEvent, env::AbstractEnvironment, cont::Continuous)
  println("initialize")
  initialize(cont.integrator)
  for (index, var) in enumerate(cont.vars)
    var.bev = BaseEvent(env)
    append_callback(var, step, cont)
    schedule(var)
  end
end

function step(var::Variable, cont::Continuous)
  println("step $(var.id)")
  var.bev = BaseEvent(var.bev.env)
  append_callback(var, step, cont)
  integrate()
end

function setindex!(cont::Continuous, var::Variable, name::AbstractString)
  i = cont.names[name]
  cont.vars[i] = var
  var.id = i
  var.name = name
end
