const a21 = 1.0 / 5.0
const a31 = 3.0 / 40.0
const a32 = 9.0 / 40.0
const a41 = 44.0 / 45.0
const a42 = -56.0 / 15.0
const a43 = 32.0 / 9.0
const a51 = 19372.0 / 6561.0
const a52 = -25360.0 / 2187.0
const a53 = 64448.0 / 6561.0
const a54 = -212.0 / 729.0
const a61 = 9017.0 / 3168.0
const a62 = -355.0 / 33.0
const a63 = 46732.0 / 5247.0
const a64 = 49.0 / 176.0
const a65 = -5103.0 / 18656.
const b1 = 35.0 / 384.0
const b3 = 500.0 / 1113.0
const b4 = 125.0 / 192.0
const b5 = -2187.0 / 6784.0
const b6 = 11.0 / 84.0
const c2 = 1.0 / 5.0
const c3 = 3.0 / 10.0
const c4 = 4.0 / 5.0
const c5 = 8.0 / 9.0
const d1 = -12715105075.0 / 11282082432.0
const d3 = 87487479700.0 / 32700410799.0
const d4 = -10690763975.0 / 1880347072.0
const d5 = 701980252875.0 / 199316789632.0
const d6 = -1453857185.0 / 822651844.0
const d7 = 69997945.0 / 29380423.0
const e1 = 71.0 / 57600.0
const e3 = -71.0 / 16695.0
const e4 = 71.0 / 1920.0
const e5 = -17253.0 / 339200.0
const e6 = 22.0 / 525.0
const e7 = -1.0 / 40.0

type RKIntegrator <: AbstractIntegrator
  cont :: Continuous
  x :: Vector{Float64}
  Δt_min :: Float64
  Δt_max :: Float64
  Δt_next :: Float64
  Δabs :: Float64
	Δrel :: Float64
  derivatives :: Vector{Function}
  steps :: Int
  function RKIntegrator(cont::Continuous; Δt_min=1.0e-12, Δt_max=1.0)
    integrator = new()
    integrator.cont = cont
    integrator.Δt_min = Δt_min
    integrator.Δt_max = Δt_max
    integrator.Δt_next = Δt_max
    integrator.Δabs = Inf
    integrator.Δrel = Inf
    integrator.steps = 0
    return integrator
  end
end

function initialize(ev::AbstractEvent, env::AbstractEnvironment, integrator::RKIntegrator)
  cont = integrator.cont
  integrator.derivatives = vec(calculate_derivatives(cont, 1))
  integrator.x = Array(Float64, length(cont.vars))
  t = now(env)
  for (index, var) in enumerate(cont.vars)
    var.t = t
    integrator.x[index] = var.x[1]
    var.x = zeros(Float64, 9)
    var.x[1] = integrator.x[index]
    integrator.Δabs = min(integrator.Δabs, var.Δabs)
    integrator.Δrel = min(integrator.Δrel, var.Δrel)
  end
  evaluate_derivatives(cont.vars, integrator.derivatives, t, integrator.x, cont.p)
  new_ev = Event(env)
  append_callback(new_ev, step, env, integrator)
  schedule(new_ev)
end

