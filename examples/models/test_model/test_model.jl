function test_model_dynamics(x::Array{T, 1} where {T <: Real},
	                          u::Array{T, 1} where {T <: Real})
	dx1 = x[2]
    dx2 = -2 * x[1] - u[1]
    return [dx1, dx2]
end

function test_model_dynamics_overt(range_dict::Dict{Symbol, Array{T, 1}} where {T <: Real},
	                               N_OVERT::Int,
								   t_idx::Union{Int, Nothing}=nothing)
	if isnothing(t_idx)
		v1 = :(-2 * x1 - u)
	else
    	v1 = "-2 * x1_$t_idx - u_$t_idx"
    	v1 = Meta.parse(v1)
	end
    v1_oA = overapprox_nd(v1, range_dict; N=N_OVERT)
    return v1_oA, [v1_oA.output]
end

function test_model_update_rule(input_vars::Array{Symbol, 1},
	                            control_vars::Array{Symbol, 1},
								overt_output_vars::Array{Symbol, 1})
    ddth = overt_output_vars[1]
    integration_map = Dict(input_vars[1] => input_vars[2], input_vars[2] => ddth)
    return integration_map
end

test_model_input_vars = [:x1, :x2]
test_model_control_vars = [:u]

TestModel = OvertProblem(
	test_model_dynamics,
	test_model_dynamics_overt,
	test_model_update_rule,
	test_model_input_vars,
	test_model_control_vars
)
