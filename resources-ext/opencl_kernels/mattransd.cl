__constant sampler_t sampler = CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_NONE | CLK_FILTER_NEAREST;

__kernel void mattransd( read_only image2d_t M, write_only image2d_t Mt ) {
    int x = get_global_id(0);
    int y = get_global_id(1);
    float val = read_imagef(M, sampler, (int2)(x, y))[0];
    write_imagef(Mt, (int2)(y, x), (float4)(val, 0, 0, 0));
}
