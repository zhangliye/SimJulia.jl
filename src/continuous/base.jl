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
  res = Array(Complex{Float64}, n-1)
  if n == 1
    res = Complex{Float64}[]
  else
    if x[n] != 0.0
      if x[1] == 0.0
        res[1] = 0.0
        res[2:n] = roots(x[2:n])
      else
        mat = zeros(Float64, n-1, n-1)
        mat[1:n-2, 2:n-1] = eye(Float64, n-2)
        mat[n-1, :] = - x[1:n-1] / x[n]
        res[1:n-1] = eigvals(mat)
      end
    else
      res = roots(x[1:n-1])
    end
  end
  return res
end

function compute_next_time(x::Vector{Float64}, Δq::Float64, order::Int)
  res = Inf
  if order > 0
    if x[end] == 0.0
      res = compute_next_time(x[1:order], Δq, order-1)
    else
      res = (factorial(order)*Δq/abs(x[end]))^(1/order)
    end
  end
  return res
end

function real_positive(v::Complex{Float64})
  res = false
  if isreal(v)
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

function recompute_next_time(Δx::Vector{Float64}, Δq::Float64)
  n = copy(Δx)
  n[1] -= Δq
  p = copy(Δx)
  p[1] += Δq
  sols = filter((x)->real_positive(x), [roots(n); roots(p)])
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
