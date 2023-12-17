__constant sampler_t sampler = CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_NONE | CLK_FILTER_NEAREST;

__kernel void matmupd( read_only image2d_t A, read_only image2d_t B, write_only image2d_t C ) {
    int x = get_global_id(0);
    int y = get_global_id(1);

    //C[x, y] = dot product of A[x, :] and B[:, y]
    float dot = 0.0;
    for (int i = 0; i < get_image_height(B); i++) {
        float a_val = read_imagef(A, sampler, (int2)(i,x))[0];
        float b_val = read_imagef(B, sampler, (int2)(y,i))[0];
        dot += a_val * b_val;
    }
    write_imagef(C, (int2)(y, x), (float4)(dot, 0, 0, 0));
}
