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
                // o.ro = _WorldSpaceCameraPos;
                // o.hitPos = mul(unity_ObjectToWorld, v.vertex);

                //object space with homogeneous coordinates
                o.ro = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
                o.hitPos = v.vertex;
                return o;
            }

            //Returns distsance from point p to the scene
            float GetDist(float3 p){
                float d;
                //sphere
                d = length(p) - .5; 

                //torus
                d = length(float2(length(p.xz) - .5, p.y)) - .1;

                return d;
            }

            //Returns the distance to the scene along depth of the viewing ray
            float Raymarch(float3 ro, float3 rd){
                float dO = 0;
                float dS;
                for(int i = 0; i < MAX_STEPS; i++){
                    float3 p = ro + dO * rd;
                    dS = GetDist(p);
                    dO += dS;
                    if(dS < SURF_DIST || dO > MAX_DIST) break;
                }

                return dO;
            }

            //Calculate normal
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
                    }else{
                    //don't render pixel
                    // discard;
                }

                col = lerp(col, tex, smoothstep(.1, .2, m));

                return col;
            }
            ENDCG
        }
    }
}