bool IsInsideBox(float3 p,float3 box_center,float3 box_size){
    box_size *= 0.5f;
    float3 offset = abs(p-box_center);
    return offset.x < box_size.x && offset.y < box_size.y && offset.z < box_size.z;
}

float WhiteNoise3D(int seed,int i,int j,int k){
    float r = frac(cos(44.54f * k + 232.02f * sin(dot(float2(i,cos(j)),float2(float(seed) + 12.9898,float(seed)+78.233))) * 45.5453));
    return r;
}

float HashVoxel(int seed,int3 voxelIdx){
    float r = WhiteNoise3D(seed,voxelIdx.x,voxelIdx.y,voxelIdx.z);
    r = r*2.0f-1.0f;//[-1,1]
    return r;
}

float3 ComputeGradient(int seed,int3 voxelIdx){
    float3 gradient = float3(
        HashVoxel(seed * 123+345,voxelIdx),
        HashVoxel(seed * 456 + 234,voxelIdx),
        HashVoxel(seed * 789 +123, voxelIdx));
    return normalize(gradient);
}

float SmoothLerp(float min,float max,float t){
    t=t*t*t*(t*(t*6.0f-15.0f) + 10.0f);
    return min + t * (max-min);
}

static const int3 voxelVertexIdx[8] = {
    {0,0,0},
    {0,0,1},
    {0,1,0},
    {0,1,1},
    {1,0,0},
    {1,0,1},
    {1,1,0},
    {1,1,1}
};

float PerlinNoise3D(int seed,float3 p,float voxelSize){
    //voxelSize(方块的大小)
    p /= voxelSize;
    int3 voxelIdx = floor(p);
    float dp[8]; //<dist_vec,gradient> 的点积
    for(int i=0;i<8;++i){
        int3 currentVoxelIdx = (voxelIdx + voxelVertexIdx[i]);
        //计算随机梯度
        float3 gradient = ComputeGradient(seed,currentVoxelIdx);
        //计算真实顶点的coord
        float3 vertex_coord = float3(currentVoxelIdx);
        dp[i] = dot((p-vertex_coord),gradient);
    }
    
    //tri-linear 插值
    float3 v00 = voxelIdx;
    float3 t = (p-v00);

    //float res = SmoothLerp(SmoothLerp(dp00,dp10,tx),SmoothLerp(dp01,dp11,tx),ty);
    //float res = lerp(lerp(lerp(dp[0],dp[4],t.x),lerp(dp[1],dp[5],t.x),t.z),lerp...)
    float res = SmoothLerp(SmoothLerp(SmoothLerp(dp[0],dp[4],t.x),SmoothLerp(dp[1],dp[5],t.x),t.z),SmoothLerp(SmoothLerp(dp[2],dp[6],t.x),SmoothLerp(dp[3],dp[7],t.x),t.z),t.y);
    return res;
}

//Perlin Noise with Fractal Brownian Motion
float PerlinNoise3D_FBM6(int seed,float3 p,float voxelSize){
    //some rotation matrix
    float3x3 mat = {
        0.8f,0.6f,0,
        -0.6f,0.8f,0,
        0,0,1.0f
    };
    float f = 0.0f;
    int numFbmSteps = 6;
    float multiplier[6] = {2.02f,2.03f,2.01f,2.04f,2.01f,2.02f};
    float amp = 1.0f;
    for(int i=0;i<numFbmSteps;++i){
        f+=amp * PerlinNoise3D(seed,p,voxelSize);
        p = mul(mat,p) * multiplier[i]; //2.0f
        amp *=0.5f;
    }
    return f;
}