function lower_bound(coeff::Vector{Float64})
  n = length(coeff)
  r = log(abs(coeff[1]))
  m = exp((r-log(abs(coeff[n])))/(n-1))
  for i in n-1:-1:2
    m = min(m, exp((r-log(abs(coeff[i])))/(i-1)))
  end
  return m
end

function alter_direction(dz::Complex{Float64}, m::Float64)
  dzr = real(dz)
  dzi = imag(dz)
  return (0.6dzr-0.8dzi)+(0.8dzr+0.6dzi)*im
end

function deflation(coeff::Vector{Float64}, x::Float64)
  n = length(coeff)
  new_coeff = Array(Float64, n-1)
  new_coeff[n-1] = coeff[n]
  for i in n-1:-1:2
    new_coeff[i-1] = coeff[i] + new_coeff[i] * x
  end
  return new_coeff
end

function deflation(coeff::Vector{Float64}, z::Complex{Float64})
  n = length(coeff)
  new_coeff = Array(Float64, n-2)
  zr = real(z)
  zi = imag(z)
  r = -2zr
  u = zr*zr + zi*zi
  new_coeff[n-2] = coeff[n]
  new_coeff[n-3] = coeff[n-1] - r * new_coeff[n-2]
  for i in n-2:-1:3
    new_coeff[i-2] = coeff[i] - r * new_coeff[i-1] - u * new_coeff[i]
  end
  return new_coeff
end

function madsen(coeff::Vector{Float64})
  n = length(coeff)
  if n < 4
    res = roots(coeff)
  else
    if coeff[end] == 0.0
      res = madsen(coeff[1:end-1])
    elseif coeff[1] == 0.0
      res = [0.0; madsen(coeff)]
    else
      res = Array(Complex{Float64}, n-1)
      while n > 3
        dcoeff = Array(Float64, n-1)
        for i in 2:n
          dcoeff[i-1] = i * coeff[i]
        end
        u = lower_bound(coeff)
        z₀ = 0.0+0.0im
        f₀ = ff = 2.0coeff[1]*coeff[1]
        if coeff[2] == 0.0
          z = 0.5u
        else
          z = -0.5u * sign(coeff[1]/coeff[2]) + 0.0im
        end 
      end
      res = [res; quadratic(coeff)]
    end
  end
  return res
end
