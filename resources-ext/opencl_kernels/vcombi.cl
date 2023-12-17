__kernel void vcombi( __global const long unsigned int *A, __global const long unsigned int *B, __global long unsigned int *restrict C ) {
    int i = get_global_id(0);
    C[i] = A[i] * B[i];
}
