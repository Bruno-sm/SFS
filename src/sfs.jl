using DocOpt
using MicroLogging

include("original.jl")
import Original

include("simplified.jl")
import Simplified 



doc = """Stochastic Fractal Search.

Usage:
	sfs.jl original [--csv-output] [--debug-output] [-r | --repetitions=<r>] [-s | --seed=<seed>] [-n | --dimension=<dim>] [-w | --walk=<w>] [-p | --population=<p>] [-d | --diffusion=<dif>] [<function>... | --all]
	sfs.jl simplified [--csv-output] [--debug-output] [-r | --repetitions=<r>] [-s | --seed=<seed>] [-n | --dimension=<dim>] [-w | --walk=<w>] [-p | --population=<p>] [-d | --diffusion=<dif>] [<function>... | --all]
	sfs.jl -h | --help
	sfs.jl --version

Options:
	-h --help   Show this screen.
	--version   Show version.
	--debug-output   Show debug messages.
	-s --seed=<seed>   Random number generation seed.
	-r --repetitions=<r>   Algorithm repetitions.
	-n --dimension=<dim>   Dimension of the search space.
	-w --walk=<w>	Probability (between 0 and 1) to choose walk 1 or walk 2.
	-p --population=<p>   Population in each generation.
	-d --diffusion=<dif>   Number of diffusions in the diffusion process.
	--all   Executes the algorithm over the cec14 functions from 1 to 20.
"""


function main()
	args = docopt(doc, version=v"0.0.1")

	if length(args["--seed"]) != 0
		println("Seed: $(args["--seed"][1])")
		srand(parse(Int, args["--seed"][1]))
	end

	if length(args["--dimension"]) == 0
		push!(args["--dimension"], "30")
	end

	r = 1 
	if length(args["--repetitions"]) != 0
		r = parse(Int, args["--repetitions"][1])
	end

	if args["original"]
		algorithm = Original.main
	elseif args["simplified"]
		algorithm = Simplified.main
	end

	algorithm(args, 1) #In order to not count the precompilation time

	if args["--debug-output"]
		configure_logging(min_level=:debug)
	end

	if args["--csv-output"]
		println("function,value,error,time")
	end

	if args["--all"]
		args["<function>"] = [string(i) for i in 1:20]
	end

	for fn in args["<function>"] 
		val = 0
		error = 0
		time = 0
		for i = 1:r
			v, err, t = algorithm(args, parse(Int, fn))
			val += v
			error += err
			time += t
		end
		val /= r
		error /= r
		time /= r

		if args["--csv-output"]
			println("$fn,$val,$error,$time")
		else
			println("\nFunction: $fn")
			println("Repetitions: $r")
			println("Value: $val")
			println("Error: $error")
			println("Time: $time")
		end
	end
end

main()
