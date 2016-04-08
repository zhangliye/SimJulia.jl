using Polynomials

type Variable <: AbstractVariable
  id :: Int
  bev :: BaseEvent
  f :: AbstractString
  Δabs :: Float64
  Δrel :: Float64
  x :: Poly
  tx :: Float64
  function Variable(f::AbstractString, x0::Float64, Δabs::Float64=1e-6, Δrel::Float64=1e-6)
    var = new()
    var.f = f
    var.x = Poly([x0])
    var.Δabs = Δabs
    var.Δrel = Δrel
    return var
  end
end

type Continuous{I<:AbstractIntegrator} <: AbstractEvent
  env :: AbstractEnvironment
  bev :: BaseEvent
  names :: Dict{UTF8String, Int}
  vars :: Vector{AbstractVariable}
  integrator :: I
  function Continuous(env::AbstractEnvironment, names::AbstractString...; args...)
    cont = new()
    cont.env = env
    cont.names = Dict{UTF8String, Int}()
    for i = 1:length(names)
      cont.names[names[i]] = i
    end
    cont.vars = Array(AbstractVariable, length(names))
    cont.integrator = I(cont; args...)
    cont.bev = BaseEvent(env)
    push!(cont.bev.callbacks, (ev)->initialize(ev::AbstractEvent, cont::Continuous))
    schedule(cont, true)
    return cont
  end
end

function Continuous{I<:AbstractIntegrator} (::Type{I}, env::AbstractEnvironment, names::AbstractString...; args...)
  cont = Continuous{I}(env, names...; args...)
  return cont
end

function initialize(ev::AbstractEvent, cont::Continuous)
  println("Initialize")
end

function step(ev::AbstractEvent, cont::Continuous, var::Variable)
  t = integrate()
end

function setindex!(cont::Continuous, var::Variable, name::AbstractString)
  i = cont.names[name]
  cont.vars[i] = var
  var.id = i

end
