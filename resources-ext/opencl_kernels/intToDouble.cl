__constant sampler_t sampler = CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_NONE | CLK_FILTER_NEAREST;

__kernel void intToDouble(read_only image2d_t inputMatrix, write_only image2d_t outputMatrix) {
    int gidx = get_global_id(0);
    int gidy = get_global_id(1);

    int4 fromInput = read_imagei(inputMatrix, sampler, (int2)(gidy, gidx));
    int ourNumber = fromInput[0];
    float conversion = (float) ourNumber;
    
    write_imagef(outputMatrix, (int2)(gidy, gidx), (float4)(conversion, 0 ,0 ,0));
}
