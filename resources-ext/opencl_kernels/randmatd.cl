uint getInt(uint top, uint seed) {
    if (top == 0) {return 0;}
    uint hi;
    uint lo;

    lo = 16807 * (seed * 0xFFFF);
    hi = 16807 * (seed >> 16);

    lo += (hi & 0x7FFF) << 16;
    lo += hi >> 15;

    if (lo > 0x7FFFFFFF) {
        lo -= 0x7FFFFFFF;
    }

    seed = lo;
    
    return seed % top;
}

__kernel void randmatd(__global long unsigned int* seed_in, __global float* lohi, write_only image2d_t matrix) {
    int row = get_global_id(0);
    int col = get_global_id(1);

    uint seed = (seed_in[0] + (row*row) + col)*(seed_in[0] + row + col);

    float diff = lohi[1] - lohi[0];
    uint discreteStepsMax = getInt(10001, seed);
    uint discreteStepsTaken = getInt(discreteStepsMax+1, seed);

    float increments = diff / discreteStepsMax;
    float add = increments * discreteStepsTaken;

    float rnd = lohi[0] + add;

    write_imagef(matrix, (int2)(row, col), (float4)(rnd, 0, 0, 0));
}
