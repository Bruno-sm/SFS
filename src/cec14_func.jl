type SearchSpace
	dim::Int
	lbound::Array{Real, 1}
	ubound::Array{Real, 1}
	f::Function
	opt::Real
end


function cec14_func_eval(func_number::Int, x::Array, dimension::Int)
	res = [0.0]
	ccall((:cec14_test_func, "libs/libcec14_func"), Void,
		  (Ptr{Cdouble}, Ptr{Cdouble}, Cint, Cint, Cint),
		  x, res, dimension, 1, func_number)
	res[1]
end


function cec14_func(func_number::Int, dimension::Int)
	f = x -> cec14_func_eval(func_number, x, dimension)
	SearchSpace(dimension, ones(dimension)*-100, ones(dimension)*100, f, 100*func_number)
end
