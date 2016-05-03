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
    return integrator
  end
end

function initialize(ev::AbstractEvent, env::AbstractEnvironment, integrator::QSSIntegrator)
  println("initialize")
  integrator.derivatives = calculate_derivatives(integrator.cont, integrator.quantizer.order)
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

function step(var::Variable, env::Environment, integrator::QSSIntegrator)
  cont = integrator.cont
  quantizer = integrator.quantizer
  println("step of variable $(var.symbol) at time $(now(env))")
  var.bev = BaseEvent(env)
  append_callback(var, step, env, integrator)
  Δt = now(env) - var.t
  var.x = advance_time(var.x, Δt)
  var.t = now(env)
  update_quantized_state(quantizer, var.index, var.t, var.x)
  Δq = max(var.Δrel*var.x[1], var.Δabs)
  schedule(var, compute_next_time(quantizer, Δq, var.x))
  i = var.index
  for j in filter((j)->cont.deps[j,i], 1:length(cont.vars))
    Δt = var.t - cont.vars[j].t
    cont.vars[j].x[1] = update_time(cont.vars[j].x, Δt)
    cont.vars[j].t = var.t
    for k in filter((k)->cont.deps[j,k]&&(i!=k), 1:length(cont.vars))
      Δt = var.t - quantizer.t[k]
      quantizer.q[k, :] = advance_time(vec(quantizer.q[k,:]), Δt)
      quantizer.t[k] = var.t
    end
    cont.vars[j].x[2:end] = evaluate_derivatives(vec(integrator.derivatives[j,:]), var.t, quantizer.q, cont.p)
    Δq = max(cont.vars[j].Δrel*cont.vars[j].x[1], cont.vars[j].Δabs)
    Δx = cont.vars[j].x
    Δx[1:end-1] -= vec(quantizer.q[j, :])
    schedule(cont.vars[j], recompute_next_time(quantizer, Δq, Δx))
  end
end

function evaluate_derivatives(derivs::Vector{Function}, t::Float64, q::Matrix{Float64}, p::Vector{Float64})
  order = length(derivs)
  res = Array(Float64, order)
  for i in 1:order
    res[i] = derivs[i](t, q[:,1:i]..., p...)
  end
  return res
end
