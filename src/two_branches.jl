module TwoBranches 

using Distributions
using MicroLogging

include("cec14_func.jl")
include("check_bounds.jl")

export main



type SearchParams
	max_evaluations::Unsigned
	max_diffusion::Unsigned
	error_threshold::Real
end


type Particle
	x::Array #Position
	f::Real #Evaluation in x
end

function Base.isless(p1::Particle, p2::Particle)
	p1.f < p2.f
end

function Base.copy(p::Particle)
	Particle(copy(p.x), p.f)
end


function main(args, func_number)
	dim = parse(Int, args["--dimension"][1])
	diffusion = 1
	if length(args["--diffusion"]) != 0
		diffusion = parse(Int, args["--diffusion"][1])
	end
	search_params = SearchParams(10000*dim, diffusion, 1e-8)
	search_space = cec14_func(func_number, dim)
	tic()
	opt = stochastic_fractal_search(search_params, search_space)
	opt.f, opt.f - search_space.opt, toq() 
end


function stochastic_fractal_search(sp::SearchParams, s::SearchSpace)
	evaluations = 0
	# Initial population of particles 
	x = s.lbound + rand(s.dim).*(s.ubound - s.lbound)
	particles = [Particle(x, s.f(x))]
	pos_diffs = [1.0]
	value_diffs = [1.0]
	value_diffs_mean = 1.0
    
	# Best particle of the initial population 
	best = particles[1] 
    
	g = 0
	σ = 1
	c = 0
	while evaluations < sp.max_evaluations && best.f - s.opt > sp.error_threshold 
		g += 1
		# Diffusion ----------------------------
		for i = 1:length(particles)
			if value_diffs[i] >= 0.01
				σ = (abs(value_diffs[i])/value_diffs_mean + 1e-8)/(pos_diffs[i])+1e-8 * 2*σ
				c = 0
			else
				σ = (pos_diffs[i])+1e-8/(abs(value_diffs[i])/value_diffs_mean + 1e-8) * 2*σ
				c += 1
			end
			μ = particles[i].x
			pos_diffs[i] = 0
			value_diffs[i] = 0
			new_par = Particle([], Inf) # New particle with infinity cost
			for j = 1:sp.max_diffusion
				x = check_bounds(rand.(Normal.(μ, σ)), s.lbound, s.ubound)
				pos_diffs[i] += sqrt(sum((x - particles[i].x).^2))
				f = s.f(x)
				value_diffs[i] += particles[i].f - f
				if f <= new_par.f
					new_par.x = x
					new_par.f = f
				end
			end
			particles[i] = new_par
			pos_diffs[i] /= sp.max_diffusion
			value_diffs[i] /= sp.max_diffusion
		end
		# End diffusion ------------------------
		push!(particles, exploration_diffusion(sp, s))
		push!(pos_diffs, 1.0)
		push!(value_diffs, 1.0)
		value_diffs_mean = sum(abs.(value_diffs))/length(value_diffs)
		evaluations += length(particles)*sp.max_diffusion
		new_best = minimum(particles)
		if (new_best.f < best.f)
			best = copy(new_best)
		end
        
		@debug "Iteration $g"
		@debug "$evaluations evaluations"
		@debug "$(best.x)"
		@debug "$(best.f)"
		@debug "Step mean: $(sum(pos_diffs)/length(pos_diffs))"
		@debug "Values mean: $(sum(value_diffs)/length(value_diffs))"
	end
	best
end


function diffusion(p::Particle, sp::SearchParams, s::SearchSpace, pos_diff::Real, value_diff::Real, best::Particle)
	new_particle = Particle([], Inf) # New particle with infinity cost
	for i = 1:sp.max_diffusion
		σ = (pos_diff+1e-8)/(abs(value_diff)+1e-8) * (sqrt(sum((p.x - best.x).^2))+1e-8)
		μ = p.x
		x = check_bounds(rand.(Normal.(μ, σ)), s.lbound, s.ubound)
		f = s.f(x)
		if f <= new_particle.f
			new_particle.x = x
			new_particle.f = f
		end
	end
	new_particle
end

function exploration_diffusion(sp::SearchParams, s::SearchSpace)
	points = [s.lbound + rand(s.dim).*(s.ubound - s.lbound) for i=1:sp.max_diffusion]
	particles = [Particle(p, s.f(p)) for p in points]
	minimum(particles)
end

end
