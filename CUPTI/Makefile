#
# Copyright 2011-2018 NVIDIA Corporation. All rights reserved
# 
INCLUDES=-I/software/cuda-10.1/extras/CUPTI/include
LIB_PATH ?= /software/cuda-10.1/extras/CUPTI/lib64
export LD_LIBRARY_PATH := $(LD_LIBRARY_PATH):$(LIB_PATH)
LIBS= -lcuda -L $(LIB_PATH) -lcupti

event_sampling: event_sampling.o
	nvcc -o $@ event_sampling.o $(LIBS)

event_sampling.o: event_sampling.cu
	nvcc -c $(INCLUDES) $<

run: event_sampling
	./$<

clean:
	rm -f event_sampling event_sampling.o
