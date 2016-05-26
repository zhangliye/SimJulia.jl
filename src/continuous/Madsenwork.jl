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
  new_coeff[n-3] = coeff[n-1] - r*new_coeff[n-2]
  for i in n-2:-1:3
    new_coeff[i-2] = coeff[i] - r*new_coeff[i-1] - u*new_coeff[i]
  end
  return new_coeff
end

println(deflation([1.0, 0.0, 1.0, 0.0, 1.0], 1.0-im))
