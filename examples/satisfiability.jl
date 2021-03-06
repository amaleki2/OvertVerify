using Overt
using LazySets
using OvertVerify

include("models/car/simple_car.jl")

network = "examples/car_controller.nnet"

query = OvertQuery(
	SimpleCar,  # problem
	network,    # network file
	Id(),      	# last layer activation layer Id()=linear, or ReLU()=relu
	"MIP",     	# query solver, "MIP" or "ReluPlex"
	25,        	# ntime
	0.2,       	# dt
	-1,        	# N_overt
	)

input_set = Hyperrectangle(low=[9.5, -4.5, 2.1, 1.5], high=[9.55, -4.45, 2.11, 1.51])
target_set = InfiniteHyperrectangle([-Inf, -Inf, -Inf, -Inf], [5.0, Inf, Inf, Inf])
SATus, vals, stats = symbolic_satisfiability(query, input_set, target_set)
