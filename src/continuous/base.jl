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
  fac = Array(Float64, n-1)
  for i = 1:n-1
    fac[i] = Δt^i/factorial(i)
  end
  for i = 1:n
    res[i] = coeff[i]
    for j = i+1:n
      res[i] += coeff[j]*fac[j-i]
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

# function roots(x::Vector{Float64})
#   n = length(x)
#   res = Array(Complex{Float64}, n-1)
#   if n == 1
#     res = Complex{Float64}[]
#   else
#     if x[n] != 0.0
#       if x[1] == 0.0
#         res[1] = 0.0
#         res[2:n] = roots(x[2:n])
#       else
#         mat = zeros(Float64, n-1, n-1)
#         mat[2:n-1, 1:n-2] = eye(Float64, n-2)
#         mat[:, n-1] = - x[1:n-1] / x[n]
#         res[1:n-1] = eigvals(mat)
#       end
#     else
#       res = roots(x[1:n-1])
#     end
#   end
#   return res
# end

function compute_next_time(x::Vector{Float64}, Δq::Float64, order::Int)
  return (factorial(order)*Δq/abs(x[end]))^(1/order)
end

function real_positive(v::Complex{Float64})
  res = false
  if abs(imag(v)) < 1.0e-16#*abs(real(v))
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

function min_pos_root(x::Vector{Float64})
  res = [Inf]
  if x[end]==0.0
    if length(x) > 1
      res = min_pos_root(x[1:end-1])
    end
  else
    res = roots(x)
  end
  return res
end

function recompute_next_time(x::Vector{Float64}, q::Vector{Float64}, Δq::Float64)
  if abs(x[1]-q[1]) >= 0.99999999Δq
    return 0.0
  end
  Δx = copy(x)
  for (index, q) in enumerate(q)
    Δx[index] -= q
    Δx[index] /= factorial(index-1)
  end
  Δx[end] /= factorial(length(Δx)-1)
  neg = copy(Δx)
  neg[1] -= Δq
  pos = copy(Δx)
  pos[1] += Δq
  sols = filter((x)->real_positive(x), [min_pos_root(neg); min_pos_root(pos)])
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
