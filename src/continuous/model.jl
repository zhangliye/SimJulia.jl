type Variable <: AbstractEvent
  index :: Int
  name :: UTF8String
  bev :: BaseEvent
  f :: UTF8String
  Δabs :: Float64
  Δrel :: Float64
  x :: Vector{Float64}
  t :: Float64
  function Variable(f::AbstractString, x₀::Float64, Δabs::Float64, Δrel::Float64)
    var = new()
    var.f = f
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
  names :: Dict{UTF8String, Int}
  vars :: Vector{Variable}
  deps :: Matrix{Bool}
  function Continuous(names::AbstractString...; args...)
    n = length(names)
    cont = new()
    cont.names = Dict{UTF8String, Int}()
    for i = 1:n
      cont.names[names[i]] = i
    end
    cont.vars = Array(Variable, n)
    cont.deps = zeros(Bool, n, n)
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
  var.index = i
  var.name = name
end

function check_dependencies(cont::Continuous)
  syms = Dict{Symbol, UTF8String}()
  for name in keys(cont.names)
    syms[Symbol(name)] = name
  end
  for (index, var) in enumerate(cont.vars)
    deps = Set{UTF8String}()
    process_expr(parse(var.f), syms, deps)
    for name in deps
      cont.deps[index, cont.names[name]] = true
    end
  end
end

function process_expr(ex::Expr, syms::Dict{Symbol, UTF8String}, deps::Set{UTF8String})
  if ex.head == :call
    for ex_arg in ex.args[2:end]
      process_expr(ex_arg, syms, deps)
    end
  end
end

function process_expr(sym::Symbol, syms::Dict{Symbol, UTF8String}, deps::Set{UTF8String})
  if sym in keys(syms)
    push!(deps, syms[sym])
  end
end

function process_expr(sym::Any, syms::Dict{Symbol, UTF8String}, deps::Set{UTF8String})

end

function advance_time(var::Variable, Δt::Float64)
  for i = 1:length(var.x)
    for j = i+1:length(var.x)
      var.x[i] += var.x[j]*Δt^(j-i)/factorial(j-i)
    end
  end
end
