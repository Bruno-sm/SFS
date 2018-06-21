module JadeProgressiveDiffusion

using Distributions
using MicroLogging

include("cec14_func.jl")
include("check_bounds.jl")
include("jade.jl")

export main



type SearchParams
	initial_population::Unsigned
	max_evaluations::Unsigned
	max_diffusion::Unsigned
	walk_prob::Real
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
	max_diffusion = 5 
	if length(args["--diffusion"]) != 0
		max_diffusion = parse(Int, args["--diffusion"][1])
	end
	walk = 0
	if length(args["--walk"]) != 0
		walk = parse(Int, args["--walk"][1])
	end
	search_params = SearchParams(population, 10000*dim, max_diffusion, walk, 1e-8)
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

	# Jade parameters
	A = []
	μCR = 0.5
	μF = 0.5
	p = 0.05
	c = 0.1

	g = 0
	while evaluations < sp.max_evaluations && best.f - s.opt > sp.error_threshold 
		g += 1
		# diffusion process 
		diffusion_number = round(Int, sp.max_diffusion - (sp.max_diffusion/sp.max_evaluations * evaluations))
		@debug "Diffusion $diffusion_number"
		if diffusion_number != 0
			particles = sort(diffusion.(particles, sp, s, diffusion_number, g, best))
			evaluations += length(particles)*diffusion_number
		end
        
		# update process
		x, v, A, μCR, μF = jade([p.x for p in particles], [p.f for p in particles],
								A, s, μCR, μF, p, c)
		evaluations += length(particles)
		particles = [Particle(p[1], p[2]) for p in zip(x, v)]
        
		if (particles[1].f < best.f)
			best = copy(particles[1])
		end
        
		@debug "Iteration $g"
		@debug "$evaluations evaluations"
		@debug "$(best.x)"
		@debug "$(best.f)"
	end
	best
end


function diffusion(p::Particle, sp::SearchParams, s::SearchSpace, g::Int64, diffusion, best::Particle)
	new_particle = Particle([], Inf) # New particle with infinity cost
	for i = 1:diffusion
		σ = (log(g)/g) * (abs.(p.x - best.x))
		for i = 1:length(σ)
			if σ[i] <= 0 # σ can't be 0
				σ[i] = 0.001
			end
		end
		if rand() < sp.walk_prob # First random walk
			μ = best.x
			x = rand.(Normal.(μ, σ)) + (randn()*best.x - randn()*p.x)
		else # Second random walk
			μ = p.x
			x = rand.(Normal.(μ, σ))
		end
		x = check_bounds(x, s.lbound, s.ubound) # x must be inside the bounds
		f = s.f(x)
		if f <= new_particle.f
			new_particle.x = x
			new_particle.f = f
		end
	end
	if new_particle.f < p.f
		@debug "MEJORA :)"
	else
		@debug "EMPEORA :("
	end
	new_particle
end

end
