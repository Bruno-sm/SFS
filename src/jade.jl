using Distributions


function jade(points::Array, values::Array, A::Array, s::SearchSpace, μCR::Real, μF::Real, p::Real, c::Real)
	SF = []
	SCR = []
	CR = ones(length(points))
	F = ones(length(points))
	v = [ones(s.dim) for i in 1:length(points)]
	u = [ones(s.dim) for i in 1:length(points)]
	points = [x[1] for x in sort(collect(zip(points, values)), by = x -> x[2])]
	for i = 1:length(points)
		CR[i] = max(min(rand(Normal(μCR, 0.1)), 1), 0)
		F[i] = min(rand(Cauchy(μF, 0.1)), 1)
		while F[i] <= 0
			F[i] = min(rand(Cauchy(μF, 0.1)), 1)
		end
		b = points[rand(1:ceil(Int, length(points)*p))]
		r1 = rand(1:length(points))
		while r1 == i
			r1 = rand(1:length(points))
		end
		pointsUA = union(points, A)
		r2 = rand(1:length(pointsUA)) 
		while r2 == r1 || r2 == i
			r2 = rand(1:length(pointsUA)) 
		end
        v[i] = points[i] + F[i]*(b - points[i]) + F[i]*(points[r1] - pointsUA[r2])

		jrand = rand(1:s.dim)
		for j = 1:s.dim
			if j == jrand || rand() < CR[i]
				u[i][j] = v[i][j]
			else
				u[i][j] = copy(points[i][j]) 
			end
		end
		check_bounds(u[i], s.lbound, s.ubound)

		fu = s.f(u[i])
		if fu < values[i]
			push!(A, points[i])
			points[i] = copy(u[i]) 
			values[i] = fu
			push!(SCR, CR[i])
			push!(SF, F[i])
		end
	end
	while length(A) > length(points)
		deleteat!(A, rand(1:length(A)))
	end
	if length(SCR) > 0
		μCR = (1 - c) * μCR + c * mean(SCR)
	end
	if length(SF) > 0
		μF = (1 - c) * μF + c * sum(SF.^2)/sum(SF)
	end

	points, values, A, μCR, μF
end


function jade_test()
	s = cec14_func(1, 2)
	x = [s.lbound + rand(s.dim).*(s.ubound - s.lbound) for i=1:100]
	v = [s.f(p) for p in x]
	A = []
	μCR = 0.5
	μF = 0.5
	p = 0.05
	c = 0.1
	for g = 1:30
		x, v, A, μCR, μF = jade(x, v, A, s, μCR, μF, p, c)
		println("Generation $g")
		println("	$(x[1]): $(v[1])")
	end
end
