type ExplicitQuantizer <: AbstractQuantizer
  q :: Matrix{Float64}
  t :: Vector{Float64}
  order :: Int
  function ExplicitQuantizer(n::Int, order::Int)
    quantizer = new()
    quantizer.q = Array(Float64, n, order)
    quantizer.t = zeros(Float64, n)
    quantizer.order = order
    return quantizer
  end
end
