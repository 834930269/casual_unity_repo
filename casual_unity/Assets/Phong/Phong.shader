Shader "ShaderLab/Phong"
{
    Properties
    {
        _MainColor("Main Color", Color) = (1,1,1,1)
        _SpecularColor("Specular Color",Color) = (0,0,0,0)
        _Shininess("Shininess",Range(1,100)) = 1
    }
    SubShader
    {
        Pass
        {
            CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#include "UnityCG.cginc"
            //声明包含灯光变量的文件
#include "Lighting.cginc"
        struct v2f {
        float4 pos : SV_POSITION;
        fixed4 color : COLOR0;
};
    fixed4 _MainColor;
    fixed4 _SpecularColor;
    //光滑度
    half _Shininess;

    v2f vert(appdata_base v) {
        v2f o;
        o.pos = UnityObjectToClipPos(v.vertex);

        //计算公式中的各个变量
        float3 n = UnityObjectToWorldNormal(v.normal);
        n = normalize(n);
        fixed3 l = normalize(_WorldSpaceLightPos0.xyz);
        //WorldSpaceViewDir是顶点指向光源的方向
        fixed3 view = normalize(WorldSpaceViewDir(v.vertex));

        //漫反射部分
        fixed ndot1 = saturate(dot(n, l));
        fixed4 dif = _LightColor0 * _MainColor * ndot1;

        //镜面反射部分
        //光线反射向量
        float3 ref = reflect(-l, n);
        ref = normalize(ref);
        fixed rdotv = saturate(dot(ref, view));
        fixed4 spec = _LightColor0 * _SpecularColor * pow(rdotv, _Shininess);

        //环境光+漫反射+镜面反射
        o.color = unity_AmbientSky + dif + spec;

        return o;
        }

    fixed4 frag(v2f i) :SV_Target
    {
        return i.color;
        }
            ENDCG
        }
    }
}
