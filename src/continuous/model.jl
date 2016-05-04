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
  function Variable(env::Environment, f::AbstractString, x₀::Float64, Δabs::Float64, Δrel::Float64)
    var = new()
    var.bev = BaseEvent(env)
    var.ex = parse(f)
    var.x = [x₀]
    var.Δabs = Δabs
    var.Δrel = Δrel
    return var
  end
end

function Variable(env::Environment, f::AbstractString, x₀::Float64, Δq::Float64)
  Variable(env, f, x₀, Δq, Δq)
end

function Variable(env::Environment, f::AbstractString, x₀::Float64)
  Variable(env, f, x₀, 1e-6)
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

function show(io::IO, var::Variable)
  print(io, var.symbol)
end

function setindex!(cont::Continuous, var::Variable, name::AbstractString)
  symbol = Symbol(name)
  i = cont.symbols[symbol]
  cont.vars[i] = var
  var.index = i
  var.symbol = symbol
end

function calculate_derivatives(cont::Continuous, order::Int)
  n = length(cont.vars)
  m = length(cont.params)
  vars = Array(Symbol, n)
  for (index, var) in enumerate(cont.vars)
    vars[index] = var.symbol
  end
  params = Array(Symbol, m)
  for (index, param) in enumerate(cont.params)
    params[index] = param.symbol
  end
  args = Symbol[:t, vars...]
  derivatives = Array(Function, order, n)
  for (index, var) in enumerate(cont.vars)
    derivatives[1, index] = eval(:(($(args...), $(params...))->$(var.ex)))
  end
  if order > 1
    fun = Array(Expr, n)
    for (index, var) in enumerate(cont.vars)
      fun[index] = var.ex
    end
    for o = 2:order
      prev_args = copy(args)
      for i = 1:n
        push!(args, symbol("d$(o-1)_", vars[i]))
      end
      for index in 1:n
        ∇ = differentiate(fun[index], prev_args)
        for j = 2:(o-1)*n+1
          ∇[j] = :($(∇[j])*$(args[j+n]))
        end
        fun[index] = reduce((a,b)->:($a + $b), ∇)
        derivatives[o, index] = eval(:(($(args...), $(params...))->$(fun[index])))
      end
    end
  end
  return derivatives
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
