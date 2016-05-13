using SimJulia

# function print_solution_var1(var::Variable)
#   t = now(var.bev.env)
#   x = var.x[1]
#   Δx = abs(3/5*exp(-t)+2/5*exp(-6t) - x)
#   println("time=$t, $var=$x, err=$(abs(Δx/x))")
# end
#
# function print_solution_var2(var::Variable)
#   t = now(var.bev.env)
#   x = var.x[1]
#   Δx = abs(12/5*exp(-t)-2/5*exp(-6t) - x)
#   println("time=$t, $var=$x, err=$(abs(Δx/x))")
# end
#
#
# env = Environment()
# cont = Continuous(QSSIntegrator{ExplicitQuantizer}, env, ["x₁", "x₂"], ["p"]; order=3)
# #cont = Continuous(RKIntegrator, env, ["x₁", "x₂"], ["p"]; Δt_min=1.0e-12, Δt_max=1.0)
# var11 = Variable(env, "-5x₁+x₂", 1.0, 1.0e-6)
# var12 = Variable(env, "4x₁-2x₂+p", 2.0, 1.0e-6)
# var21 = Variable(env, "-5x₁+x₂", 1.0, 1.0e-6)
# var22 = Variable(env, "4x₁-2x₂+p", 2.0, 1.0e-6)
# cont["x₁"] = var11
# cont["x₂"] = var12
# cont["p"] = Parameter(0.0)
# #cont2["x₁"] = var21
# #cont2["x₂"] = var22
# #cont2["p"] = Parameter(0.0)
# append_callback(var11, print_solution_var1)
# append_callback(var12, print_solution_var2)
# tic()
# run(env, 5.0)
# toc()

function print_var(var::Variable)
  t = now(var.bev.env)
  y = var.x[1]
  println("t=$t, $var=$y")
end

env = Environment()
cont = Continuous(QSSIntegrator{ExplicitQuantizer}, env, ["x₁", "x₂"]; order=1)
#cont = Continuous(RKIntegrator, env, ["x₁", "x₂"]; Δt_min=1.0e-12, Δt_max=1.0)
x₁ = Variable(env, "0.01x₂", 20.0, 1.0)
x₂ = Variable(env, "2020.0-100x₁-100x₂", 0.0, 1.0)
cont["x₁"] = x₁
cont["x₂"] = x₂
#append_callback(x₁, print_var)
#append_callback(x₂, print_var)
tic()
run(env, 500.0)
toc()
