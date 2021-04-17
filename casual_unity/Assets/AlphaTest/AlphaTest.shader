﻿Shader "Custom/AlphaTest"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _AlphaTest("Alpha Test",Range(0,1)) = 0
    }
    SubShader
    {
        Tags { 
            "Queue" = "AlphaTest"
            "RenderType" = "TransparentCutout"
            "IgnoreProjector" = "True"
        }

        Pass
        {
            Tags {
                "LightMode" = "ForwardBase"
            }
            Cull Off
            //抗锯齿
            AlphaToMask On

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"

            struct v2f {
                float4 pos : SV_POSITION;
                float4 worldPos : TEXCOORD0;
                float2 texcoord : TEXCOORD1;
                float3 worldNormal : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _AlphaTest;

            v2f vert(appdata_base v) {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);

                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldNormal = normalize(worldNormal);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target{
                float3 worldLight = UnityWorldSpaceLightDir(i.worldPos.xyz);
                worldLight = normalize(worldLight);

                fixed NdotL = saturate(dot(i.worldNormal, worldLight));

                fixed4 color = tex2D(_MainTex, i.texcoord);

                //开始Aplha测试
                clip(color.a - _AlphaTest);

                color.rgb *= NdotL * _LightColor0;
                color.rgb += unity_AmbientSky;

                return color;
            }

            ENDCG
        }
    }
}
