using Calculus
using Polynomials

import Calculus.integrate

abstract AbstractVariable

function integrate(ev::AbstractEvent, var::AbstractVariable)

end

type Step <: AbstractEvent
  bev :: BaseEvent
  function Step(env::AbstractEnvironment, delay::Float64, var::AbstractVariable)
    step = new()
    step.bev = BaseEvent(env)
    push!(step.bev.callbacks, (ev) -> integrate(ev, var))
    schedule(step, delay, var)
    return step
  end
end

function total_derivatives_with_respect_to_time(f::AbstractString, order::Int, deps...)
  n = length(deps)
  args = AbstractString["t", deps...]
  derivs = Function[eval(parse("($(reduce((a::AbstractString,b::AbstractString)->"$a,$b",args)))->$f"))]
  if order > 1
    fun = f
    for i = 2:order
      ∇f = differentiate(fun, args)
      df = AbstractString["$(∇f[1])"]
      for j = 1:n
        push!(args, "d$i$(deps[j])")
      end
      for j = 2:length(∇f)
        push!(df, "($(∇f[j])) * $(args[j+n])")
      end
      fun = reduce((a::AbstractString,b::AbstractString)->"$a + $b", df)
      push!(derivs, eval(parse("($(reduce((a::AbstractString,b::AbstractString)->"$a,$b",args)))->$fun")))
    end
  end
  return derivs
end

type Continuous
  env :: AbstractEnvironment
  order :: Int
  vars :: Dict{AbstractString, AbstractVariable}
  rev_deps :: Dict{AbstractString, Set{AbstractVariable}}
  function Continuous(env::AbstractEnvironment, order::Int)
    cont = new()
    cont.env = env
    cont.order = order
    cont.vars = Dict{AbstractString, AbstractVariable}()
    cont.rev_deps = Dict{AbstractString, Set{AbstractVariable}}()
    return cont
  end
end

type Variable <: AbstractVariable
  cont :: Continuous
  name :: AbstractString
  x :: Vector{Float64}
  q :: Vector{Float64}
  derivs :: Vector{Function}
  deps :: Vector{AbstractString}
  ev :: Step
  function Variable(cont::Continuous, name::AbstractString, delay::Float64, x₀::Float64, f::AbstractString, deps...)
    var = new()
    var.cont = cont
    cont.vars[name] = var
    var.name = name
    var.x = zeros(Float64, cont.order+1)
    var.x[1] = x₀
    var.q = zeros(Float64, cont.order)
    var.derivs = total_derivatives_with_respect_to_time(f, cont.order, deps...)
    var.deps = AbstractString[deps...]
    for i in 1:length(deps)
      if !haskey(cont.rev_deps, deps[i])
        cont.rev_deps[deps[i]] = Set{AbstractVariable}()
      end
      push!(cont.rev_deps[deps[i]], var)
    end
    var.ev = Step(cont.env, delay, var)
    return var
  end
end
