abstract AbstractIntegrator
abstract AbstractQuantizer

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

function compute_next_time(x::Vector{Float64}, Δq::Float64, order::Int)
  (Δq/abs(x[end]))^(1/order)
end

function real_positive(v::Complex{Float64})
  res = false
  if abs(imag(v)) < 1.0e-15
    if real(v)>=0.0
      res = true
    end
  end
  return res
end

function minimum_or_inf(v::Vector{Complex{Float64}})
  res = Inf
  if !isempty(v)
    res = minimum(real(v))
  end
  return res
end

function recompute_next_time(x::Vector{Float64}, q::Vector{Float64}, Δq::Float64)
  if abs(x[1]-q[1]) >= Δq
    return 0.0
  end
  Δx = copy(x)
  Δx[1:length(q)] -= q
  neg = copy(Δx)
  neg[1] -= Δq
  pos = copy(Δx)
  pos[1] += Δq
  sols = filter((x)->real_positive(x), [roots(neg); roots(pos)])
  minimum_or_inf(sols)
end

function evaluate_derivatives(derivs::Vector{Function}, t::Float64, q::Matrix{Float64}, p::Vector{Float64})
  order = length(derivs)
  res = Array(Float64, order)
  h = copy(q)
  for i in 1:order
    h[:,i] *= factorial(i-1)
    res[i] = derivs[i](t, h[:,1:i]..., p...) / factorial(i)
  end
  return res
end
