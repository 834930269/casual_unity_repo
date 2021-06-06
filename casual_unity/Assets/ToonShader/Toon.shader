Shader "Custom_My/Toon"
{
	Properties{
		_Color("Color",Color) = (1,1,1,1)
		_HColor("HighlightColor",Color) = (1,1,1,1)
		_SColor("ShadowColor",Color) = (1,1,1,1)
		_SPecColor("SpecularColor",Color) = (1,1,1,1)
		_RimColor("RimColor",Color) = (1,1,1,1)


		
		_MainTex("Main Texture",2D) = "white" {}
		_RampThreshold("RampThreshold",Range(0,1)) = 3
		_RampSmooth("RampSmooth",Range(0,1)) = 0
		_SPecSmooth("SpecularSmooth",Range(0,1)) = 0
		_Shininess("Shininess ",Range(0,1)) = 0
		_RimThreshold("RimThreshold",Range(0,1)) = 0
		_RimSmooth("RimSmooth",Range(0,1)) = 0
		_ToonSteps("ToonSteps",Range(0,5)) = 3

	}

	SubShader{
		Tags {"RenderType" = "Opaque"}
		CGPROGRAM
		#pragma surface surf Toon addshadow fullforwardshadows exclude_path::deferred exclude_path::prepass
		#pragma target 3.0

		fixed4 _Color;
		fixed4 _HColor;
		fixed4 _SColor;
		fixed4 _SPecColor;
		fixed4 _RimColor;
		sampler2D _MainTex;
		fixed _RampThreshold;
		fixed _RampSmooth;
		fixed _SpecSmooth;
		fixed _RimSmooth;
		fixed _Shininess;
		fixed _RimThreshold;
		fixed _ToonSteps;

		struct Input {
			float2 uv_MainTex;
			float3 viewDir;
		};

		float linearstep(float min, float max, float t)
		{
			return saturate((t - min) / (max - min));
		}

		inline fixed4 LightingToon(SurfaceOutput s, half3 lightDir, half3 viewDir, half atten) {
			half3 normalDir = normalize(s.Normal);
			float ndl = max(0, dot(normalDir, lightDir));
			float ndv = max(0, dot(normalDir, viewDir));
			float rim = (1.0 - ndv) * ndl;
			rim *= atten;
			rim = smoothstep(_RimThreshold - _RimSmooth * 0.5, _RimThreshold + _RimSmooth * 0.5, rim);


			fixed3 lightColor = _LightColor0.rgb;

			fixed3 rimColor = _RimColor.rgb * lightColor * _RimColor.a * rim;

			float diff = smoothstep(_RampThreshold - ndl, _RampThreshold + ndl, ndl);
			float ramp = floor(diff * _ToonSteps) / _ToonSteps;
			float interval = 1 / _ToonSteps;
			float level = round(diff * _ToonSteps) / _ToonSteps;
			if (_RampSmooth == 1)
			{
				ramp = interval * linearstep(level - _RampSmooth * interval * 0.5, level + _RampSmooth * interval * 0.5, diff) + level - interval;
			}
			else
			{
				ramp = interval * smoothstep(level - _RampSmooth * interval * 0.5, level + _RampSmooth * interval * 0.5, diff) + level - interval;
			}
			ramp = max(0, ramp);
			ramp *= atten;
			_SColor = lerp(_HColor, _SColor, _SColor.a);
			
			float3 rampColor = lerp(_SColor.rgb, _HColor.rgb, ramp);
			

			fixed4 color;
			fixed3 diffuse = s.Albedo * lightColor * rampColor;

			half3 halfDir = normalize(lightDir + viewDir);
			float ndh = max(0, dot(normalDir, halfDir));
			float spec = pow(ndh, s.Specular) * s.Gloss;
			spec *= atten;
			spec = smoothstep(0.5 - _SpecSmooth * 0.5, 0.5 + _SpecSmooth * 0.5, spec);
			fixed3 specular = _SpecColor.rgb * lightColor * spec;

			color.rgb = diffuse + specular + rimColor;
			color.a = s.Alpha;
			return color;
		}

		void surf(Input IN, inout SurfaceOutput o) {
			fixed4 mainTex = tex2D(_MainTex, IN.uv_MainTex);
			o.Albedo = mainTex.rgb * _Color.rgb;
			o.Alpha = mainTex.a * _Color.a;

			o.Specular = _Shininess;
			o.Gloss = mainTex.a;
		}

		ENDCG
	}
}
