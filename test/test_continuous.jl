using SimJulia

env = Environment()
cont = Continuous(QSSIntegrator{ExplicitQuantizer}, env, "x₁", "x₂"; order=1)
cont["x₁"] = Variable("x₁*x₂", 0.0)
cont["x₂"] = Variable("x₁+x₂^2", 1.0)
run(env)
