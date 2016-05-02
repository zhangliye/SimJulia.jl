using SimJulia

env = Environment()
cont = Continuous(QSSIntegrator{ExplicitQuantizer}, env, ["x₁", "x₂", "x₃"], ["p₁"]; order=2)
cont["x₁"] = Variable("0.1x₁+0.01x₁*x₂-0.01x₁^2", 10.0, 0.001)
cont["x₂"] = Variable("-0.4x₂+0.5x₁*x₂+p₁", 10.0, 0.001)
cont["x₃"] = Variable("x₁/x₃", 10.0, 0.001)
cont["p₁"] = Parameter(1.0)
run(env, 300.0)
println(cont.deps)
