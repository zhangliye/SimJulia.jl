using SimJulia

function print_solution_var1(var::Variable)
  t = now(var.bev.env)
  x = var.x[1]
  Δx = abs(3/5*exp(-t)+2/5*exp(-6t) - x)
  println("time=$t, $var=$x, err=$Δx")
end

function print_solution_var2(var::Variable)
  t = now(var.bev.env)
  x = var.x[1]
  Δx = abs(12/5*exp(-t)-2/5*exp(-6t) - x)
  println("time=$t, $var=$x, err=$Δx")
end

function print_solution_var3(var::Variable)
  t = now(var.bev.env)
  x = var.x[1]
  Δx = abs(-4+sqrt(16+2t) - x)
  println("time=$t, $var=$x, err=$Δx")
end

function print_solution_var4(var::Variable)
  t = now(var.bev.env)
  x = var.x[1]
  Δx = abs(1.0+0.5*t^2 - x)
  println("time=$t, $var=$x, err=$Δx")
end

env = Environment()
cont = Continuous(QSSIntegrator{ExplicitQuantizer}, env, ["x₁", "x₂", "x₃", "x₄"], ["p"]; order=4)
cont2 = Continuous(RKIntegrator, env, ["x₁", "x₂", "x₃", "x₄"], ["p"]; Δt_min=1.0e-12, Δt_max=1.0)
var11 = Variable(env, "-5x₁+x₂", 1.0, 1.0e-6)
var12 = Variable(env, "4x₁-2x₂+p", 2.0, 1.0e-6)
var13 = Variable(env, "1/(x₃+4.0)", 0.0, 1.0e-6, 1.0e-6)
var14 = Variable(env, "1.0*t", 1.0)
var21 = Variable(env, "-5x₁+x₂", 1.0, 1.0e-6)
var22 = Variable(env, "4x₁-2x₂+p", 2.0, 1.0e-6)
var23 = Variable(env, "1/(x₃+4.0)", 0.0, 1.0e-6, 1.0e-6)
var24 = Variable(env, "1.0*t", 1.0)
cont["x₁"] = var11
cont["x₂"] = var12
cont["x₃"] = var13
cont["x₄"] = var14
cont["p"] = Parameter(0.0)
cont2["x₁"] = var21
cont2["x₂"] = var22
cont2["x₃"] = var23
cont2["x₄"] = var24
cont2["p"] = Parameter(0.0)
append_callback(var11, print_solution_var1)
append_callback(var12, print_solution_var2)
append_callback(var13, print_solution_var3)
append_callback(var14, print_solution_var4)
tic()
run(env, 5.0)
toc()
