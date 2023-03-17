Shader "Unlit/Mandelbrot"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_Area("Area", vector) = (0,0,4,4)
		_Color("Color", Color) = (1,1,1,1)
		_Iterations("Iterations", int) = 100
	}

		SubShader
		{
			Tags { "RenderType" = "Opaque" }
			LOD 100

			Pass
			{
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag

				#include "UnityCG.cginc"

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
				float4 _Area;
				float4 _Scale;
				int _Iterations;
				float4 _Color;

				v2f vert(appdata v)
				{
					v2f o;
					o.vertex = UnityObjectToClipPos(v.vertex);
					o.uv = TRANSFORM_TEX(v.uv, _MainTex);
					return o;
				}

				fixed4 frag(v2f i) : SV_Target
				{
					float2 c = _Area.xy + (i.uv - .5) * _Area.zw;
					float2 z;
					for (float iter = 0; iter < _Iterations; iter++)
					{
						z = float2(z.x * z.x - z.y * z.y, 2 * z.x * z.y) + c;
						if (length(z) > 2) break;
					}
					return (iter / 255) * _Color;
				}
				ENDCG
			}
		}
}
