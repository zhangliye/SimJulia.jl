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

function initialize(ev::AbstractEvent, env::AbstractEnvironment, integrator::QSSIntegrator)
  println("initialize")
  add_derivatives(integrator)
  check_dependencies(integrator.cont)
  for (index, var) in enumerate(integrator.cont.vars)
    var.t = now(env)
    integrator.quantizer.q[index, 1] = var.x[1]
    var.x = zeros(Float64, integrator.quantizer.order+1)
    var.x[1] = integrator.quantizer.q[index, 1]
    var.bev = BaseEvent(env)
    append_callback(var, step, env, integrator)
    schedule(var)
  end
end

function add_derivatives(integrator::QSSIntegrator)
  n = length(integrator.cont.vars)
  m = length(integrator.cont.params)
  vars = Array(Symbol, n)
  for (index, var) in enumerate(integrator.cont.vars)
    vars[index] = var.symbol
  end
  params = Array(Symbol, m)
  for (index, param) in enumerate(integrator.cont.params)
    params[index] = param.symbol
  end
  args = Symbol[:t, vars...]
  for (index, var) in enumerate(integrator.cont.vars)
    integrator.derivatives[index, 1] = eval(:(($(args...), $(params...))->$(var.ex)))
  end
  if integrator.quantizer.order > 1
    fun = Array(Expr, n)
    for (index, var) in enumerate(integrator.cont.vars)
      fun[index] = var.ex
    end
    for order = 2:integrator.quantizer.order
      prev_args = copy(args)
      for i = 1:n
        push!(args, symbol("d$(order-1)_", vars[i]))
      end
      for index in 1:n
        ∇ = differentiate(fun[index], prev_args)
        for j = 2:(order-1)*n+1
          ∇[j] = :($(∇[j])*$(args[j+n]))
        end
        fun[index] = reduce((a,b)->:($a + $b), ∇)
        integrator.derivatives[index, order] = eval(:(($(args...), $(params...))->$(fun[index])))
      end
    end
  end
end

function step(var::Variable, env::Environment, integrator::QSSIntegrator)
  println("step of variable $(var.symbol) at time $(now(env))")
  var.bev = BaseEvent(env)
  append_callback(var, step, env, integrator)
  Δt = now(env) - var.t
  advance_time(var, Δt)
  var.t = now(env)
  update_quantized_state(integrator.quantizer, var.index, var.t, var.x)
  Δq = max(var.Δrel*var.x[1], var.Δabs)
  schedule(var, compute_next_time(integrator.quantizer, Δq, var.x))
end
