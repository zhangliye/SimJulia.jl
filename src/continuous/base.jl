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

function advance_time(coeff::Vector{Float64}, Δt::Float64)
  n = length(coeff)
  res = Array(Float64, n)
  for i = 1:n
    res[i] = coeff[i]
    for j = i+1:n
      res[i] += coeff[j]*Δt^(j-i)/factorial(j-i)
    end
  end
  return res
end

function update_time(coeff::Vector{Float64}, Δt::Float64)
  n = length(coeff)
  res = coeff[1]
  for j = 2:n
    res += coeff[j]*Δt^(j-1)/factorial(j-1)
  end
  return res
end

function roots(x::Vector{Float64})
  n = length(x)
  res = Array(Float64, n-1)
  if n == 2
    if x[2] != 0.0
      res = [-x[1]/x[2]]
    else
      res = [inf]
    end
  elseif x[1] == 0.0
    res = [0.0; roots(x[2:end])]
  else
    mat = zeros(Float64, n-1, n-1)
    mat[2:n-1,1:n-2] = eye(n-2)
    for (index, v) in enumerate(x[2:end])
      mat[1,index]=-v/factorial(index)/x[1]
    end
    res = eigvals(mat)
  end
  return res
end

function compute_next_time(Δx::Float64, Δq::Float64, order::Int)
  (factorial(order)*Δq/abs(Δx))^(1/order)
end

function real_positive(v)
  res = false
  if isreal(v)
    if real(v)>=0.0
      res = true
    end
  end
  return res
end

function minimum_or_inf(v::Vector)
  res = inf
  if !isempty(v)
    res = minimum(real(v))
  end
  return res
end

function recompute_next_time(Δx::Vector{Float64}, Δq::Float64)
  n = copy(Δx)
  n[1] -= Δq
  p = copy(Δx)
  p[1] += Δq
  sols = filter((x)->real_positive(x), [roots(n); roots(p)])
  println(sols)
  return minimum_or_inf(sols)
end

function evaluate_derivatives(derivs::Vector{Function}, t::Float64, q::Matrix{Float64}, p::Vector{Float64})
  order = length(derivs)
  res = Array(Float64, order)
  for i in 1:order
    res[i] = derivs[i](t, q[:,1:i]..., p...)
  end
  return res
end
