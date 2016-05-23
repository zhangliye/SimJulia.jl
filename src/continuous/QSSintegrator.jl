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
    quantizer.q[1, index] = var.x[1]
    var.x = zeros(Float64, quantizer.order+1)
    var.x[1] = quantizer.q[1, index]
    append_callback(var, step, env, integrator)
    schedule(var)
  end
  for (index, var) in enumerate(cont.vars)
    var.x[2] = integrator.derivatives[1, index](var.t, quantizer.q[1,:]..., cont.p...)
  end
end

function step(var::Variable, env::AbstractEnvironment, integrator::QSSIntegrator)
  cont = integrator.cont
  quantizer = integrator.quantizer
  n = length(cont.vars)
  integrator.steps += 1
  t = now(env)
  #println("step nr $(integrator.steps) of variable $(var.symbol) at time $t")
  Δt = t - var.t
  var.x = advance_time(var.x, Δt)
  #println("$var=$(var.x)")
  var.t = t
  update_quantized_state(quantizer, var.index, t, var.x)
  #println("q=$(quantizer.q)")
  Δq = max(var.Δrel*var.x[1], var.Δabs)
  Δt = compute_next_time(var.x, Δq, quantizer.order)
  #println("Δt=$Δt")
  schedule(var, Δt)
  i = var.index
  for j in filter((j)->cont.deps[j,i], 1:n)
    dep = cont.vars[j]
    Δt = t - dep.t
    dep.x[1] = update_time(dep.x, Δt)
    dep.t = t
    Δt = t - quantizer.t[j]
    quantizer.q[:,j] = advance_time(quantizer.q[:,j], Δt)
    quantizer.t[j] = t
    for k in filter((k)->cont.deps[j,k]&&(i!=k)&&(j!=k), 1:n)
      Δt = t - quantizer.t[k]
      quantizer.q[:,k] = advance_time(quantizer.q[:,k], Δt)
      quantizer.t[k] = t
    end
    dep.x[2:end] = evaluate_derivatives(integrator.derivatives[:,j], t, transpose(quantizer.q), cont.p)
    #println("$dep, x=$(dep.x)")
    #println("q=$(quantizer.q)")
    Δq = max(dep.Δrel*dep.x[1], dep.Δabs)
    Δt = recompute_next_time(dep.x, quantizer.q[:,j], Δq)
    #println("Δt=$Δt")
    schedule(dep, Δt)
  end
end
