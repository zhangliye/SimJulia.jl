using Calculus

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

function initialize(integrator::QSSIntegrator)
  add_derivatives(integrator)
end

function add_derivatives(integrator::QSSIntegrator)
  n = length(integrator.cont.names)
  names = Array(UTF8String, n)
  for name in keys(integrator.cont.names)
    names[integrator.cont.names[name]] = name
  end
  args = UTF8String["t", names...]
  for (index, var) in enumerate(integrator.cont.vars)
    integrator.derivatives[index, 1] = eval(parse("($(reduce((a,b)->"$a,$b",args)))->$(var.f)"))
  end
  if integrator.quantizer.order > 1
    fun = Array(UTF8String, n)
    for (index, var) in enumerate(integrator.cont.vars)
      fun[index] = var.f
    end
    for order = 2:integrator.quantizer.order
      prev_args = copy(args)
      for i = 1:n
        push!(args, "d$(order-1)_$(names[i])")
      end
      for index in 1:n
        ∇fun = differentiate(fun[index], prev_args)
        dfun = UTF8String["$(∇fun[1])"]
        for j = 2:(order-1)*n+1
          push!(dfun, "($(∇fun[j])) * $(args[j+n])")
        end
        fun[index] = reduce((a,b)->"$a + $b", dfun)
        integrator.derivatives[index, order] = eval(parse("($(reduce((a,b)->"$a,$b",args)))->$(fun[index])"))
      end
    end
  end
end

function integrate()

end
