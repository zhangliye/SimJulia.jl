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
