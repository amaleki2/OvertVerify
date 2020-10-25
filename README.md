# OvertVerify

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://sisl.github.io/OvertVerify.jl/stable)
[![Build Status](https://travis-ci.com/sisl/OvertVerify.jl.svg?branch=master)](https://travis-ci.com/sisl/OvertVerify.jl)
[![Coverage](https://codecov.io/gh/sisl/OvertVerify.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/sisl/OvertVerify.jl)

This repo integrates Overt and MIPVerify tools for the purpose of verifying closed-loop systems that are controlled by neural networks. [Overt](https://sisl.github.io/Overt.jl) is a `julia` package that provides a relational piecewise linear over-approximation of any multi-dimensional functions. Such an over-approximation is used for converting non-linear functions that commonly appear in closed dynamical systems into a set of piecewise linear relations with piece linear nonlinear operation such as `min` and `max`. The over-approximated dynamics, together with the neural network controllers (which is assumed to be relu-activated) are then represented as a mixed integer program following the [MIPVerify algorithm](https://arxiv.org/abs/1711.07356).

## Dependency
OvertVerify is tested with julia 1.x and Ubuntu 18 and Windows 10 operating systems. The following packages are required for OvertVerify:

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
add https://github.com/sisl/OvertVerify
```

## Usage
See the accompanied documentation. 
