module Simplified 

using Distributions
using MicroLogging

include("cec14_func.jl")

export main



type SearchParams
	initial_population::Unsigned
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
	population = 100
	if length(args["--population"]) != 0
		population = parse(Int, args["--population"][1])
	end
	diffusion = 1
	if length(args["--diffusion"]) != 0
		diffusion = parse(Int, args["--diffusion"][1])
	end
	search_params = SearchParams(population, 10000*dim, diffusion, 1e-8)
	search_space = cec14_func(func_number, dim)
	tic()
	opt = stochastic_fractal_search(search_params, search_space)
	opt.f, opt.f - search_space.opt, toq() 
end


function stochastic_fractal_search(sp::SearchParams, s::SearchSpace)
	evaluations = 0
	# Initial population of particles 
	points = [s.lbound + rand(s.dim).*(s.ubound - s.lbound) for i=1:sp.initial_population]
	particles = [Particle(p, s.f(p)) for p in points]
    
	# Best particle of the initial population 
	best = minimum(particles)
    
	g = 0
	while evaluations < sp.max_evaluations && best.f - s.opt > sp.error_threshold 
		g += 1
		particles = diffusion.(particles, sp, s, g, best)
		evaluations += length(particles)*sp.max_diffusion
		new_best = minimum(particles)
		if (new_best.f < best.f)
			best = copy(new_best)
		end
        
		@debug "Iteration $g"
		@debug "$evaluations evaluations"
		@debug "$(best.x)"
		@debug "$(best.f)"
	end
	best
end


function diffusion(p::Particle, sp::SearchParams, s::SearchSpace, g::Int64, best::Particle)
	new_particle = Particle([], Inf) # New particle with infinity cost
	for i = 1:sp.max_diffusion
		σ = (log(g)/g) * (abs.(p.x - best.x))
		for i = 1:length(σ)
			if σ[i] <= 0 # σ can't be 0
				σ[i] = 0.001
			end
		end
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


function check_bounds(x, lbound, ubound)
	new_x = copy(x)
	upper = find(x .> ubound) 
	lower = find(x .< lbound)

	for i in upper
		new_x[i] = ubound[i] - lbound[i]*rand() + lbound[i]
	end
	for i in lower
		new_x[i] = ubound[i] - lbound[i]*rand() + lbound[i]
	end
	
	new_x
end

end
