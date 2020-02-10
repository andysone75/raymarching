Shader "Unlit/RayMarcher"
{
    Properties
    {
		_Radius("Sphere Radius", float) = .5
		_Position("Sphere Position", vector) = (0,0,0,0)

		_BoxSize("Box Size", vector) = (.5,.5,.5,0)
		_BoxPosition("Box Position", vector) = (0,0,0,0)
		_BoxRotationY("Box Rotation Y", float) = 0

		_SmoothBlending("Smooth Blending", Range(0,2)) = 32

		_Ambient("Ambient", Color) = (0,0,0,0)
		_Diffuse("Diffuse", Color) = (1,0,0,0)
		_Specular("Specular", Color) = (1,1,1,0)
		_Shininess("Shininess", float) = 1

		_AmbientIntensity("Ambient Intensity", Range(0,1)) = .5
		_DiffuseIntensity("Diffuse Intensity", Range(0,1)) = .5
		_SpecularIntensity("Specular Intensity", Range(0,1)) = .5
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
				float d = length(p) - _Radius;
				return d;
			}

			float4 _BoxSize;
			float _BoxRadius;

			float BoxSDF(float3 p) {
				float3 q = abs(p) - _BoxSize;
				float d = length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
				return d;
			}

			float4 _Position;
			float4 _BoxPosition;
			float _BoxRotationY;
			float _SmoothBlending;

			float4x4 rotateY(float theta) {
				float c = cos(theta);
				float s = sin(theta);

				return float4x4(
					float4(c, 0, s, 0),
					float4(0, 1, 0, 0),
					float4(-s, 0, c, 0),
					float4(0, 0, 0, 1)
					);
			}

			float smin(float a, float b, float k) {
				// polynomial smooth min
				float h = clamp(.5 + .5 * (b - a) / k, 0.0, 1.0);
				return lerp(b, a, h) - k * h * (1.0 - h);
			}

			/*float GetDist(float3 p) {
				float d1 = SphereSDF(p + _Position + float3(0, _SinTime.w, 0) / 2);
				float3 boxP = (mul(rotateY(_BoxRotationY), (p + _BoxPosition))).xyz;
				float d2 = BoxSDF(boxP);
				return smin(d1, d2, _SmoothBlending);
			}*/

			float GetDist(float3 p) {
				float d = SphereSDF(p + _Position);
				return d;
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

			float3 GetNormal(float3 p) {
				float e = 1e-2;
				float3 n = float3(
					GetDist(float3(p.x + e, p.y, p.z)) - GetDist(float3(p.x - e, p.y, p.z)),
					GetDist(float3(p.x, p.y + e, p.z)) - GetDist(float3(p.x, p.y - e, p.z)),
					GetDist(float3(p.x, p.y, p.z + e)) - GetDist(float3(p.x, p.y, p.z - e))
					);
				return normalize(n);
			}

			float4 _Ambient;
			float _AmbientIntensity;

			float4 _Diffuse;
			float _DiffuseIntensity;
			float4 _LightPos;

			float4 _Specular;
			float _SpecularIntensity;
			float _Shininess;

			float NotNegative(float n) {
				if (n < 0) return 0;
				return n;
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
					float3 p = ro + rd * d;
					float3 n = GetNormal(p);

					float3 l = normalize(_WorldSpaceLightPos0 - p);
					float3 r = 2 * NotNegative(dot(l, n)) * n - l;
					col.rgb = 
						_Ambient.rgb * _AmbientIntensity
						+ _Diffuse.rgb * NotNegative(dot(l, n)) * _DiffuseIntensity
						+ _Specular.rgb * pow(NotNegative(dot(r, -rd)), _Shininess) * _SpecularIntensity;
					col.rgb = n;
				}
				
                return col;
            }
            ENDCG
        }
    }
}
