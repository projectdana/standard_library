__constant sampler_t sampler = CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_NONE | CLK_FILTER_NEAREST;

__kernel void chopColumnI(__global long unsigned int* startEnd, read_only image2d_t in, write_only image2d_t out) {
    int row = get_global_id(0);
    int col = get_global_id(1);

    unsigned int diff = startEnd[1] - startEnd[0];
    
    if (col < startEnd[0]) {
        uint4 vfour = read_imageui(in, sampler, (int2)(col, row));
        uint pix = vfour[0];
        write_imageui(out, (int2)(col, row), (uint4)(pix, 0 ,0 ,0));
    }
    else { //(col >= startEnd[0])
        uint4 vfour = read_imageui(in, sampler, (int2)(col+diff, row));
        uint pix = vfour[0];
        write_imageui(out, (int2)(col, row), (uint4)(pix, 0 ,0 ,0));
    }

}
