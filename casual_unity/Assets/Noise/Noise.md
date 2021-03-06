# 噪声

## (white noise)白噪声

> 用随机数来实现白噪声  
- 伪随机数生成器一般是基于上一个状态实现的,需要存储状态,Shader不适合  
- 复杂的哈希函数(Hash Function) *H(x,y) *无状态

如何生成一个白噪声呢?

比如下面这段HLSL代码,提供了一个随便凑的函数

**输入: **某种坐标如float2,int2等  
**输出: **[0,1]的float值  

```
float WhiteNoise(int seed,int i,int j){
	float r = frac(sin(dot(float2(i,cos(j)),float2(float(seed) + 12.9898,float(seed) + 78.233)))*43758.5453);
	return r;
}
```

Pixel Shader/Fragment Shader

```
float frag(v2f pixel) :SV_Target
{
	int gridCount = 200；
	fixed4 col = WhiteNoise(123,pixel.uv.x * gridCount,pixel.uv.y*gridCount);
	return col;
}
```

通过UV坐标的x,y值计算当前(x,y)点处的像素或者片元的颜色,由gridCount 如上代码,就可以渲染出200*200的白噪声

> 这点解释一下

因为这个哈希函数是固定的,甚至没有碰撞检测,所以输入什么,输出的一定是什么.

1. UV的取值范围是[0,1]
2. frac函数返回标量或每个矢量中各分量的小数部分
3. 所以x*gridCount 就类似于0-1等分gridCOunt块,每块都有一个唯一的整数 (因为x是小数,而参数转int向下取整)
4. 所以每块的颜色是相同的

frac实现原理:  
```
float frac(float v)
{
  // floor函数返回值会向下取值
  // floor实验部分可查看《Shader实验室：floor函数》
  return v - floor(v);
}

```


## (Perlin Noise) 柏林噪声


