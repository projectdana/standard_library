
__kernel void randMat(__global unsigned int* seed, write_only image2d_t matrix) {
    int globalID_x = get_global_id(0);
    int globalID_y = get_global_id(1);

    float seeded = (float) 10.0;

    write_imagef(matrix, (int2)(globalID_x, globalID_y), (float4)(seeded, 0 ,0 ,0));
}
