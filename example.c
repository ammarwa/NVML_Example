#include <stdio.h>
#include <nvml.h>

const char * convertToComputeModeString(nvmlComputeMode_t mode)
{
    switch (mode)
    {
        case NVML_COMPUTEMODE_DEFAULT:
            return "Default";
        case NVML_COMPUTEMODE_EXCLUSIVE_THREAD:
            return "Exclusive_Thread";
        case NVML_COMPUTEMODE_PROHIBITED:
            return "Prohibited";
        case NVML_COMPUTEMODE_EXCLUSIVE_PROCESS:
            return "Exclusive Process";
        default:
            return "Unknown";
    }
}

int main()
{
    nvmlReturn_t result;
    unsigned int device_count, i;

    // First initialize NVML library
    result = nvmlInit();
    if (NVML_SUCCESS != result)
    { 
        printf("Failed to initialize NVML: %s\n", nvmlErrorString(result));

        printf("Press ENTER to continue...\n");
        getchar();
        return 1;
    }

    result = nvmlDeviceGetCount(&device_count);
    if (NVML_SUCCESS != result)
    { 
        printf("Failed to query device count: %s\n", nvmlErrorString(result));
        goto Error;
    }
    printf("Found %d device%s\n\n", device_count, device_count != 1 ? "s" : "");

    printf("Listing devices:\n");    
    for (i = 0; i < device_count; i++)
    {
        nvmlDevice_t device;
        char name[NVML_DEVICE_NAME_BUFFER_SIZE];
        nvmlPciInfo_t pci;
        nvmlComputeMode_t compute_mode;
	unsigned int clock;
	unsigned int temp;
	unsigned int power;

        // Query for device handle to perform operations on a device
        // You can also query device handle by other features like:
        // nvmlDeviceGetHandleBySerial
        // nvmlDeviceGetHandleByPciBusId
        result = nvmlDeviceGetHandleByIndex(i, &device);
        if (NVML_SUCCESS != result)
        { 
            printf("Failed to get handle for device %i: %s\n", i, nvmlErrorString(result));
            goto Error;
        }

        result = nvmlDeviceGetName(device, name, NVML_DEVICE_NAME_BUFFER_SIZE);
        if (NVML_SUCCESS != result)
        { 
            printf("Failed to get name of device %i: %s\n", i, nvmlErrorString(result));
            goto Error;
        }
        
        // pci.busId is very useful to know which device physically you're talking to
        // Using PCI identifier you can also match nvmlDevice handle to CUDA device.
        result = nvmlDeviceGetPciInfo(device, &pci);
        if (NVML_SUCCESS != result)
        { 
            printf("Failed to get pci info for device %i: %s\n", i, nvmlErrorString(result));
            goto Error;
        }

	result = nvmlDeviceGetTemperature(device, 0, &temp);
	if (NVML_SUCCESS != result)
        { 
            printf("Failed to get clock info for device %i: %s\n", i, nvmlErrorString(result));
            goto Error;
        }

	result = nvmlDeviceGetClockInfo(device, 0, &clock);
	if (NVML_SUCCESS != result)
        { 
            printf("Failed to get clock info for device %i: %s\n", i, nvmlErrorString(result));
            goto Error;
        }
	
	result = nvmlDeviceGetPowerUsage(device, &power);
	if (NVML_SUCCESS != result)
        { 
            //printf("Failed to get clock info for device %i: %s\n", i, nvmlErrorString(result));
            //goto Error;
	    power = 0;
        }
	if(power == 0){
        	printf("%d. %s [%s] :_\n Temp --> %d\n Clock --> %d\n Power --> Not Supported\n\n", i, name, pci.busId, temp, clock);
	} else {
		printf("%d. %s [%s] :_\n Temp --> %d\n Clock --> %d\n Power --> %d\n\n", i, name, pci.busId, temp, clock, power);
	}
    }

    result = nvmlShutdown();
    if (NVML_SUCCESS != result)
        printf("Failed to shutdown NVML: %s\n", nvmlErrorString(result));

    printf("All done.\n");

    printf("Press ENTER to continue...\n");
    getchar();
    return 0;

Error:
    result = nvmlShutdown();
    if (NVML_SUCCESS != result)
        printf("Failed to shutdown NVML: %s\n", nvmlErrorString(result));

    printf("Press ENTER to continue...\n");
    getchar();
    return 1;
}
