__kernel void vscaled( __global const float* scalar, __global float* A ) {
    int i = get_global_id(0);
    A[i] = scalar[0] * A[i];
}

