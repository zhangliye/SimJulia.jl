using SimJulia

env = Environment()
system = Continuous(env, 2)
x₁ = Variable(system, "x₁", 0.0, "0.02*x₂^2", "x₂")
x₂ = Variable(system, "x₂", 0.0, "2020.0-100.0*x₁^2-100.0*x₂^2", "x₁", "x₂")
x₂.derivs[2](1.0, 2.0, 3.0, 1.0, 2.0)
