using Calculus
using Polynomials

abstract AbstractQuantizer

type Variable
  name :: UTF8String
  x :: Vector{Float64}
  ev :: AbstractEvent
  tx :: Float64
  tq :: Float64
  derivatives :: Vector{Function}
  function Variable(name::AbstractString, t::Float64)
    var = new()
    var.name = name()
    var.tx = t
    var.tq = t
    return var
  end
end

type Quantizer <: AbstractQuantizer
  order :: Int
  function Quantizer(order::Int)
    new(order)
  end
end

type Continuous
  quant :: AbstractQuantizer
  vars :: Dict{UTF8String, Variable}
  q :: Matrix{Float64}
  function Continuous(quant::AbstractQuantizer, vars::AbstractString...)
    cont = new()
    cont.quant = quant
    for var in vars

    end
    cont.q = zeros(Float64, length(vars), quant.order)
    return cont
  end
end

type Start <: AbstractEvent
  bev :: BaseEvent
  function Step(env::AbstractEnvironment, cont::Continuous, delay::Float64=0.0)
    step = new()
    step.bev = BaseEvent(env)
    push!(step.bev.callbacks, (ev) -> initialize(env, ev, cont))
    schedule(step, delay)
    return step
  end
end

function initialize(env::AbstractEnvironment, ev::Start, cont::Continuous)

end

type Step <: AbstractEvent
  bev :: BaseEvent
  function Step(env::AbstractEnvironment, cont::Continuous, var::Variable, delay::Float64=0.0)
    step = new()
    step.bev = BaseEvent(env)
    push!(step.bev.callbacks, (ev) -> integrate(env, ev, cont, var))
    schedule(step, delay)
    return step
  end
end

function integrate(env::AbstractEnvironment, ev::Step, cont::Continuous, var::Variable)
  t = now(env)

end
