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

