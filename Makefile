LIB=libs
SRC=src
RES=results


$(LIB)/libcec14_func.so: $(SRC)/cec14_func.c
	mkdir -p $(LIB)
	c99 -g -shared -fPIC -Wl,-soname,cec14_func.so -o $@ $^ -lc

results: $(RES)/original_p100_d1_w0.csv $(RES)/original_p100_d1_w1.csv $(RES)/original_p100_d5_w0.csv $(RES)/original_p500_d2_w0.csv

$(RES)/original_p100_d1_w0.csv:
	mkdir -p $(RES)
	julia $(SRC)/sfs.jl original --csv-output -n 30 -p 100 -d 1 -w 0 --all > $@

$(RES)/original_p100_d1_w1.csv:
	mkdir -p $(RES)
	julia $(SRC)/sfs.jl original --csv-output -n 30 -p 100 -d 1 -w 1 --all > $@

$(RES)/original_p100_d5_w0.csv:
	mkdir -p $(RES)
	julia $(SRC)/sfs.jl original --csv-output -n 30 -p 100 -d 5 -w 0 --all > $@

$(RES)/original_p500_d2_w0.csv:
	mkdir -p $(RES)
	julia $(SRC)/sfs.jl original --csv-output -n 30 -p 500 -d 2 -w 0 --all > $@
