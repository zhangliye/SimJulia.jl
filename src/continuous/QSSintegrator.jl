type QSSIntegrator{Q<:AbstractQuantizer} <: AbstractIntegrator
  cont :: Continuous
  quantizer :: Q
  derivatives :: Matrix{Function}
  function QSSIntegrator(cont::Continuous; order=3)
    n = length(cont.vars)
    integrator = new()
    integrator.cont = cont
    integrator.quantizer = Q(n, order)
    integrator.derivatives = Array(Function, n, order)
    return integrator
  end
end
