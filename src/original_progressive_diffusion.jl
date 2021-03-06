module OriginalProgressiveDiffusion

using Distributions
using MicroLogging

include("cec14_func.jl")
include("check_bounds.jl")

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
	diffusion = 5
	if length(args["--diffusion"]) != 0
		diffusion = parse(Int, args["--diffusion"][1])
	end
	walk = 0
	if length(args["--walk"]) != 0
		walk = parse(Int, args["--walk"][1])
	end
	search_params = SearchParams(population, 10000*dim, diffusion, walk, 1e-8)
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
		# diffusion process 
	    diffusion_number = round(Int, sp.max_diffusion/sp.max_evaluations * evaluations)
#		diffusion_number = round(Int, sp.max_diffusion - (sp.max_diffusion/sp.max_evaluations * evaluations))
		if diffusion_number != 0
			particles = sort(diffusion.(particles, sp, s, diffusion_number, g, best))
			evaluations += length(particles)*diffusion_number
		end
		new_best = particles[1]
        
		# First update process 
		size = length(particles)
		Pa = [(size - i + 1) / size for i=1:size] 
		randvec1 = randperm(size)
		randvec2 = randperm(size)
		for i = 1:size
			p = copy(particles[i])
			for j = 1:s.dim
				if rand() > Pa[i]
					p.x[j] = particles[randvec1[i]].x[j] -
					                   rand()*(particles[randvec2[i]].x[j] - p.x[j])
				end
			end
			p.x = check_bounds(p.x, s.lbound, s.ubound)
			p.f = s.f(p.x)
			evaluations += 1
			if p.f <= particles[i].f
				particles[i] = p
			end
		end
        
		particles = sort(particles)
		new_best = particles[1]
		if (new_best.f < best.f)
			best = copy(new_best)
		end
        
		# Second update process 
		for i = 1:size
			if rand() > Pa[i]
				t = ceil(Int, rand()*size)
				r = ceil(Int, rand()*size)
				while t == r
					r = ceil(Int, rand()*size)
				end
                
				p = copy(particles[i])
				if rand() < 0.5
					p.x = check_bounds(p.x - rand() * (particles[t].x - best.x),
									   s.lbound, s.ubound)
					p.f = s.f(p.x)
				else
					p.x = check_bounds(p.x + rand() * (particles[t].x - particles[r].x),
									   s.lbound, s.ubound)
					p.f = s.f(p.x)
				end
				evaluations += 1
                
				if p.f < particles[i].f
					particles[i] = p
				end
			end
		end
        
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


function diffusion(p::Particle, sp::SearchParams, s::SearchSpace, diffusion, g::Int64, best::Particle)
	new_particle = Particle([], Inf) # New particle with infinity cost
	@debug "Diffusion $diffusion"
	if diffusion == 0
		new_particle = copy(p)
	end
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
