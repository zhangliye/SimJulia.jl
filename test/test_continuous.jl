using SimJulia
using Gadfly

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

type Counter
  count :: Int
  times :: Vector{Float64}
  values :: Vector{Float64}
  exact :: Vector{Float64}
end

function print_var(var::Variable, count::Counter)
  #t = now(var.bev.env)
  #y = var.x[1]
  #println("t=$t, $var=$y")
  count.count += 1
end

# env = Environment()
# cont = Continuous(QSSIntegrator{ExplicitQuantizer}, env, ["x₁", "x₂"]; order=3)
# #cont = Continuous(RKIntegrator, env, ["x₁", "x₂"]; Δt_min=1.0e-12, Δt_max=1.0)
# x₁ = Variable(env, "0.01x₂", 0.0, 1.0)
# x₂ = Variable(env, "2020.0-100x₁-100x₂", 20.0, 1.0)
# cont["x₁"] = x₁
# cont["x₂"] = x₂
# count₁ = Counter(0)
# count₂ = Counter(0)
# append_callback(x₁, print_var, count₁)
# append_callback(x₂, print_var, count₂)
# tic()
# run(env, 500.0)
# toc()
# println("$x₁: $(count₁.count) steps")
# println("$x₂: $(count₂.count) steps")

function print_solution_var1(var::Variable, count::Counter)
  t = now(var.bev.env)
  push!(count.times, t)
  x = var.x[1]
  push!(count.values, x)
  y = 1-sqrt(3)/3*exp(-t/2)*sin(sqrt(3)/2*t)-exp(-t/2)*cos(sqrt(3)/2*t)
  push!(count.exact, y)
  Δx = abs(y - x)
  println("time=$t, $var=$x, err=$(abs(Δx))")
  count.count += 1
end

function print_solution_var2(var::Variable, count::Counter)
  t = now(var.bev.env)
  push!(count.times, t)
  x = var.x[1]
  push!(count.values, x)
  y = sqrt(12)/3*exp(-t/2)*sin(sqrt(3)/2*t)
  push!(count.exact, y)
  Δx = abs(y - x)
  println("time=$t, $var=$x, err=$(abs(Δx))")
  count.count += 1
end

env = Environment()
#cont = Continuous(QSSIntegrator{ExplicitQuantizer}, env, ["x₁", "x₂"]; order=7)
cont = Continuous(RKIntegrator, env, ["x₁", "x₂"]; Δt_min=1.0e-12, Δt_max=1.0)
x₁ = Variable(env, "1.0x₂", 0.0, 1.0e-9)
x₂ = Variable(env, "1.0-1.0x₁-1.0x₂", 0.0, 1.0e-9)
cont["x₁"] = x₁
cont["x₂"] = x₂
count₁ = Counter(0, Float64[], Float64[], Float64[])
count₂ = Counter(0, Float64[], Float64[], Float64[])
append_callback(x₁, print_solution_var1, count₁)
append_callback(x₂, print_solution_var2, count₂)
tic()
run(env, 15.0)
toc()
println("$x₁: $(count₁.count) steps")
println("$x₂: $(count₂.count) steps")
plot(layer(x=count₁.times, y=abs(count₁.values-count₁.exact), Geom.line),
  #layer(x=count₁.times, y=count₁.exact, Geom.line),
  #layer(x=count₂.times, y=count₂.values, Geom.line),
  layer(x=count₂.times, y=abs(count₂.values-count₂.exact), Geom.line))
# for (index, value) in enumerate(count₁.values)
#   println("$(count₁.times[index]): $value")
# end
# for (index, value) in enumerate(count₂.values)
#   println("$(count₂.times[index]): $value")
# end
