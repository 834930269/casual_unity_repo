Shader "Custom/Bump"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Normal("Normal Map",2D) = "bump" {}
        _Bumpiness ("Bumpiness",Range(0,1)) = 0
    }
    SubShader
    {
        CGPROGRAM
        //定义表面函数名为surf,使用Lambert
        #pragma surface surf Lambert

        //Input
        struct Input {
            float2 uv_MainTex;
            float2 uv_Normal;
        };

        sampler2D _Normal;
        fixed _Bumpiness;
        sampler2D _MainTex;
        fixed4 _Color;

        void surf(Input IN, inout SurfaceOutput o) {
            //采样法线贴图并解包
            fixed3 n = UnpackNormal(tex2D(_Normal, IN.uv_Normal));
            n *= float3(_Bumpiness, _Bumpiness, 1);
            fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            o.Normal = n;
        }

        ENDCG
    }
    FallBack "Diffuse"
}
