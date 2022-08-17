Shader "Water/UPRSimpleWaveShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color("Color", Color) = (1,1,1,1)
        _WaveA ("WaveA (dir_x,dir_y,steepness,length)", Vector) = (1.0, 1.0, 0.5, 20)    // dir_x,dir_y,steepness,length
        _WaveB ("WaveB", Vector) = (0.5, 1.0, 0.5, 40)
        _WaveC ("WaveC", Vector) = (0.2, 1.0, 0.4, 5)
        _Specular ("Specular", Color) = (1,1,1,1)
        _Glossiness ("Smoothness", Range(8,256)) = 20
        _WaveGravity ("WaveGravity", Float) = 9.8
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "Queue"="Geometry"
            "RenderType"="Opaque"
        }
        
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        
        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        float4 _Color;
        float4 _Specular;
        float _Glossiness;
        float _Gravity;
        float4 _WaveA;
        float4 _WaveB;
        float4 _WaveC;
        float _WaveGravity;
        CBUFFER_END

        ENDHLSL

        Pass
        {
            Name "UPRSimpleWaveShader"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            #pragma vertex vert
            #pragma fragment frag

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                //float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                //float2 uv : TEXCOORD0;
                //UNITY_FOG_COORDS(1)
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldViewDir : TEXCOORD2;
                
            };

            float3 GerstnerWave( float4 wave, float3 pos, inout float3 tangent, inout float3 binormal)
            {
                float steepness = wave.z;
                float waveLength = wave.w;
                float k = 2 * 3.14 / waveLength;
                float c = sqrt( _WaveGravity / k);
                float2 dir = wave.xy;
                float f = k * ( dot(dir,pos.xz) - c * _Time.y);
                float amplitude = steepness / k;

                tangent += float3(
                    -dir.x * dir.x * steepness * sin(f),
                    dir.y * steepness * cos(f),
                    -dir.y * dir.x * steepness * sin(f));

                binormal += float3(
                    -dir.x * dir.y * steepness * sin(f),
                    dir.y * steepness * cos(f),
                    -dir.y * dir.y * steepness * sin(f));
                
                return float3(
                    dir.x * amplitude * cos(f),
                    amplitude * sin(f),
                    dir.y * amplitude * cos(f)); 
           }

            v2f vert (a2v v)
            {
                float3 gridPoint = v.vertex.xyz;
                float3 tangent = float3(1,0,0);
                float3 binormal = float3(0,0,1);
                gridPoint += GerstnerWave(_WaveA,gridPoint,tangent,binormal);
                gridPoint += GerstnerWave(_WaveB,gridPoint,tangent,binormal);
                gridPoint += GerstnerWave(_WaveC,gridPoint,tangent,binormal);

                v.vertex.xyz = gridPoint;
                v.normal = normalize(cross(binormal,tangent));

                v2f o;
                o.pos = mul(UNITY_MATRIX_MVP,v.vertex);
                o.worldNormal = mul(UNITY_MATRIX_M,v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldViewDir = normalize(GetCameraPositionWS() - o.worldPos);
                //o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                //UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                // sample the texture
                float4 col = _Color;
                // apply fog
                //UNITY_APPLY_FOG(i.fogCoord, col);
                float3 worldNormal = normalize(i.worldNormal);
                Light light = GetMainLight();
                float3 worldLightDir = normalize(light.direction);
                float3 worldViewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                float3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                float3 diffuse = _Color.rgb * saturate(dot(worldNormal, worldLightDir));
                float3 halfDir = normalize(worldLightDir + worldViewDir);
                float3 specular = _Specular.rgb * pow(saturate(dot(worldNormal, halfDir)), _Glossiness);
                
                return float4(ambient + diffuse + specular, 1.0);
            }
            ENDHLSL
        }
    }
}
