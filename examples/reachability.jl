using Overt
using LazySets
using OvertVerify


include("models/single_pendulum/single_pend.jl")

controller = "examples/single_pendulum_controller.nnet"

query = OvertQuery(
	SinglePendulum,    # problem
	controller,        # network file
	Id(),              # last layer activation layer Id()=linear, or ReLU()=relu
	"MIP",             # query solver, "MIP" or "ReluPlex"
	40,                # ntime
	0.1,               # dt
	-1,                # N_overt
	)

input_set = Hyperrectangle(low=[1., 0.], high=[1.2, 0.2])
all_sets, all_sets_symbolic = symbolic_reachability_with_concretization(query, input_set, [1, 1])
