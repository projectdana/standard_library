__kernel void vscalei( __global const long unsigned int* scalar, __global long unsigned int *A ) {
    int i = get_global_id(0);
    A[i] = scalar[0] * A[i];
}
