# OvertVerify

<!-- [![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://amaleki2.github.io/OvertVerify.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://amaleki2.github.io/OvertVerify.jl/dev)
[![Build Status](https://travis-ci.com/amaleki2/OvertVerify.jl.svg?branch=master)](https://travis-ci.com/amaleki2/OvertVerify.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/amaleki2/OvertVerify.jl?svg=true)](https://ci.appveyor.com/project/amaleki2/OvertVerify-jl)
[![Coverage](https://codecov.io/gh/amaleki2/OvertVerify.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/amaleki2/OvertVerify.jl) -->

This repo integrates Overt and MIPVerify tools for the purpose of verifying closed-loop systems that are controlled by neural networks. [Overt](some link) is a julia package that provides Overt provides a relational piecewise linear over-approximation of any multi-dimensional functions. Such an over-approximation is used for converting non-linear functions that commonly appear in closed dynamical systems into a set of piecewise linear relations with piece linear nonlinear operation such as `min` and `max`. The over-approximated dynamics, together with the neural network controllers (which is assumed to be relu-activated) are then represented as a mixed integer program following the [MIPVerify algorithm](some link).

## Dependency
OvertVerify is tested with julia 1.x and Ubuntu 18, Windows 10 and SOME MC SYSTEM HERE operating systems. The following packages are required for OvertVerify:

```
Overt = "0.1"
Parameters = "0.12"
MathProgBase = "0.7"
MathOptInterface = "0.9"
JuMP = "0.21"
Interpolations = "0.12"
GLPK = "0.13"
Gurobi = "0.8"
LazySets = "1.37"
Crayons = "4.0"
```

## Installation
```
]
add https://github.com/amaleki2/OvertVerify
```

## Usage
Examples of reachability and satisfiability problems are setup in the `example` folder.
In order to test your own model, follow this instruction:
##### Setup mode
Your model can be specified in `my_model.jl` file, preferably located in `examples/models/my_model` folder. The file may include three functions:
- `1) my_model_dynamics(x, u)`: where `x` is the vector of system variables and `u` is the vector of control variables. This function returns a vector `dx` which specifies how the derivative of system variables are computed. For example, for a single pendulum system, the continuous-time system is:

<img src="https://render.githubusercontent.com/render/math?math=\dot{x}_1 = x_2">

<img src="https://render.githubusercontent.com/render/math?math=\dot{x}_2 = \frac{g}{l} \sin(x_1)"> +
<img src="https://render.githubusercontent.com/render/math?math=\frac{u_1 - c x_2}{ml^2}">

where
<img src="https://render.githubusercontent.com/render/math?math=g, l, m">  and
<img src="https://render.githubusercontent.com/render/math?math=c"> are model parameters: gravitational acceleration, pendulum length, pendulum mass and viscous drag coefficient). For the single pendulum model, `single_pend_dynamics(x, y)` looks like this:

```
function single_pend_dynamics(x::Array{T, 1} where {T <: Real},
	                          u::Array{T, 1} where {T <: Real})
	m, l, g, c = 0.5, 0.5, 1., 0.
    dx1 = x[2]
    dx2 = g/l * sin(x[1]) + 1 / (m*l^2) * (u[1] - c * x[2])
    return [dx1, dx2]
end
```

- `2)my_model_dynamics_overt(range_dict, N_overt; t_idx)`: This function generates an relation overapproximation of the original model. `range_dict` indicates the range of system variables as a dictionary and `N_overt` is the number of linear segment, the parameter that Overt library takes. Passing `N_overt=-1` lets Overt to choose this parameter efficiently.
Often times, one may be interested in verifying a desired property of the closed system over
a number of timesteps. Keeping a symbolic expression of the model over time allows OvertVerify to be significantly less conservative. To allow this to happen, we need to assign a secondary subscript to the system variables to keep track of the time step. parameter `t_idx` is that extra subscript. The default value `t_idx=nothing` means no symbolic representation is kept over time. The output of this function is a tuple of `(v_oA, [v_oA.output])` where `v_oA` is the `OverApproximation` object that includes overapproximation of nonlinear part of your model. For example, for the single pendulum model, the function looks like this:
```
function single_pend_dynamics_overt(range_dict, N_OVERT; t_idx=nothing)
	m, l, g, c = 0.5, 0.5, 1., 0.
	if isnothing(t_idx)
		v1 = :($(g/l) * sin(x1) + $(1/(m*l^2)) * u - $(c/(m*l^2)) * x2)
	else
    	v1 = "$(g/l) * sin(x1_$t_idx) + $(1/(m*l^2)) * u_$t_idx - $(c/(m*l^2)) * x2_$t_idx"
    	v1 = Meta.parse(v1)
	end
    v1_oA = overapprox_nd(v1, range_dict; N=N_OVERT)
    return v1_oA, [v1_oA.output]
end
```
Notice how `t_idx` is used as an extra subscript for system and control variables. While single pendulum problem has only one nonlinear relation, more complicated models may include multiple such equations. To combine all over-approximation objects, use `add_overapproximate`:
```
combined_v_oA = add_overapproximate([v1_oA, v2_oA])
```
see other models in `example\models` folder for your reference.

- `my_model_update_rule(input_vars, control_vars, overt_output_vars)`: this function determines how the over-approximated model may be constructed. The output is a dictionary
that indicates how the time-discrete integration of each state variable may be computed.
For example, for the single pendulum model, the function looks like this:
```
function single_pend_update_rule(input_vars, control_vars, overt_output_vars)
    ddth = overt_output_vars[1]
    integration_map = Dict(input_vars[1] => input_vars[2], input_vars[2] => ddth)
    return integration_map
end
```

In addition to these three functions, you need to define the system and control variable symbols, and eventually define the problem as an `OvertProblem`:
```
single_pend_input_vars = [:x1, :x2]
single_pend_control_vars = [:u]

SinglePendulum = OvertProblem(
	single_pend_dynamics,
	single_pend_dynamics_overt,
	single_pend_update_rule,
	single_pend_input_vars,
	single_pend_control_vars
)
```
