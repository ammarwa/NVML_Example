ARCH       := $(shell getconf LONG_BIT)
OS         := $(shell cat /etc/issue)
RHEL_OS    := $(shell cat /etc/redhat-release)

# Gets Driver Branch
DRIVER_BRANCH := $(shell nvidia-smi | grep Driver | cut -f 3 -d' ' | cut -f 1 -d '.')

# Location of the CUDA Toolkit
CUDA_PATH ?= "/software/cuda-10.1"

ifeq (${ARCH},$(filter ${ARCH},32 64))
    # If correct architecture and libnvidia-ml library is not found 
    # within the environment, build using the stub library
    
    ifneq (,$(findstring Ubuntu,$(OS)))
        DEB := $(shell dpkg -l | grep cuda)
        ifneq (,$(findstring cuda, $(DEB)))
            NVML_LIB := /usr/lib/nvidia-$(DRIVER_BRANCH)
        else 
            NVML_LIB := /lib${ARCH}
        endif
    endif

    ifneq (,$(findstring SUSE,$(OS)))
        RPM := $(shell rpm -qa cuda*)
        ifneq (,$(findstring cuda, $(RPM)))
            NVML_LIB := /usr/lib${ARCH}
        else
            NVML_LIB := /lib${ARCH}
        endif
    endif

    ifneq (,$(findstring CentOS,$(RHEL_OS)))
        RPM := $(shell rpm -qa cuda*)
        ifneq (,$(findstring cuda, $(RPM)))
            NVML_LIB := /usr/lib${ARCH}/nvidia
        else
            NVML_LIB := /lib${ARCH}
        endif
    endif

    ifneq (,$(findstring Red Hat,$(RHEL_OS)))
        RPM := $(shell rpm -qa cuda*)
        ifneq (,$(findstring cuda, $(RPM)))
            NVML_LIB := /usr/lib${ARCH}/nvidia
        else
            NVML_LIB := /lib${ARCH}
        endif
    endif

    ifneq (,$(findstring Fedora,$(RHEL_OS)))
        RPM := $(shell rpm -qa cuda*)
        ifneq (,$(findstring cuda, $(RPM)))
            NVML_LIB := /usr/lib${ARCH}/nvidia
        else
            NVML_LIB := /lib${ARCH}
        endif
    endif

else
    NVML_LIB := ../../lib${ARCH}/stubs/
    $(info "libnvidia-ml.so.1" not found, using stub library.)
endif

ifneq (${ARCH},$(filter ${ARCH},32 64))
	$(error Unknown architecture!)
endif

NVML_LIB += /software/cuda-10.1/lib/
NVML_LIB_L := $(addprefix -L , $(NVML_LIB))

CFLAGS  := -I /software/cuda-10.1/include -I /software/cuda-10.1/include
LDFLAGS := -lnvidia-ml $(NVML_LIB_L)

all: example
example: example.o
	$(CC) $< $(CFLAGS) $(LDFLAGS) -o $@
clean:
	-@rm -f example.o
	-@rm -f example
