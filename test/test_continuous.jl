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
  x = SimJulia.update_time(var.x, Δt)
  Δx = abs(12/5*exp(-t)-2/5*exp(-6t) - x)
  println("time=$t, $var=$x, err=$Δx")
end

function print_solution_var3(var::Variable)
  t = now(var.bev.env)
  Δt = t - var.t
  x = SimJulia.update_time(var.x, Δt)
  Δx = abs(-4+sqrt(16+2t) - x)
  println("time=$t, $var=$x, err=$Δx")
end

env = Environment()
cont = Continuous(QSSIntegrator{ExplicitQuantizer}, env, ["x₁", "x₂", "x₃"], ["p"]; order=5)
var1 = Variable(env, "-5x₁+x₂", 1.0, 1.0e-8)
var2 = Variable(env, "4x₁-2x₂+p", 2.0, 1.0e-8)
var3 = Variable(env, "1/(x₃+4.0)", 0.0)
cont["x₁"] = var1
cont["x₂"] = var2
cont["x₃"] = var3
cont["p"] = Parameter(0.0)
append_callback(var1, print_solution_var1)
append_callback(var2, print_solution_var2)
append_callback(var3, print_solution_var3)
run(env, 5.0)
