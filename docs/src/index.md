# OvertVerify

## Introduction
This repo integrates Overt and MIPVerify tools for the purpose of verifying closed-loop systems that are controlled by neural networks. [Overt](https://sisl.github.io/Overt.jl) is a `julia` package that provides a relational piecewise linear over-approximation of any multi-dimensional functions. Such an over-approximation is used for converting non-linear functions that commonly appear in closed dynamical systems into a set of piecewise linear relations with piece linear nonlinear operation such as `min` and `max`. The over-approximated dynamics, together with the neural network controllers (which is assumed to be relu-activated) are then represented as a mixed integer program following the [MIPVerify algorithm](https://arxiv.org/abs/1711.07356).

Examples of reachability and satisfiability problems are setup in the `example` folder. Below you can find instructions for
 - [set up a new model](src/setup_model.md)
 - [define a new controller](define_controller.md)
 - [reachability problem specification](reachability.md)
 - [satisfiability problem specification](satisfiability.md)
