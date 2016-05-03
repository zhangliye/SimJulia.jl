using SimJulia

env = Environment()
cont = Continuous(QSSIntegrator{ExplicitQuantizer}, env, ["x₁", "x₂"], ["p₁"]; order=2)
#cont["x₁"] = Variable("0.1x₁+0.01x₁*x₂-0.01x₁^2", 10.0, 0.001)
#cont["x₂"] = Variable("-0.4x₂+0.5x₁*x₂+p₁", 10.0, 0.001)
cont["x₁"] = Variable("x₁+x₂-1.0", 0.0, 1.0)
cont["x₂"] = Variable("1.0-x₁-x₂", 0.0, 1.0)
cont["p₁"] = Parameter(0.0)
run(env, 10.0)
