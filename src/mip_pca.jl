function find_pca(x_sim)

end

function get_bounding_box(input_set::Hyperrectangle,
	                      pca_mat::Union{Nothing, Array{Float64, 2}})
	if isnothing(pca_mat)
		bounding_box = input_set
	else
		n_dim = size(pca_mat)[1]
		pca_mat_inv = inv(pca_mat)
		lows = Array{Float64}(undef, 0)
		highs = Array{Float64}(undef, 0)
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



function solve_for_reachability_along_pca(mip_model::OvertMIP,
	                                      query::OvertQuery,
	                                      oA_vars::Array{Symbol, 1},
										  t_idx::Union{Int64, Nothing},
										  pca_mat::Union{Nothing, Array{Float64, 2}})

	"""
	this function setup states in the future timestep and optimize that.
	this will give a minimum and maximum on each of the future timesteps.
	the final answer is a hyperrectangle.
	inputs:
	- mip_model: OvertMIP object that contains all overt and controller constraints.
	- query: OvertQuery
	- oA_vars: output variables of overt.
	- t_idx: this is for timed dynamics, when the symbolic version is called.
	        if t_idx is an integer, a superscript will be added to all state and
	        control variable, indicating the timestep is a symbolic represenation.
	        default is nothing, which does not do the timed dynamics.
	outputs:
	- reacheable_set: smallest hyperrectangle that contains the reachable set.
	"""
	if isnothing(pca_mat)
		return solve_for_reachability(mip_model, query, oA_vars, t_idx)
	end

	# inputs of reachable set hyperrectangle are initialized
	lows = Array{Float64}(undef, 0)
	highs = Array{Float64}(undef, 0)

	input_vars = query.problem.input_vars
	control_vars = query.problem.control_vars
	update_rule = query.problem.update_rule
	dt = query.dt

	if !isnothing(t_idx)
		input_vars_last = [Meta.parse("$(v)_$t_idx") for v in input_vars]
		control_vars_last = [Meta.parse("$(v)_$t_idx") for v in control_vars]
		integration_map = update_rule(input_vars_last, control_vars_last, oA_vars)
	else
		input_vars_last = input_vars
		integration_map = query.problem.update_rule(input_vars, control_vars, oA_vars)
	end

	# setup the future state and optimize.
	vars  = input_vars_last
	dvars = [integration_map[v] for v in vars]
	vars_mip  = [mip_model.vars_dict[v] for v in vars]
	dvars_mip = [mip_model.vars_dict[v] for v in dvars]
	next_v_mip = [v + dt * dv for (v, dv) in zip(vars, dvars)]
	next_v_mip_along_pca = pca_mat * next_v_mip

	lows = Array{Float64}(undef, 0)
	highs = Array{Float64}(undef, 0)
	for v in next_v_mip_along_pca
		@objective(mip_model.model, Min, v)
		JuMP.optimize!(mip_model.model)
		push!(lows, objective_value(mip_model.model))
		@objective(mip_model.model, Max, v)
		JuMP.optimize!(mip_model.model)
		push!(highs, objective_value(mip_model.model))
   	end

	# get the hyperrectangle.
	reacheable_set_along_pca = Hyperrectangle(low=lows, high=highs)
	return reacheable_set_along_pca
end



function symbolic_reachability(query::OvertQuery, input_set::Hyperrectangle,
	                           pca_mat::Union{nothing, Array{Real, 1}})


	input_set_box = get_bounding_box(input_set)
	mip_model, all_sets, all_oA_vars = setup_mip_with_overt_constraints(query, input_set_box)
	add_controllers_constraints!(mip_model, query, all_sets)
    mip_summary(mip_model.model)
	match_io!(mip_model, query, all_oA_vars)
	set_symbolic = solve_for_reachability(mip_model, query, all_oA_vars[end], query.ntime)
	return all_sets, set_symbolic

function symbolic_reachability_with_concretization(query::OvertQuery,
	input_set::Hyperrectangle, concretize_every::Union{Int, Array{Int, 1}},
	pca_flag::Bool)

	"""
	with pca_flag turned on, the optimization happens along the pca's of
	simulations.
	"""
	if !pca_flag
	   return symbolic_reachability_with_concretization(query, input_set, concretize_every)
	end

	ntime = query.ntime
	if isa(concretize_every, Int)
		@assert ntime % concretize_every == 0
		n_loops = Int(query.ntime / concretize_every)
		concretize_every = [concretize_every for i in 1:n_loops]
	end


	all_concrete_sets = []
	all_symbolic_sets = []
	this_set = copy(input_set)
	for n in concretize_every
		query.ntime = n
		concrete_sets, symbolic_set = symbolic_reachability(query, this_set)
		push!(all_concrete_sets, concrete_sets)
		push!(all_symbolic_sets, symbolic_set)
		this_set = copy(symbolic_set)
	end

	query.ntime = ntime
	return all_concrete_sets, all_symbolic_sets
end
