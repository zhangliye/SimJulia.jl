using SimJulia

system = Continuous()
x₁ = Variable(system, "x₁", 0.0, "0.02*x₂^2", AbstractString["x₂"], 2)
x₂ = Variable(system, "x₂", 20.0, "2020.0-100.0*x₁^2-100.0*x₂^2", AbstractString["x₁", "x₂"], 2)
