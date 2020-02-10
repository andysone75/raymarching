Shader "Unlit/InfiniteSpheres"
{
    Properties
    {
		_Radius("Sphere Radius", float) = .5
		_Position("Sphere Position", vector) = (0,0,0,0)
		_Position2("Sphere 2 Position", vector) = (0,0,0,0)

		_SmoothBlending("Smooth Blending", Range(0,2)) = 32
    }
    SubShader
    {
		Cull off
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
#define SURF_DIST 1e-3

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
				o.ro = _WorldSpaceCameraPos;
				o.hitPos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

			float _Radius;

			float SphereSDF(float3 p) {
				float d = distance(p % 2.0, float3(1, 1, 1)) - _Radius;
				return d;
			}

			float4 _Position;
			float4 _Position2;
			float _SmoothBlending;

			float smin(float a, float b, float k) {
				// polynomial smooth min
				float h = clamp(.5 + .5 * (b - a) / k, 0.0, 1.0);
				return lerp(b, a, h) - k * h * (1.0 - h);
			}

			float GetDist(float3 p) {
				float d1 = SphereSDF(p + _Position);
				float d2 = SphereSDF(p + _Position2);
				return smin(d1, d2, _SmoothBlending);
			}

			float Raymarch(float3 ro, float3 rd) {
				float dO = 0;
				float dS;
				for (int i = 0; i < MAX_STEPS; i++) {
					float3 p = ro + dO * rd;
					dS = GetDist(p);
					dO += dS;
					if (dS < SURF_DIST || dO > MAX_DIST) break;
				}

				return dO;
			}

            fixed4 frag (v2f i) : SV_Target
            {
				float3 ro = i.ro;
				float3 rd = normalize(i.hitPos - ro);
				float d = Raymarch(ro, rd);

                fixed4 col = 0;

				if (d >= MAX_DIST)
					discard;
				else {
					col.rgb = float3(1.0 / d, 1.0 / d, 1.0 / d);
				}
				
                return col;
            }
            ENDCG
        }
    }
}
