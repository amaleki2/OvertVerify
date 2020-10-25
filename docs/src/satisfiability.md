## Satisfiability problem specification
The second type of problems that `OvertVerify` supports are satisfiability problems.
Satisfiability problems directly encode the unsafe set (complement of the safe set) and return Sat/Unsat which indicates whether the unsafe set is reachable or not, without explicitly computing the reachable set.

Example of a satisfiability problem is provided in `examples\satisfiability.jl`. The setup is similar to reachability problems, except a target set (unsafe set) must be specified. The target set can be of type `Hyperrectangle` or a `InfiniteHyperrectangle`:
For example,
```julia
target_set = InfiniteHyperrectangle([-Inf, -Inf, -Inf, -Inf], [5.0, Inf, Inf, Inf])
```
indicates `x[1]<5` as an unsafe set. To solve the satisfiability problem, use
```julia
SATus, vals, ce = symbolic_satisfiability(query, input_set, target_set)
```
If problem returns `SAT`, meaning that the target set is reachable, a counter example is return in `ce`.