function step(ev::AbstractEvent, env::AbstractEnvironment, integrator::RKIntegrator)
  cont = integrator.cont
  n = length(cont.vars)
  last_time = now(env)
  integrator.steps += 1
  Δt_now = integrator.Δt_next
  Δt_full = integrator.Δt_next
  h = Δt_now
  error_ratio = 0.0
  t = last_time
  println("Steps: $(integrator.steps)")
  for (index, var) in enumerate(cont.vars)
    var.t = last_time
    var.x[1] = integrator.x[index]
    var.x[2] = var.x[1]
    var.x[4] = h * var.x[3]
    for callback in var.bev.callbacks
      callback(var)
    end
  end
  while error_ratio < 1.0
    for (index, var) in enumerate(cont.vars)
      integrator.x[index] = var.x[2] + a21 * var.x[4]
    end
    Δt = c2 * h
    t = last_time + Δt
    evaluate_derivatives(cont.vars, integrator.derivatives, t, integrator.x, cont.p)
    for (index, var) in enumerate(cont.vars)
      var.x[5] = h * var.x[3]
      integrator.x[index] = var.x[2] + a31 * var.x[4] + a32 * var.x[5]
    end
    Δt = c3 * h
    t = last_time + Δt
    evaluate_derivatives(cont.vars, integrator.derivatives, t, integrator.x, cont.p)
    for (index, var) in enumerate(cont.vars)
      var.x[6] = h * var.x[3]
      integrator.x[index] = var.x[2] + a41 * var.x[4] + a42 * var.x[5] + a43 * var.x[6]
    end
    Δt = c4 * h
    t = last_time + Δt
    evaluate_derivatives(cont.vars, integrator.derivatives, t, integrator.x, cont.p)
    for (index, var) in enumerate(cont.vars)
      var.x[7] = h * var.x[3]
      integrator.x[index] = var.x[2] + a51 * var.x[4] + a52 * var.x[5] + a53 * var.x[6] + a54 * var.x[7]
    end
    Δt = c5 * h
    t = last_time + Δt
    evaluate_derivatives(cont.vars, integrator.derivatives, t, integrator.x, cont.p)
    for (index, var) in enumerate(cont.vars)
      var.x[8] = h * var.x[3]
      integrator.x[index] = var.x[2] + a61 * var.x[4] + a62 * var.x[5] + a63 * var.x[6] + a64 * var.x[7] + a65 * var.x[8]
    end
    Δt = h
    t = last_time + Δt
    evaluate_derivatives(cont.vars, integrator.derivatives, t, integrator.x, cont.p)
    for (index, var) in enumerate(cont.vars)
      var.x[5] = var.x[8]
      var.x[8] = h * var.x[3]
      var.x[9] = b1 * var.x[4] + b3 * var.x[6] + b4 * var.x[7] + b5 * var.x[5] + b6 * var.x[8]
      integrator.x[index] = var.x[2] + var.x[9]
    end
    evaluate_derivatives(cont.vars, integrator.derivatives, t, integrator.x, cont.p)
    error_ratio = 64.0
    for (index, var) in enumerate(cont.vars)
      err = abs(e1 * var.x[4] + e3 * var.x[6] + e4 * var.x[7] + e5 * var.x[5] + e6 * var.x[8] + e7 * h * var.x[3])
			tol = integrator.Δabs + 0.5 * integrator.Δrel * (abs(var.x[2]) + abs(integrator.x[index]))
			if error_ratio * err > tol
				error_ratio = tol / err
			end
			if error_ratio < 1.0
				if Δt_now < integrator.Δt_min
					throw("The requested integration accuracy could not be achieved!")
				end
				f = 0.0
				h *= 0.5
				if h < integrator.Δt_min
					f = integrator.Δt_min / Δt_now
					Δt_now = integrator.Δt_min
					integrator.Δt_next = integrator.Δt_min
				else
					f = 0.5
					Δt_now = h
					integrator.Δt_next = h
				end
				h = Δt_now
				for var in cont.vars
					var.x[4] *= f
				end
				break
			end
		end
	end
	if Δt_now == Δt_full
		integrator.Δt_next = (0.5 * error_ratio) ^ 0.2 * Δt_now
		if integrator.Δt_next > integrator.Δt_max
			integrator.Δt_next = integrator.Δt_max
		elseif integrator.Δt_next < integrator.Δt_min
			integrator.Δt_next = integrator.Δt_min
		end
	end
  schedule(ev, Δt_now)
end

function evaluate_derivatives(vars::Vector{Variable}, derivatives::Vector{Function}, t::Float64, x::Vector{Float64}, p::Vector{Float64})
  for (index, var) in enumerate(vars)
    var.x[3] = derivatives[index](t, x..., p...)
  end
end
