__constant sampler_t sampler = CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_NONE | CLK_FILTER_NEAREST;

__kernel void chopRowF(__global long unsigned int* startEnd, read_only image2d_t in, write_only image2d_t out) {
    int row = get_global_id(0);
    int col = get_global_id(1);

    unsigned int diff = startEnd[1] - startEnd[0];
    
    if (row < startEnd[0]) {
        float4 vfour = read_imagef(in, sampler, (int2)(col, row));
        float pix = vfour[0];
        write_imagef(out, (int2)(col, row), (float4)(pix, 0 ,0 ,0));
    }
    else { //(row >= startEnd[0])
        float4 vfour = read_imagef(in, sampler, (int2)(col, row+diff));
        float pix = vfour[0];
        write_imagef(out, (int2)(col, row), (float4)(pix, 0 ,0 ,0));
    }

}

