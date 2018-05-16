module Original

using Distributions
using MicroLogging

include("cec14_func.jl")

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
	p = SearchParams(100, 10000*dim, 10, 0, 1e-8)
	search_space = cec14_func(func_number, dim)
	tic()
	opt = stochastic_fractal_search(p, search_space)
	opt.f, toq() 
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
		particles = sort(diffusion.(particles, sp, s, g, best))
		evaluations += sp.max_diffusion
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


function diffusion(p::Particle, sp::SearchParams, s::SearchSpace, g::Int64, best::Particle)
	new_particle = Particle([], Inf) # New particle with infinity cost
	for i = 1:sp.max_diffusion
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
