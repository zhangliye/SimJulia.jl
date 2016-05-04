using SimJulia

function print_solution_var1(var::Variable)
  t = now(var.bev.env)
  Δt = t - var.t
  println("time=$t, x₁=$(SimJulia.update_time(var.x, Δt)), x₁ex=$(3/5*exp(-t)+2/5*exp(-6t))")
end

function print_solution_var2(var::Variable)
  t = now(var.bev.env)
  Δt = t - var.t
  println("time=$t, x₂=$(SimJulia.update_time(var.x, Δt)), x₂ex=$(12/5*exp(-t)-2/5*exp(-6t))")
end

env = Environment()
cont = Continuous(QSSIntegrator{ExplicitQuantizer}, env, ["x₁", "x₂"]; order=7)
var1 = Variable(env, "-5x₁+x₂", 1.0, 1.0e-10)
var2 = Variable(env, "4x₁-2x₂", 2.0)
cont["x₁"] = var1
cont["x₂"] = var2
append_callback(var1, print_solution_var1)
append_callback(var2, print_solution_var2)
run(env, 2.0)
