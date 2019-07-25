#include "stdio.h"
__global__ void add(int a, int b, int *c)
{
 
 *c = a + b;
}
static void func(int iter)
{
int a,b,c;
int *dev_c;
a=3;
b=4;
cudaMalloc((void**)&dev_c, sizeof(int));
for(int i = 0; i < iter; i++)
    add<<<1,1>>>(a,b,dev_c);
cudaMemcpy(&c, dev_c, sizeof(int), cudaMemcpyDeviceToHost);
printf("%d + %d is %d\n", a, b, c);
cudaFree(dev_c);
} 