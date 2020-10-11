
using LazySets

function get_bounding_box(input_set::Hyperrectangle, pca_mat::Union{Nothing, Array{Float64, 2}})
	if isnothing(pca_mat)
		bounding_box = input_set
	else
		n_dim = size(pca_mat)[1]
		pca_mat_inv = inv(pca_mat)
		lows = zeros(n_dim)
		highs = zeros(n_dim)
		for i = 1:n_dim
			for j = 1:n_dim
				coef = pca_mat_inv[i, j]
				if coef > 0
					lows[i] += low(input_set)[j]*coef
					highs[i] += high(input_set)[j]*coef
				else
					lows[i] += high(input_set)[j]*coef
					highs[i] += low(input_set)[j]*coef
				end
			end
		end
		bounding_box = Hyperrectangle(low=lows, high=highs)
	end
	return bounding_box
end

input_set = Hyperrectangle(low=[1., -1., 2.], high=[2., 1.5, 3.])
pca_mat = [[0., 2., 1.], [1., -2., 1.], [1., -2., 0.]]
pca_mat = hcat(pca_mat...)

bounding_box =  get_bounding_box(input_set, pca_mat)
@assert low(bounding_box) == [0.5, -0.75, -1.5]
@assert high(bounding_box) == [2.75, 2.5, 2.75]
#
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
