__constant sampler_t sampler = CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_NONE | CLK_FILTER_NEAREST;

__kernel void lintransd( read_only image2d_t T, __global const float* V, __global float* Vt ) {
    int i = get_global_id(0);
    float sum = 0.0;
    for (int k = 0; k < get_image_width(T); k++) {
        float mul = read_imagef(T, sampler, (int2)(k, i))[0];
        sum += V[k] * mul;
    }
    Vt[i] = sum;
}
