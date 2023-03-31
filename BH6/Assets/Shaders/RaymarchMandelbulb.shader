Shader "Unlit/Raymarch Mandelbulb"
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

			#include "UnityCG.cginc"

			#define MAX_STEPS 100
			#define MAX_DIST 100
			#define SURF_DIST .001 

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

			// theta -- angle vector makes with the XY plane
			// psi -- angle the projected vector on the XY plane makes with the X axis
			// note: this might not be the usual convention
			inline void cartesian_to_polar(float3 p, out float r, out float theta, out float psi)
			{
				r = length(p);
				float r1 = p.x*p.x + p.y*p.y;
				theta = atan(p.z / r1); // angle vector makes with the XY plane
				psi	= atan(p.y / p.x); // angle of xy-projected vector with X axis
			}


			// theta -- angle vector makes with the XY plane
			// psi -- angle the projected vector on the XY plane makes with the X axis
			// note: this might not be the usual convention	
			inline void polar_to_cartesian(float r, float theta, float psi, out float3 p)
			{
				p.x = r * cos(theta) * cos(psi);
				p.y = r * cos(theta) * sin(psi);
				p.z = r * sin(theta);
			}
			
			float Mandelbulb(float3 c){
				// i believe that similar to the mandelbrot, the mandelbulb is enclosed in a sphere of radius 2 (hence the delta) 
				const float delta = 2;	
				
				float3 p = c;
				float dr = 2.0, r = 1.0;

				int ii;
				for(ii = 0; ii < 10; ii++)
				{			
					// equation used: f(p) = p^_Exponent + c starting with p = 0			

					// get polar coordinates of p
					float theta, psi;
					cartesian_to_polar(p, r, theta, psi);

					// rate of change of points in the set
					dr = .5 * pow(r, .5 - 1) *dr + 1.0;

					// find p ^ .5
					r = pow(r,.5);
					theta *= .5;
					psi *= .5;

					// convert to cartesian coordinates
					polar_to_cartesian(r, theta, psi, p);
					
					// add c
					p += c;

					// check for divergence
					if (length(p) > delta) {
						break;
					}
				}

				// return r;
				return log(r) * r / dr; // Greens formula
			}

			//Returns distsance from point p to the scene
			float GetDist(float3 p){
				float d;
				//sphere
				//d = length(p) - .5; 

				//torus
				//d = length(float2(length(p.xz) - .5, p.y)) - .1;

				// int n = 8;
				// int maxIterations = 10;
				// int iteration = 0;
				// float3 zeta;
				// while(true){
					// 	float r = sqrt(zeta.x * zeta.x + zeta.y * zeta.y + zeta.z * zeta.z);
					// 	float theta = atan2(sqrt(zeta.x * zeta.x + zeta.y * zeta.y), zeta.z);
					// 	float phi = atan2(zeta.y, zeta.z);

					// 	float3 c = float3(r, theta, phi);

					// 	float newx = pow(c.x, n) * sin(c.y * n) * cos(c.z * n);
					// 	float newy = pow(c.x, n) * sin(c.y * n) * sin(c.z * n);
					// 	float newz = pow(c.x, n) * cos(c.z * n);

					// 	zeta.x = newx + c.x;
					// 	zeta.y = newy + c.y;
					// 	zeta.z = newz + c.z;

					// 	iteration++;

					// 	if(c.r > 2){
						// 		break;
					// 	}

					// 	if(iteration > maxIterations){
						// 		d += length(c) - .1;
						// 		break;
					// 	}
				// }

				d = Mandelbulb(p);		

				return d;
			}

			//Returns the distance to the scene along depth of the viewing ray
			float Raymarch(float3 ro, float3 rd){
				float dO = 0, dS;
				for(int i = 0; i < MAX_STEPS; i++){
					float3 p = ro + dO * rd;
					dS = GetDist(p);
					dO += dS;
					if(dS < SURF_DIST || dO > MAX_DIST) break;
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
				float2 uv = i.uv - .5f;

				//origin
				// float3 ro = float3(0, 0, -3);
				float3 ro = i.ro;

				//direction
				// float3 rd = normalize(float3(uv.x, uv.y, 1));
				float3 rd = normalize(i.hitPos - ro);

				float d = Raymarch(ro, rd);

				//texture
				fixed4 tex = tex2D(_MainTex, i.uv);

				fixed4 col = 0;
				
				//mask
				float m = dot(uv, uv);

				//coloring of hits
				if(d < MAX_DIST){
					float3 p = ro + rd * d;
					float3 n = GetNormal(p);
					col.rgb = n;
					} else {
					//don't render pixel
					discard;
				}

				// col = lerp(col, tex, smoothstep(.1, .2, m));

				return col;
			}
			ENDCG
		}
	}
}