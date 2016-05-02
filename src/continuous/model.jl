type Parameter
  index :: Int
  symbol :: Symbol
  value :: Float64
  function Parameter(x₀::Float64)
    param = new()
    param.value = x₀
    return param
  end
end

type Variable <: AbstractEvent
  bev :: BaseEvent
  index :: Int
  symbol :: Symbol
  ex :: Expr
  Δabs :: Float64
  Δrel :: Float64
  x :: Vector{Float64}
  t :: Float64
  function Variable(f::AbstractString, x₀::Float64, Δabs::Float64, Δrel::Float64)
    var = new()
    var.ex = parse(f)
    var.x = [x₀]
    var.Δabs = Δabs
    var.Δrel = Δrel
    return var
  end
end

function Variable(f::AbstractString, x₀::Float64, Δq::Float64)
  Variable(f, x₀, Δq, Δq)
end

function Variable(f::AbstractString, x₀::Float64)
  Variable(f, x₀, 1e-6, 1e-6)
end

type Continuous
  symbols :: Dict{Symbol, Int}
  vars :: Vector{Variable}
  params :: Vector{Parameter}
  p :: Vector{Float64}
  deps :: Matrix{Bool}
  function Continuous(vars::Vector, params::Vector)
    n = length(vars)
    m = length(params)
    cont = new()
    cont.symbols = Dict{Symbol, Int}()
    for i in 1:n
      cont.symbols[Symbol(vars[i])] = i
    end
    for i in 1:m
      cont.symbols[Symbol(params[i])] = i + n
    end
    cont.vars = Array(Variable, n)
    cont.params = Array(Parameter, m)
    cont.p = zeros(Float64, m)
    cont.deps = zeros(Bool, n, n+m)
    return cont
  end
end

function Continuous{I<:AbstractIntegrator}(::Type{I}, env::AbstractEnvironment, vars::Vector, params::Vector=[]; args...)
  cont = Continuous(vars, params)
  integrator = I(cont; args...)
  ev = Event(env)
  append_callback(ev, initialize, env, integrator)
  schedule(ev, true)
  return cont
end

function setindex!(cont::Continuous, param::Parameter, name::AbstractString)
  n = length(cont.vars)
  symbol = Symbol(name)
  i = cont.symbols[symbol]
  cont.params[i-n] = param
  param.index = i
  param.symbol = symbol
  cont.p[i-n] = param.value
end

function setindex!(cont::Continuous, var::Variable, name::AbstractString)
  symbol = Symbol(name)
  i = cont.symbols[symbol]
  cont.vars[i] = var
  var.index = i
  var.symbol = symbol
end

function check_dependencies(cont::Continuous)
  n = length(cont.vars)
  symbols = Set{Symbol}(keys(cont.symbols))
  for (index, var) in enumerate(cont.vars)
    deps = Set{Symbol}()
    process_expr(var.ex, deps)
    for symbol in intersect(deps, symbols)
      cont.deps[index, cont.symbols[symbol]] = true
    end
  end
end

function process_expr(ex::Expr, deps::Set{Symbol})
  if ex.head == :call
    for ex_arg in ex.args[2:end]
      process_expr(ex_arg, deps)
    end
  end
end

function process_expr(symbol::Symbol, deps::Set{Symbol})
  push!(deps, symbol)
end

function process_expr(::Any, ::Set{Symbol})

end

function advance_time(var::Variable, Δt::Float64)
  for i = 1:length(var.x)
    for j = i+1:length(var.x)
      var.x[i] += var.x[j]*Δt^(j-i)/factorial(j-i)
    end
  end
end
