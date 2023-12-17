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

__kernel void randvecd(__global long unsigned int* seed_in, __global float* lohi, __global float* v) {
    int row = get_global_id(0);

    uint seed = (seed_in[0] + (row*row))*(seed_in[0] + row);

    float diff = lohi[1] - lohi[0];
    uint discreteStepsMax = getInt(10001, seed);
    uint discreteStepsTaken = getInt(discreteStepsMax+1, seed);

    float increments = diff / discreteStepsMax;
    float add = increments * discreteStepsTaken;

    float rnd = lohi[0] + add;

    v[row] = rnd;
}
