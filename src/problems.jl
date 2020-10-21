using LazySets
export
    OvertProblem,
    OvertQuery,
	InfiniteHyperrectangle


mutable struct OvertProblem
	true_dynamics
	overt_dynamics
	update_rule
	input_vars
	control_vars
end

mutable struct OvertQuery
	problem::OvertProblem
	network_file::String
	last_layer_activation ##::ActivationFunction
	solver::String
	ntime::Int64
	dt::Float64
	N_overt::Int64
end

Base.copy(x::OvertQuery) = OvertQuery(
	x.problem,
	x.network_file,
	x.last_layer_activation,
	x.type,
	x.ntime,
	x.dt,
	x.N_overt
	)

# this datastructure allows the hyperrectnagle to have inifinite length.
# used for satisfiability target.
struct InfiniteHyperrectangle
	low
	high
	function InfiniteHyperrectangle(low, high)
		@assert all(low .≤	high) "low must not be greater than high"
		return new(low, high)
	end
end

"""
this datastructure creates a tilted hyperrectangle.
the hyper rectangle is tilted to be in the direction of the principle compoenents.
the parameters are similar to regular hyperrecntangle with an addition a rotation
matrix. the conversion matrix spcifies how the tilted hyperrectangle can be created
from a regular one. For example, a 2D system with X = [x; y] as the default axes
and Xₚ = [xₚ; yₚ] as the pc axes, then Xₚ = pca_mat * X.
parameters:
 - low: a list of minimum values in each direction
 - high: a list of maximum values in each direction
 - conv_mat: matrix of conversion to create the tilted axes from the default axes
"""
struct TiltedHyperrectangle
	center
	radius
	conv_mat
	function TiltedHyperrectangle(center, radius, conv_mat)
		@assert all(radius .≥ 0.) "low must not be greater than high"
		@assert length(center) == length(radius) == size(conv_mat)[1] == size(conv_mat)[2]
		return new(center, radius, conv_mat)
	end
end

function TiltedHyperrectangle(;low=low, high=high, conv_mat=conv_mat)
	center = 0.5 * (high .+ low)
	radius = 0.5 * (high .- low)
	return TiltedHyperrectangle(center, radius, conv_mat)
end


"""
this function computes a regular hyperrectnagle that contains a tilted hyper rectangle.
"""
get_bounding_box(input_set::Hyperrectangle) = input_set

function get_bounding_box(input_set::TiltedHyperrectangle)
	n_dim = length(low(input_set))
	conv_mat = input_set.conv_mat
	conv_mat_inv = inv(conv_mat)
	lows = Array{Float64}(undef, n_dim)
	highs = Array{Float64}(undef, n_dim)
	for i = 1:n_dim
		for j = 1:n_dim
			coef = conv_mat_inv[i, j]
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
	return bounding_box
end


import LazySets.low
import LazySets.high

low(x::InfiniteHyperrectangle)   = x.low
high(x::InfiniteHyperrectangle)  = x.high
low(x::TiltedHyperrectangle)     = x.center - x.radius
high(x::TiltedHyperrectangle)    = x.center + x.radius
