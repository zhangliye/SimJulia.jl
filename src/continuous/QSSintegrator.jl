using Calculus

type QSSIntegrator{Q<:AbstractQuantizer} <: AbstractIntegrator
  cont :: Continuous
  quantizer :: Q
  derivatives :: Matrix{Function}
  steps :: Int
  function QSSIntegrator(cont::Continuous; order=3)
    n = length(cont.vars)
    integrator = new()
    integrator.cont = cont
    integrator.quantizer = Q(n, order)
    integrator.steps = 0
    return integrator
  end
end

function initialize(ev::AbstractEvent, env::AbstractEnvironment, integrator::QSSIntegrator)
  cont = integrator.cont
  quantizer = integrator.quantizer
  integrator.derivatives = calculate_derivatives(cont, quantizer.order)
  check_dependencies(cont)
  for (index, var) in enumerate(cont.vars)
    var.t = now(env)
    quantizer.q[index, 1] = var.x[1]
    var.x = zeros(Float64, quantizer.order+1)
    var.x[1] = quantizer.q[index, 1]
    #var.x[2:end] = evaluate_derivatives(integrator.derivatives[:,index], var.t, quantizer.q, cont.p)
    append_callback(var, step, env, integrator)
    schedule(var)
  end
end

function step(var::Variable, env::Environment, integrator::QSSIntegrator)
  cont = integrator.cont
  quantizer = integrator.quantizer
  n = length(cont.vars)
  integrator.steps += 1
  #println("step nr $(integrator.steps) of variable $(var.symbol) at time $(now(env))")
  Δt = now(env) - var.t
  var.x = advance_time(var.x, Δt)
  #println(var, ": ", var.x)
  var.t = now(env)
  update_quantized_state(quantizer, var.index, var.t, var.x)
  Δq = max(var.Δrel*var.x[1], var.Δabs)
  schedule(var, compute_next_time(var.x, Δq, quantizer.order))
  i = var.index
  for j in filter((j)->cont.deps[j,i], 1:n)
    Δt = var.t - cont.vars[j].t
    cont.vars[j].x[1] = update_time(cont.vars[j].x, Δt)
    cont.vars[j].t = var.t
    for k in filter((k)->cont.deps[j,k]&&(i!=k), 1:n)
      Δt = var.t - quantizer.t[k]
      quantizer.q[k, :] = advance_time(vec(quantizer.q[k,:]), Δt)
      quantizer.t[k] = var.t
    end
    cont.vars[j].x[2:end] = evaluate_derivatives(integrator.derivatives[:,j], var.t, quantizer.q, cont.p)
    Δq = max(cont.vars[j].Δrel*cont.vars[j].x[1], cont.vars[j].Δabs)
    Δx = copy(cont.vars[j].x)
    for (index, q) in enumerate(quantizer.q[j, :])
      Δx[index] -= q
      Δx[index] /= factorial(index-1)
    end
    Δt = recompute_next_time(Δx, Δq)
    if Δt != Inf || i != j
      schedule(cont.vars[j], Δt)
    end
  end
end
