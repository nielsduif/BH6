Shader "Unlit/Raymarch Mandelbulb"
{
	Properties
	{
		//_MainTex ("Texture", 2D) = "white" {}

		//mandelbulb
		_Exponent ("Exponent", Range(0, 50)) = 1
		_Iterations ("Iterations", Range(1, 50)) = 50

		//raymarch
		_MaxSteps ("Max Steps", int) = 100
		_MaxDist ("Max Distance", int) = 100
		_SurfDist ("Surface Distance", int) = .001

		//color
		_ColorX ("Color X", Color) = (0,0,0,0)
		_ColorY ("Color Y", Color) = (0,0,0,0)
		_ColorZ ("Color Z", Color) = (0,0,0,0)

		//rt adjustments
		_Speed ("Speed", float) = 1
	}
	
	SubShader
	{
		Tags {"RenderType" = "Opaque" }
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
				float3 ro : TEXCOORD1;
				float3 hitPos : TEXCOORD2;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			float _Exponent;
			float _Iterations;

			int _MaxSteps;
			int _MaxDist;
			int _SurfDist;

			float4 _ColorX;
			float4 _ColorY;
			float4 _ColorZ;

			float _Speed;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);

				//world space
				o.ro = _WorldSpaceCameraPos;
				o.hitPos = mul(unity_ObjectToWorld, v.vertex);

				//object space with homogeneous coordinates
				// o.ro = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
				// o.hitPos = v.vertex;
				
				return o;
			}

			inline void cartesian_to_polar(float3 p, out float r, out float theta, out float psi)
			{
				r = length(p);
				float r1 = p.x * p.x + p.y *  p.y;
				theta = atan(p.z / r1); // angle vector makes with the XY plane
				psi	= atan(p.y / p.x); // angle of xy-projected vector with X axis
			}

			inline void polar_to_cartesian(float r, float theta, float psi, out float3 p)
			{
				p.x = r * cos(theta) * cos(psi);
				p.y = r * cos(theta) * sin(psi);
				p.z = r * sin(theta);
			}
			
			float Mandelbulb(float3 c){				
				//radius of inside sphere of the mandelbulb 
				const float delta = 2;	
				
				float3 p = c;
				float dr = 2, r = 1;

				float se = _Exponent, si = _Iterations;

				//iteration increase/decrease
				//si = lerp(_Iterations - 1, _Iterations + 1, sin(_Time.y * .5 + .5) * _Speed);

				for(int i = 0; i < si; i++)
				{		
					//easing between exponents	
					se = lerp(_Exponent - .5, _Exponent + .5, sin(_Time.y * _Speed));

					// convert cart to polar
					float theta, psi;
					cartesian_to_polar(p, r, theta, psi);

					// rate change of points
					dr = se * pow(r, se - 1) * dr + 1.0;

					// find p ^ .5
					r = pow(r, se);
					theta *= se;
					psi *= se;

					// convert to cartesian coordinates
					polar_to_cartesian(r, theta, psi, p);
					
					// add c
					p += c;

					// check if point is outside range of mandelbulb
					if (length(p) > delta) {
						break;
					}
				}

				// Greens method
				return log(r) * r / dr; 
			}

			float Sphere(float3 p, float r){
				return length(p) - r;
			}

			float Box(float3 p, float w){
				float3 d = abs(p) - w;
				return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
			}

			float Torus(float3 p, float ic, float r){
				return length(float2(length(p.xz) - ic, p.y)) - r;
			}

			//Returns distance from point p to the scene
			float GetDist(float3 p){
				float cd; //combined distance

				float d1 = Mandelbulb(p);	
				float d2 = Sphere(p, .8);

				//add shapes
				// cd = min(d1, d2);

				//subtract shapes, negative is the 'hollow'
				cd = max(-d2, d1);

				return cd;
			}

			//Returns the distance to the scene along depth of the viewing ray
			float Raymarch(float3 ro, float3 rd){
				float dO = 0, dS;
				for(int i = 0; i < _MaxSteps; i++){
					float3 p = ro + dO * rd;
					dS = GetDist(p);
					dO += dS;
					if(dS < _SurfDist || dO > _MaxDist) break;
				}

				return dO;
			}

			//Calculate normal for lighting
			float3 GetNormal(float3 p){
				//epsilon
				float2 e = float2(.02, 0);
				float3 n = GetDist(p) - float3(
				GetDist(p - e.xyy),
				GetDist(p - e.yxy),
				GetDist(p - e.yyx)
				);
				return normalize(n);
			}

			fixed4 frag (v2f i) : SV_Target
			{
				//pivot
				float2 uv = i.uv + .5;

				//origin
				// float3 ro = float3(0, 0, -3);
				float3 ro = i.ro;

				//direction
				// float3 rd = normalize(float3(uv.x, uv.y, 1));
				float3 rd = normalize(i.hitPos - ro);

				float d = Raymarch(ro, rd);

				//texture
				//fixed4 tex = tex2D(_MainTex, i.uv);

				fixed4 col = 0;
				
				//mask
				//float m = dot(uv, uv);

				//coloring of hits
				if(d < _MaxDist){
					float3 p = ro + rd * d;
					float3 n = GetNormal(p);

					//col.rgb = n;
					// col.rgb = n * .5 + .5;
					col.rgb = _ColorX * n.x + _ColorY * n.y + _ColorZ * n.z;
					} else {
					//don't render pixel
					discard;
				}

				//col = lerp(col, tex, smoothstep(.1, .2, m));

				//col = lerp(_ColorX, _ColorY, sin(_Time.y * .5 + .5) * _Speed);

				return col;
			}
			ENDCG
		}
	}
}