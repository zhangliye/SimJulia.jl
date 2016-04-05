type QSSIntegrator <: AbstractIntegrator
  quantizer :: AbstractQuantizer
  derivatives :: Matrix{Function}
end
