using DocOpt
using MicroLogging

include("original.jl")
import Original


doc = """Stochastic Fractal Search.

Usage:
	sfs.jl original [--debug-output] [-r | --repetitions=<r>] [-s | --seed=<seed>] [<function>...]
	sfs.jl -h | --help
	sfs.jl --version

Options:
	-h --help   Show this screen.
	--version   Show version.
	--debug-output   Show debug messages.
	-s --seed=<seed>   Random number generation seed.
	-r --repetitions=<r>   Algorithm repetitions.
"""


function main()
	args = docopt(doc, version=v"0.0.1")

	if length(args["--seed"]) != 0
		println("Seed: $(args["--seed"][1])")
		srand(parse(Int, args["--seed"][1]))
	end

	if args["original"]
		algorithm = Original.main
	end

	r = 1 
	if length(args["--repetitions"]) != 0
		r = parse(Int, args["--repetitions"][1])
	end

	algorithm(args) #In order to not count the precompilation time

	if args["--debug-output"]
		configure_logging(min_level=:debug)
	end

	val = 0
	time = 0
	for i = 1:r
		v, t = algorithm(args)
		val += v
		time += t
	end
	val /= r
	time /= r

	println("Repetitions: $r")
	println("Value: $val")
	println("Time: $time")
end

main()
