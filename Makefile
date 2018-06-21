LIB=libs
SRC=src
RES=results
SEED=300


$(LIB)/libcec14_func.so: $(SRC)/cec14_func.c
	mkdir -p $(LIB)
	c99 -g -shared -fPIC -Wl,-soname,cec14_func.so -o $@ $^ -lc


results: original original_without_ls two_branches original_progressive_diffusion original_adaptive original_adaptive_without_ls original_with_jade original_with_jade_without_ls

original: $(SRC)/original.jl
	mkdir -p $(RES)
	julia $(SRC)/sfs.jl original --csv-output -s $(SEED) -r 25 -n 10 -p 60 -d 2 -w 0 --all > $(RES)/$@_10.csv
	julia $(SRC)/sfs.jl original --csv-output -s $(SEED) -r 25 -n 30 -p 60 -d 2 -w 0 --all > $(RES)/$@_30.csv

original_without_ls: $(SRC)/original.jl
	mkdir -p $(RES)
	julia $(SRC)/sfs.jl original --csv-output -s $(SEED) -r 25 -n 10 -p 60 -d 0 -w 0 --all > $(RES)/$@_10.csv
	julia $(SRC)/sfs.jl original --csv-output -s $(SEED) -r 25 -n 30 -p 60 -d 0 -w 0 --all > $(RES)/$@_30.csv

two_branches: $(SRC)/two_branches.jl
	mkdir -p $(RES)
	julia $(SRC)/sfs.jl two_branches --csv-output -s $(SEED) -r 25 -n 10 -p 100 -d 3 --all > $(RES)/$@_10.csv
	julia $(SRC)/sfs.jl two_branches --csv-output -s $(SEED) -r 25 -n 30 -p 100 -d 3 --all > $(RES)/$@_30.csv

original_with_jade: $(SRC)/original_with_jade.jl
	mkdir -p $(RES)
	julia $(SRC)/sfs.jl original_with_jade --csv-output -s $(SEED) -r 25 -n 10 -p 100 -d 2 -w 0 --all > $(RES)/$@_10.csv
	julia $(SRC)/sfs.jl original_with_jade --csv-output -s $(SEED) -r 25 -n 30 -p 100 -d 2 -w 0 --all > $(RES)/$@_30.csv

original_with_jade_without_ls: $(SRC)/original_with_jade.jl
	mkdir -p $(RES)
	julia $(SRC)/sfs.jl original_with_jade --csv-output -s $(SEED) -r 25 -n 10 -p 60 -d 0 -w 0 --all > $(RES)/$@_10.csv
	julia $(SRC)/sfs.jl original_with_jade --csv-output -s $(SEED) -r 25 -n 30 -p 60 -d 0 -w 0 --all > $(RES)/$@_30.csv

original_progressive_diffusion: $(SRC)/original_progressive_diffusion.jl
	mkdir -p $(RES)
	julia $(SRC)/sfs.jl original_progressive_diffusion --csv-output -s $(SEED) -r 25 -n 10 -p 60 -d 2 -w 0 --all > $(RES)/$@_10.csv
	julia $(SRC)/sfs.jl original_progressive_diffusion --csv-output -s $(SEED) -r 25 -n 30 -p 60 -d 2 -w 0 --all > $(RES)/$@_30.csv

original_adaptive: $(SRC)/original_adaptive.jl
	mkdir -p $(RES)
	julia $(SRC)/sfs.jl original_adaptive --csv-output -s $(SEED) -r 25 -n 10 -p 60 -d 3 -w 0 --all > $(RES)/$@_10.csv
	julia $(SRC)/sfs.jl original_adaptive --csv-output -s $(SEED) -r 25 -n 30 -p 60 -d 3 -w 0 --all > $(RES)/$@_30.csv

original_adaptive_without_ls: $(SRC)/original_adaptive.jl
	mkdir -p $(RES)
	julia $(SRC)/sfs.jl original_adaptive --csv-output -s $(SEED) -r 25 -n 10 -p 60 -d 0 -w 0 --all > $(RES)/$@_10.csv
	julia $(SRC)/sfs.jl original_adaptive --csv-output -s $(SEED) -r 25 -n 30 -p 60 -d 0 -w 0 --all > $(RES)/$@_30.csv


