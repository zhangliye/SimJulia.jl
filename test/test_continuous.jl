using SimJulia

env = Environment()
cont = Continuous(QSSIntegrator{ExplicitQuantizer}, env, "x₁", "x₂"; order=3)
cont["x₁"] = Variable("x₁*x₂", 0.0)
cont["x₂"] = Variable("x₁+x₂^2", 1.0)
run(env, 5.0)
for i = 1:2
  println(cont.integrator.derivatives[i, 1](0.0, 1.0, 2.0))
  println(cont.integrator.derivatives[i, 3](0.0, 1.0, 2.0, 3.0, 4.0, 1.0, 2.0))
end
