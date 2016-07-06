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

function linear(coeff::Vector{Float64})
  if coeff[2] == 0.0
    res = Complex{Float64}[Inf]
  else
    res = Complex{Float64}[-coeff[1] / coeff[2]]
  end
  return res
end

function quadratic(coeff::Vector{Float64})
  if coeff[3] == 0.0
    res = linear(coeff[1:2])
  else
    res = Array(Complex{Float64}, 2)
    if coeff[1] == 0.0
      res[1] = 0.0
      res[2] = linear(coeff[2:3])
    else
      if coeff[2] == 0.0
        r = -coeff[1] / coeff[3]
        if r < 0.0
          res[1] = sqrt(-r)*im
          res[2] = -imag(res[1])*im
        else
          res[1] = sqrt(r)
          res[2] = -real(res[1])
        end
      else
        Δ = 1.0 - 4coeff[1]*coeff[3] / (coeff[2]*coeff[2])
        if Δ < 0.0
          res[1] = -0.5coeff[2]/coeff[3]+0.5coeff[2]*sqrt(-Δ)/coeff[3]*im
          res[2] = real(res[1]) - imag(res[1])*im
        else
          q = -0.5*(1.0+sign(coeff[2])*sqrt(Δ))*coeff[2]
          res[1] = q / coeff[3]
          res[2] = coeff[1] / q
        end
      end
    end
  end
  return res
end

function cubic(coeff::Vector{Float64})
  if coeff[4] == 0.0
    res = linear(coeff[1:3])
  else
    res = Array(Complex{Float64}, 3)
    if coeff[1] == 0.0
      res[1] = 0.0
      res[2] = linear(coeff[2:4])
    else

    end
  end
  return res
end

function roots(coeff::Vector{Float64})
  n = length(coeff)
  if n == 1
    res = Complex{Float64}[]
  elseif n == 2
    res = linear(coeff)
  elseif n == 3
    res = quadratic(coeff)
  #elseif n == 4
  #  res = cubic(coeff)
  #elseif n == 5
  #  res = quartic(coeff)
  else
    if coeff[n] == 0.0
      res = roots(coeff[1:n-1])
    else
      res = Array(Complex{Float64}, n-1)
      if coeff[1] == 0.0
        res[1] = 0.0
        res[2:n-1] = roots(coeff[2:n])
      else
        mat = zeros(Float64, n-1, n-1)
        mat[2:n-1, 1:n-2] = eye(Float64, n-2)
        mat[:, n-1] = - coeff[1:n-1] / coeff[n]
        res[1:n-1] = eigvals(mat)
        #res[1:n-1] = roots(Poly(coeff))
      end
    end
  end
  return res
end

function feval(coeff::Vector{Float64}, z::Complex{Float64})
  n = length(coeff)
  rz = real(z)
  iz = imag(z)
  p = -2rz
  q = rz*rz + iz*iz
  s = 0.0
  r = coeff[n]
  for val in reverse(coeff[2:n-1])
    t = val - p*r - q*s
    s = r
    r = t
  end
  return coeff[1] + rz*r - q*s + r*iz*im
end

function feval(coeff::Vector{Float64}, x::Float64)
  n = length(coeff)
  res = coeff[n]
  for val in reverse(coeff, 1, n-1)[1:n-1]
    res = x * res + val
  end
  return res
end
