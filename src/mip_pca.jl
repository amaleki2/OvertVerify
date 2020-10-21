function solve_for_reachability_along_pca(mip_model::OvertMIP,
	                                      query::OvertQuery,
	                                      oA_vars::Array{Symbol, 1},
										  t_idx::Union{Int64, Nothing},
										  pca_mat::Union{Nothing, Array{Float64, 2}})

	"""
	blah
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
	next_v_mip = [v + dt * dv for (v, dv) in zip(vars_mip, dvars_mip)]
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
	reacheable_set_along_pca = TiltedHyperrectangle(lows, highs, pca_mat)
	return reacheable_set_along_pca
end


function symbolic_reachability(query::OvertQuery,
							   input_set::TiltedHyperrectangle,
							   pca_mat_out::Union{Nothing, Array{Float64, 2}})
	input_set_box = get_bounding_box(input_set)
	mip_model, all_sets, all_oA_vars = setup_mip_with_overt_constraints(query, input_set_box)
	add_controllers_constraints!(mip_model, query, all_sets)
    mip_summary(mip_model.model)
	match_io!(mip_model, query, all_oA_vars)
	set_symbolic = solve_for_reachability_along_pca(mip_model, query, all_oA_vars[end], query.ntime, pca_mat_out)
	return all_sets, set_symbolic
end


function symbolic_reachability_with_concretization(query::OvertQuery,
	                                               input_set::TiltedHyperrectangle,
												   concretize_every::Array{Int, 1},
												   pca_matrices::Array{Array{Float64, 2}, 1})

	"""
	blah
	"""
	ntime = query.ntime
	all_concrete_sets = []
	all_symbolic_sets = []
	this_set = copy(input_set)
	for idx in length(concretize_every)
		query.ntime = concretize_every[idx]
		pca_mat = pca_matrices[idx]
		concrete_sets, symbolic_set = symbolic_reachability(query, this_set, pca_mat)
		push!(all_concrete_sets, concrete_sets)
		push!(all_symbolic_sets, symbolic_set)
		this_set = copy(symbolic_set)
	end

	query.ntime = ntime
	return all_concrete_sets, all_symbolic_sets
end
