#include <stdio.h>
#include <cuda_runtime_api.h>
#include <cupti_events.h>
#include "simple.c"

#include <unistd.h>
#include <pthread.h>

#define CHECK_CU_ERROR(err, cufunc)                                     \
if (err != CUDA_SUCCESS)                                              \
 {                                                                   \
   printf ("Error %d for CUDA Driver API function '%s'.\n",          \
           err, cufunc);                                             \
   exit(-1);                                                         \
 }

#define CHECK_CUPTI_ERROR(err, cuptifunc)                       \
if (err != CUPTI_SUCCESS)                                     \
 {                                                           \
   const char *errstr;                                       \
   cuptiGetResultString(err, &errstr);                       \
   printf ("%s:%d:Error %s for CUPTI API function '%s'.\n",  \
           __FILE__, __LINE__, errstr, cuptifunc);           \
   exit(-1);                                                 \
 }

#define EVENT_NAME "inst_executed"

static volatile int testComplete = 0;

static CUcontext context;
static CUdevice device;
static const char *eventName;

void *
sampling_func(void *arg)
{
CUptiResult cuptiErr;
CUpti_EventGroup eventGroup;
CUpti_EventID eventId;
size_t bytesRead, valueSize;
uint32_t numInstances = 0, j = 0;
uint64_t *eventValues = NULL, eventVal = 0;
uint32_t profile_all = 1;

cuptiErr = cuptiSetEventCollectionMode(context,
                                      CUPTI_EVENT_COLLECTION_MODE_CONTINUOUS);
CHECK_CUPTI_ERROR(cuptiErr, "cuptiSetEventCollectionMode");

cuptiErr = cuptiEventGroupCreate(context, &eventGroup, 0);
CHECK_CUPTI_ERROR(cuptiErr, "cuptiEventGroupCreate");

cuptiErr = cuptiEventGetIdFromName(device, eventName, &eventId);
CHECK_CUPTI_ERROR(cuptiErr, "cuptiEventGetIdFromName");

cuptiErr = cuptiEventGroupAddEvent(eventGroup, eventId);
CHECK_CUPTI_ERROR(cuptiErr, "cuptiEventGroupAddEvent");

cuptiErr = cuptiEventGroupSetAttribute(eventGroup,
                                      CUPTI_EVENT_GROUP_ATTR_PROFILE_ALL_DOMAIN_INSTANCES,
                                      sizeof(profile_all), &profile_all);
CHECK_CUPTI_ERROR(cuptiErr, "cuptiEventGroupSetAttribute");

cuptiErr = cuptiEventGroupEnable(eventGroup);
CHECK_CUPTI_ERROR(cuptiErr, "cuptiEventGroupEnable");

valueSize = sizeof(numInstances);
cuptiErr = cuptiEventGroupGetAttribute(eventGroup,
                                      CUPTI_EVENT_GROUP_ATTR_INSTANCE_COUNT,
                                      &valueSize, &numInstances);
CHECK_CUPTI_ERROR(cuptiErr, "cuptiEventGroupGetAttribute");

bytesRead = sizeof(uint64_t) * numInstances;
eventValues = (uint64_t *) malloc(bytesRead);
if (eventValues == NULL) {
   printf("%s:%d: Failed to allocate memory.\n", __FILE__, __LINE__);
   exit(-1);
}

while (!testComplete) {
 cuptiErr = cuptiEventGroupReadEvent(eventGroup,
                                     CUPTI_EVENT_READ_FLAG_NONE,
                                     eventId, &bytesRead, eventValues);
 CHECK_CUPTI_ERROR(cuptiErr, "cuptiEventGroupReadEvent");
 if (bytesRead != (sizeof(uint64_t) * numInstances)) {
   printf("Failed to read value for \"%s\"\n", eventName);
   exit(-1);
 }

 for (j = 0; j < numInstances; j++) {
   eventVal += eventValues[j];
 }
 printf("%s: %llu\n", eventName, (unsigned long long)eventVal);
//  usleep(10);
}

cuptiErr = cuptiEventGroupDisable(eventGroup);
CHECK_CUPTI_ERROR(cuptiErr, "cuptiEventGroupDisable");

cuptiErr = cuptiEventGroupDestroy(eventGroup);
CHECK_CUPTI_ERROR(cuptiErr, "cuptiEventGroupDestroy");

free(eventValues);
return NULL;
}

int
main(int argc, char *argv[])
{
int status;
pthread_t pThread;
CUresult err;
int deviceNum;
int deviceCount;
char deviceName[32];

printf("Usage: %s [device_num] [event_name]\n", argv[0]);

err = cuInit(0);
CHECK_CU_ERROR(err, "cuInit");

err = cuDeviceGetCount(&deviceCount);
CHECK_CU_ERROR(err, "cuDeviceGetCount");

if (deviceCount == 0) {
 printf("There is no device supporting CUDA.\n");
 exit(-1);
}

if (argc > 1)
 deviceNum = atoi(argv[1]);
else
 deviceNum = 0;
printf("CUDA Device Number: %d\n", deviceNum);

err = cuDeviceGet(&device, deviceNum);
CHECK_CU_ERROR(err, "cuDeviceGet");

err = cuDeviceGetName(deviceName, 32, device);
CHECK_CU_ERROR(err, "cuDeviceGetName");

printf("CUDA Device Name: %s\n", deviceName);

if (argc > 2) {
 eventName = argv[2];
}
else {
 eventName = EVENT_NAME;
}

err = cuCtxCreate(&context, 0, device);
CHECK_CU_ERROR(err, "cuCtxCreate");


testComplete = 0;

// printf("Creating sampling thread\n");

status = pthread_create(&pThread, NULL, sampling_func, NULL);
if (status != 0) {
 perror("pthread_create");
 exit(-1);
}

func(5000);
// usleep(500000);
testComplete = 1;
pthread_join(pThread, NULL);

cudaDeviceSynchronize();
return 0;
}
