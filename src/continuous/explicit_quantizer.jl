type ExplicitQuantizer <: AbstractQuantizer
  q :: Matrix{Float64}
  t :: Vector{Float64}
  order :: Int
  function ExplicitQuantizer(n::Int, order::Int)
    quantizer = new()
    quantizer.q = zeros(Float64, order, n)
    quantizer.t = zeros(Float64, n)
    quantizer.order = order
    return quantizer
  end
end

function update_quantized_state(quantizer::ExplicitQuantizer, index::Int, t::Float64, x::Vector{Float64})
  quantizer.t[index] = t
  quantizer.q[:, index] = x[1:quantizer.order]
end
