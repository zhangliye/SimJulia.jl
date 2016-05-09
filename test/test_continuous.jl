using SimJulia

function print_solution_var1(var::Variable)
  t = now(var.bev.env)
  Δt = t - var.t
  x = SimJulia.update_time(var.x, Δt)
  Δx = abs(3/5*exp(-t)+2/5*exp(-6t) - x)
  println("time=$t, $var=$x, err=$Δx")
end

function print_solution_var2(var::Variable)
  t = now(var.bev.env)
  Δt = t - var.t
  t = now(var.bev.env)
  Δt = t - var.t
  x = SimJulia.update_time(var.x, Δt)
  Δx = abs(12/5*exp(-t)-2/5*exp(-6t) - x)
  println("time=$t, $var=$x, err=$Δx")
end

env = Environment()
cont = Continuous(QSSIntegrator{ExplicitQuantizer}, env, ["x₁", "x₂"], ["p"]; order=4)
var1 = Variable(env, "-5x₁+x₂", 1.0, 1.0e-6)
var2 = Variable(env, "4x₁-2x₂+p", 2.0, 1.0e-6)
cont["x₁"] = var1
cont["x₂"] = var2
cont["p"] = Parameter(0.0)
append_callback(var1, print_solution_var1)
append_callback(var2, print_solution_var2)
run(env, 5.0)
