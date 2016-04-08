type ExplicitQuantizer <: AbstractQuantizer
  q :: Matrix{Float64}
  function ExplicitQuantizer(n::Int, order::Int)
    quantizer = new()
    quantizer.q = Array(Float64, n, order)
    return quantizer
  end
end
