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

function total_derivatives_with_respect_to_time(f::AbstractString, order::Int, deps...)
  n = length(deps)
  args = AbstractString["t", deps...]
  derivs = Function[eval(parse("(args...)->$f"))]
  if order > 1
    fun = f
    for i = 2:order
      ∇f = differentiate(fun, args)
      df = AbstractString["$(∇f[1])"]
      for j = 1:n
        push!(args, "d$i$(deps[j])")
      end
      for j = 2:length(∇f)
        push!(df, "($(∇f[j])) * $(args[j+n])")
      end
      fun = reduce((a,b)->"$a + $b", df)
      push!(derivs, eval(parse("(args...)->$fun")))
    end
  end
  return derivs
end
