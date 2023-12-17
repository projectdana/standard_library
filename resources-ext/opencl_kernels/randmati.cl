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

__kernel void randmati(__global long unsigned int* seed_in, __global long unsigned int* lohi, write_only image2d_t matrix) {
    int row = get_global_id(0);
    int col = get_global_id(1);

    uint seed = (seed_in[0] + (row*row) + col)*(seed_in[0] + row + col);

    uint diff = lohi[1] - lohi[0];

    uint rnd = getInt(diff+1, seed);

    rnd = lohi[0] + rnd;

    write_imageui(matrix, (int2)(row, col), (uint4)(rnd, 0, 0, 0));
}
