## Reachability problem specification
One way to prove the safety of a dynamical system is to compute its reachable set.
The reachable set at a given timestep `t` is comprised of all the possible states that the system may visit at time `t`.
Reachable set computation can be solved in two different ways.
One approach is to obtain a concrete reachable set at every timestep. Here, we define the concrete reachable set as an explicit representation of reachable set.
This approach is computational cheap, but yield conservative results. The second approach is to maintain an implicit symbolic representation of the reachable set at the intermediate timesteps, and only concretize at the final timestep. In order to keep the problem computationally tractable, and yet obtain a reasonably accurate reachable set, one may use a hybrid approach, where concretization is performed only when necessary.

An example of a reachability problem is provided in `examples/reachability.jl`. After importing the files containing the description of closed loop system, as explained above, an `OvertQuery` object shall be defined:
```julia
query = OvertQuery(
    SinglePendulum,    # problem
    controller,        # network file
    Id(),              # last layer activation layer Id()=linear, or ReLU()=relu
    "MIP",             # query solver, "MIP" or "ReluPlex"
    40,                # ntime
    0.1,               # dt
    -1,                # N_overt
    )
```
The inputs of the object are problem instance (of type `OvertProblem`), controller file, last layer activation layer,
problem input set is specified by a hyperrectangle, horizon of verification (number of timesteps), time discretization constant `dt` and finally number of linear segments `N_overt`.
```julia
input_set = Hyperrectangle(low=[1., 0.], high=[1.2, 0.2])
```
Finally, reachability sets can be computed with either of these functions:
* `symbolic_reachability` : compute reachability by concretization at every timesteps.
* `symbolic_reachability_with_splitting`: compute reachability by splitting the input set into smaller sets, and then concretizing at every timesteps.
* `symbolic_reachability_with_concretization`: computing reachability by concretizing only at a given set of timesteps.

* `symbolic_reachability_with_concretization_with_splitting`:
 compute reachability by splitting the input set into smaller sets, and thenconcretizing only at a given set of timesteps.

 For example,
 `symbolic_reachability_with_concretization_with_splitting(query, input_set, [10, 20, 30, 40], [1, 3])` computes reachabilityset of the `query` problem over `input_set` initial set, by first dividing the input set along axis 1 and 3 of the system vector, and then concretizing at timesteps 10, 20, 30 and 40.
