__kernel void randVect(__global unsigned int *seed, __global double *vect) {
    int globalID = get_global_id(0);
    int seeded = seed[0] + globalID;
    seeded = (seeded * 0x5DEECE66DL + 0xBL) & ((1L << 48) -1);
    vect[globalID] = seeded >> 16;
}
