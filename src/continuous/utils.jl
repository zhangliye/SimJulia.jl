function advance_time(coeff::Vector{Float64}, Δt::Float64)
  n = length(coeff)
  y = zeros(Float64, n+1, n)
  y[1, :] = coeff
  y[:, n] = coeff[n]
  for j in 2:n+1
    for i in n-1:-1:j-1
      y[j, i] = y[j-1, i] + Δt * y[j, i+1]
    end
  end
  diag(y[2:n+1,:])
end

function update_time(coeff::Vector{Float64}, Δt::Float64)
  n = length(coeff)
  res = coeff[n]
  for i = n-1:-1:1
    res = Δt * res + coeff[i]
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
        mat[2:n-1, 1:n-2] = eye(Float64, n-2)
        mat[:, n-1] = - x[1:n-1] / x[n]
        res[1:n-1] = eigvals(mat)
      end
    else
      res = roots(x[1:n-1])
    end
  end
  return res
end
