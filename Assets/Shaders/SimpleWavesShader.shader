Shader "Water/SimpleWavesShader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _Amplitude ("Amplitude", Float) = 1.0
        _WaveLength ("WaveLength", Float) = 1.0
        _WaveSpeed ("WaveSpeed", Float) = 1.0
    }
    SubShader
    {
        Tags { "IgnoreProjector"="True" "RenderType"="Opaque" "DisableBatching"="True"}
        Pass{
            Tags{"LightMode"="ForwardBase"}


            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            sampler2D _MainTex;

            half _Glossiness;
            half _Metallic;
            fixed4 _Color;
            fixed4 _Specular;
            
            float _Amplitude;
            float _WaveLength;
            float _WaveSpeed;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldViewDir : TEXCOORD2;
                SHADOW_COORDS(3)
            };

            v2f vert(a2v v)
            {
                float k = 2 * UNITY_PI / _WaveLength;
                float3 pos = v.vertex.xyz;
                float f = k * ( pos.x - _WaveSpeed * _Time.y);
                pos.x += _Amplitude * cos(f);
                pos.y = _Amplitude * sin(f);
                float3 tangent = normalize( float3(1 - _Amplitude * k * sin(f), k * _Amplitude * cos(f), 0 ));
                float3 normal = float3( -tangent.y, tangent.x, 0);

                v.vertex.xyz = pos;
                v.normal = normal;

                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
                TRANSFER_SHADOW(o);
                return o;
            }

            fixed3 frag(v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 worldViewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                fixed3 reflectDir = normalize(reflect(-worldLightDir,worldNormal));

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                fixed3 diffuse = _Color.rgb * _LightColor0.rgb * saturate(dot(worldNormal, worldLightDir));
                //fixed3 halfDir = normalize(worldLightDir + worldViewDir);
                //fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(worldNormal, halfDir)), _Glossiness);
                
                return fixed4(ambient + diffuse, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