![](http://146.56.209.11:90/wp-content/uploads/2021/03/wp_editor_md_a152d545e60ca5baf5f98b73f55f474f.jpg)

柏林噪声是`Ken Perlin`在1983年提出的,是一种梯度噪声

分三步:

- 格点定义(Grid Definition)
- 求点积(Dot Product)
- 插值(Interpolation)


1. 定义格点

![](http://146.56.209.11:90/wp-content/uploads/2021/03/wp_editor_md_3f57022ac2eb1886a6d8888da7fdc162.jpg)

在每个格点上随机的求一个梯度  

```
//把0-1的白噪声映射到-1~1
float HashGrid(int seed,int i,int j){
	float r = WhiteNoise(seed,i,j);
	r = r * 2.0f -1.0f;
	return r; 
}

//梯度两个分量用不同的随机数种子
float2 ComputeGradient(int seed,int gridX,int gridY){
	float2 gradient = float2(
		HashGrid(seed*123+345,gridX,gridY),
		HashGrid(seed*456+234,gridX,gridY)
	);
	return normalize(gradient);
}

```

2. 求点积

![](http://146.56.209.11:90/wp-content/uploads/2021/03/wp_editor_md_448e962af49532223467cbe3d808984a.jpg)

求梯度和格点到着色点的点积

3. 双线性插值

![](http://146.56.209.11:90/wp-content/uploads/2021/03/wp_editor_md_4baca88d5d400ab7972baf39c2036dc4.jpg)

> 代码: 

```
float res = lerp(lerp(dp00,dp10,tx),lerp(dp01,dp11,tx),ty);

```

线性插值会出现的问题:

![](http://146.56.209.11:90/wp-content/uploads/2021/03/wp_editor_md_a00f0ae8e03b26d8e4b68e997e87e3b2.jpg)

**不平滑过渡**

故使用smoothstep插值: 

![](http://146.56.209.11:90/wp-content/uploads/2021/03/wp_editor_md_05726fdb08ba65ff848032fa9b009553.jpg)

可以看到在x=0和1除是平滑的


## (Value Noise) 值噪声


值噪声必须附加其他的平滑过渡才可以得到一个比较好的结果

![](http://146.56.209.11:90/wp-content/uploads/2021/03/wp_editor_md_d9b5f3cb52c5176bd2325f0c6249bc6b.jpg)

他的思想是在每个格点处直接定义一个值,而不是梯度


## (Worley Noise) 沃利噪声

> 沃利噪声比较好看,长的像细胞

![](http://146.56.209.11:90/wp-content/uploads/2021/03/wp_editor_md_e85bbb53f14bb9fa2b01f57d11d67623.jpg)

主要分两步:  

1. 生成随机点  
使用方格作为随机点生成的基础  
如何在方格内找到随机点呢,可以基于方格的中心位置叠加一个偏移向量  

![](http://146.56.209.11:90/wp-content/uploads/2021/03/wp_editor_md_2fba95a88beef78f34174e69d1c882a4.jpg)

这点可以借用Perlin Noise的随机梯度生成

至于如何计算每个着色点对应哪个随机点,利用格点的思路,只需要计算当前着色点周围九个格子那个随机点距离它最近即可

![](http://146.56.209.11:90/wp-content/uploads/2021/03/wp_editor_md_00b3b6886b071398d299765f4a7e90cf.jpg)


如果用 1-W(i)作为颜色渲染, 得到的结果和W(i)是相反的

![](http://146.56.209.11:90/wp-content/uploads/2021/03/wp_editor_md_e4a556611bd4cb5204456a514e5035e4.jpg)

# 增加噪声细节和变化

增加噪声细节可以增加噪声的细节

## Fractal Brownian Motion 分形布朗运动

- 分形布朗运动FBM(Fractal Brownian Motion)
- 一种增加噪声细节的方法
- 有些文献也称之为湍(tuan)流 Turbulence  
- 叠加一系列不同频率、不同振幅的噪声

![](http://146.56.209.11:90/wp-content/uploads/2021/03/wp_editor_md_fbbdc2de0f91855c668394c990e98b4a.jpg)

### 公式

### 示例: 迭代六次的FBM如何用于Perlin Noise

![](http://146.56.209.11:90/wp-content/uploads/2021/03/wp_editor_md_7140f5cbe4a0a01cefcd13a6dc3ff590.jpg)

```
float PerlinNoiseFBM6(int seed,float2 p,float gridSize){
	float f = 0.0f;
	int numFbmSteps = 6; // 叠加的分量个数
	float amp = 1.0f; // 振幅
	for(int i=0;i<numFbmSteps;++i){
		f+=amp * PerlinNoise(seed,p,gridSize);//叠加的噪声分量
		p *= 2.0f;//下一个噪声分量频率*2
		amp *= 0.5f; // 下一个噪声分量振幅*0.5
	}
	return f;
}
```

### 效果图

![](http://146.56.209.11:90/wp-content/uploads/2021/03/wp_editor_md_ddc568166ff74738591b0294c40c1859.jpg)

Value Noise 的四阶FBM

![](http://146.56.209.11:90/wp-content/uploads/2021/03/wp_editor_md_a203c3c31974262234273851e58b7b74.jpg)


## Domain Warping 定义域扭曲

![](http://146.56.209.11:90/wp-content/uploads/2021/03/wp_editor_md_a8fb0da694f25819b762082fc7d70720.jpg)

比如使用Perlin Noise来计算经过扰动的UV

```
fixed4 frag(v2f pixel) : SV_Target
{
	float2 distorted_uv = float2(PerlinNoiseFBM6(123,pixel.uv,0.2f),PerlinNoiseFBM6(425,pixel.uv,0.2f));
	float3 col = PerlinNoiseFBM6(42,distorted_uv,0.5f);
	return fixed4(col,1.0f);
}
```


# 代码解析

`PerlinWorleyNoiseGenerator3D.cginc`

> 哈希函数写的3D WhiteNoise (哈希函数)

```
float WhiteNoise3D(int seed,int i,int j,int k){
    float r = frac(cos(44.54f * k + 232.02f * sin(dot(float2(i,cos(j)),float2(float(seed) + 12.9898,float(seed)+78.233))) * 45.5453));
    return r;
}
```

> HashVoxel (通过白噪声计算格点,*2-1是将格点映射到[-1,1]范围内)

```
float HashVoxel(int seed,int3 voxelIdx){
    float r = WhiteNoise3D(seed,voxelIdx.x,voxelIdx.y,voxelIdx.z);
    r = r*2.0f-1.0f;//[-1,1]
    return r;
}
```

> ComputeGradient(计算格点上的梯度值,这里就是随机三个格点上的值,然后归一化)

```
float3 ComputeGradient(int seed,int3 voxelIdx){
    float3 gradient = float3(
        HashVoxel(seed * 123+345,voxelIdx),
        HashVoxel(seed * 456 + 234,voxelIdx),
        HashVoxel(seed * 789 +123, voxelIdx));
    return normalize(gradient);
}
```

> SmoothLerp(平滑差值,上面有说)

```
float SmoothLerp(float min,float max,float t){
    t=t*t*t*(t*(t*6.0f-15.0f) + 10.0f);
    return min + t * (max-min);
}
```


> 计算3D的柏林噪声

```
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

```


> 添加FBM_6(分型布朗运动(湍流))细化影响

```
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
```


## Shader 层

> Shader负责将时间作为变量传递过来,影响变化

```
Shader "Unlit/PerlinNoiseSliceAnim"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "../cg/PerlinWorleyNoiseGenerator3D.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag(v2f pixel) : SV_Target
            {
                //a moving rect intersects with 3D perlin noise
                float3 col = PerlinNoise3D_FBM6(123,float3(pixel.uv,_Time.x),0.3f);
                return fixed4(col,1.0f);
            }
            ENDCG
        }
    }
}

```

