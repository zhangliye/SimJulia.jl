using Calculus

abstract AbstractVariable

type Continuous
  vars :: Dict{AbstractString, AbstractVariable}
  rev_deps :: Dict{AbstractString, Set{AbstractVariable}}
  function Continuous()
    cont = new()
    cont.vars = Dict{AbstractString, AbstractVariable}()
    cont.rev_deps = Dict{AbstractString, Set{AbstractVariable}}()
    return cont
  end
end

type Variable <: AbstractVariable
  cont :: Continuous
  name :: AbstractString
  x :: Vector{Float64}
  q :: Vector{Float64}
  derivs :: Vector{Function}
  deps :: Vector{AbstractString}
  order :: Int
  function Variable(cont::Continuous, name::AbstractString, x₀::Float64, f::AbstractString, deps::Vector{AbstractString}, order::Int)
    var = new()
    var.cont = cont
    cont.vars[name] = var
    var.name = name
    var.x = Vector{Float64}()
    push!(var.x, x₀)
    var.q = Vector{Float64}()
    var.derivs = Vector{Function}()
    n = length(deps)
    args = ""
    for i in 1:n
      args *= deps[i]
      if i != n
        args *= ","
      end
    end
    push!(var.derivs, eval(parse("($args)->$f")))
    var.deps = deps
    for i in 1:n
      if !haskey(cont.rev_deps, deps[i])
        cont.rev_deps[deps[i]] = Set{AbstractVariable}()
      end
      push!(cont.rev_deps[deps[i]], var)
    end
    var.order = order
    if order > 1
      ∇f = differentiate(f, deps)
      df = ""
      for i in 1:n
        args *= ",d"*deps[i]
        df *= "$(∇f[i])*"*"d"*deps[i]
        if i != n
          df *= "+"
        end
      end
      push!(var.derivs, eval(parse("($args)->$df")))
    end
    return var
  end
end
