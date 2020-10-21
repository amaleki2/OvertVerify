include("../src/overt_to_mip.jl")
include("../src/problems.jl")
include("../src/mip_utils.jl")

mat = [[0., 2., 1.], [1., -2., 1.], [1., -2., 0.]]
mat = hcat(mat...)
input_set = TiltedHyperrectangle(low=[1., -1., 2.], high=[2., 1.5, 3.], conv_mat=mat)

bounding_box = get_bounding_box(input_set)
@assert all(low(bounding_box) .== [0.5, -0.75, -1.5])
@assert all(high(bounding_box) .== [2.75, 2.5, 2.75])

include("../examples/models/test_model/test_model.jl")

controller = "examples/models/test_model/test_controller.nnet"

query = OvertQuery(
	TestModel,         # problem
	controller,        # network file
	Id(),              # last layer activation layer Id()=linear, or ReLU()=relu
	"MIP",             # query solver, "MIP" or "ReluPlex"
	2,                 # ntime
	0.1,               # dt
	-1,                # N_overt
	)
input_set = Hyperrectangle([2.0, 1.5, -2.0], [1.0, 0.5, 1.0])
input_set = Hyperrectangle(low=[1.0, 1.0, -3.0], high=[3.0, 2.0, -1.0])
input_set = Hyperrectangle(low=[1., 0.], high=[1.2, 0.2])
all_sets, all_sets_symbolic = symbolic_reachability_with_concretization(query, input_set, [1, 1])
tol = 1e-4
@assert all(low.(all_sets[1])[2] .≥ [1., -0.28] .- tol)
@assert all(high.(all_sets[1])[2] .≤ [1.22, 0.] .+ tol)

if true
	using Plots
	idx = [1,2]
	all_sets = vcat(all_sets...)
	fig = plot_output_sets(all_sets; idx=idx, fig=nothing, fillalpha=0)
	output_sets, xvec, x0 = monte_carlo_simulate(query, input_set)
	fig = plot_output_hist(xvec, query.ntime; fig=fig, idx=idx)
end

# include("../src/mip_pca.jl")
# in_mat = [[1.0, 0.], [0., 1.]]
# in_mat = hcat(in_mat...)
#
# input_set = TiltedHyperrectangle(low=[1.0, 1.0, -3.0],
#                                  high=[3.0, 2.0, -1.0],
# 								 conv_mat=conv_mat)
# input_set = TiltedHyperrectangle(low=[1., 0.], high=[1.2, 0.2], conv_mat=in_mat)
# out_mat = [[0.5, 0.3], [0., 1.]]
# out_mat = hcat(out_mat...)
# all_sets, all_sets_symbolic = symbolic_reachability(query, input_set, out_mat)



# using LazySets
# using OvertVerify


# include("models/test_model/test_model.jl")
#
# controller = "models/test_model/test_model_controller.nnet"
#
# query = OvertQuery(
# 	SinglePendulum,    # problem
# 	controller,        # network file
# 	Id(),              # last layer activation layer Id()=linear, or ReLU()=relu
# 	"MIP",             # query solver, "MIP" or "ReluPlex"
# 	40,                # ntime
# 	0.1,               # dt
# 	-1,                # N_overt
# 	)
#
# mat = ones(2, 2)
# input_set = TiltedHyperrectangle(low=[1., 0.], high=[1.2, 0.2])
# all_sets, all_sets_symbolic = symbolic_reachability_with_concretization(query, input_set, [15, 15, 10])

# model = Model(with_optimizer(Gurobi.Optimizer, OutputFlag=0))
# @variable(model, x1)
# @variable(model, x2)
# @variable(model, x3)
# @variable(model, 1. <= xn1 <= 2.)
# @variable(model, -1. <= xn2 <= 1.5)
# @variable(model, 2. <= xn3 <= 3.)
# @constraint(model,        x2 + x3  == xn1)
# @constraint(model, 2x1 - 2x2 - 2x3 == xn2)
# @constraint(model, x1  + x2        == xn3)
# lows = []
# highs = []
# for x in [x1, x2, x3]
#     @objective(model, Min, x)
#     optimize!(model)
#     push!(lows, objective_value(model))
#
#     @objective(model, Max, x)
#     optimize!(model)
#     push!(highs, objective_value(model))
# end
