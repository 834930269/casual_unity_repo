Shader "Unlit/VolumetrixCloud"
{
    Properties
    {
        _3DNoise("3D Noise", 3D) = "white" {}
        _NoiseScale("Noise Scale",float) = 1
        _Speed("Speed",float) = 1
        _BackSssStrength ("BackSssStrength",float) = 1
        _Color("Color",Color) = (1,0,1,1)
        _Intensity("Intensity",float) = 1

        _AlphaClipThreshold("Alpha Clip Threshold",float) = 0
        _Height("Height",float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Cull off
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                
                //DRAW INSTANCE需要
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float3 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldNor : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
                float4 worldPos: TEXCOORD3;

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            UNITY_INSTANCING_BUFFER_START(Props)

                UNITY_DEFINE_INSTANCED_PROP(float, _AlphaClipThreshold)
#define propsAlphaClipThreshold Props

                UNITY_DEFINE_INSTANCED_PROP(float, _Height)
#define propsHeight Props

            UNITY_INSTANCING_BUFFER_END(Props)

            sampler3D _3DNoise;
            float _NoiseScale;
            float _Speed;
            float _BackSssStrength;
            fixed4 _Color;
            float _Intensity;

            v2f vert (appdata_base v)
            {

                UNITY_SETUP_INSTANCE_ID(v);
                v2f o;
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                //o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.vertex.xyz * 0.5 + 0.5;
                o.viewDir = normalize(WorldSpaceViewDir(v.vertex));
                o.worldNor = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);

                float heigth = UNITY_ACCESS_INSTANCED_PROP(propsHeight, _Height);

                half3 flowUV = o.uv.xyz / _NoiseScale + _Time.x * _Speed * half3(1, 1, 1);

                float h = tex3Dlod(_3DNoise, float4(flowUV, 0)).r * heigth;

                //v.vertex.xyz += v.normal * h * abs(_SinTime.y);
                v.vertex.xyz += v.normal * h;
                o.vertex = UnityObjectToClipPos(v.vertex);

                //将vertex沿法线向外挤压一定距离
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {

                UNITY_SETUP_INSTANCE_ID(i);
                half3 flowUV = i.uv.xyz / _NoiseScale + _Time.x * _Speed * half3(1, 1, 1);
                half noise = tex3D(_3DNoise, flowUV).x;
                half dither = frac((sin(i.worldPos.x + i.worldPos.y) * 99 + 11) * 99);

                float clipThre = UNITY_ACCESS_INSTANCED_PROP(propsAlphaClipThreshold, _AlphaClipThreshold);
                
                //clip((noise - clipThre));
                clip((noise - clipThre)-dither/5);
                
                fixed3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                half NdotL = max(0, dot(i.worldNor, lightDir));
                half smoothNdotL = saturate(pow(NdotL, 2 - clipThre));
                half3 backLitDir = i.worldNor * _BackSssStrength * lightDir;
                half backSSS = saturate(dot(i.viewDir, -backLitDir));
                backSSS = saturate(pow(backSSS, 2 + clipThre * 2) * 1.5);
                half finalLit = saturate(smoothNdotL * 0.5 + saturate(smoothNdotL + backSSS) * (1 - NdotL * 0.5));
               

                return (_Color +(finalLit))* _Intensity;
            }
            ENDCG
        }
    }
}
