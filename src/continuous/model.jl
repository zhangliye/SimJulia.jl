using Polynomials

type Variable <: AbstractEvent
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

type Continuous
  env :: AbstractEnvironment
  n : Int
  vars :: Dict{UTF8String, Variable}
  params :: Dict{UTF8String, Float64}
  integrator :: AbstractIntegrator
  function Continuous(env::AbstractEnvironment, names::AbstractString...)
    cont = new()
      cont.env = env
      cont.n = length(names)
    return cont
  end
end

function initialize(ev::AbstractEvent, cont::Continuous)

end

function integrate(ev::AbstractEvent, cont::Continuous, var::Variable)

function setindex!(cont::Continuous, var::Variable, name::AbstractString)

end
