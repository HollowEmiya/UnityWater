Shader "Water/SimpleWave"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Specular ("Specular", Color) = (1,1,1,1)
        _Glossiness ("Smoothness", Range(8,256)) = 20
        _Metallic ("Metallic", Range(0,1)) = 0.0
        
        //_Amplitude ("Amplitude", Float) = 1.0
        //_WaveSpeed ("WaveSpeed", Float) = 1.0
        /** *
        * _Direction ("Direction(2D)", Vector) = ( 1,0,0,0 )
        * _Steepness ("Steepness", Range(0, 1)) = 0.5
        * _WaveLength ("WaveLength", Float) = 1.0
        */
        _WaveA ("WaveA (dir_x,dir_y,steepness,length)", Vector) = (1.0, 1.0, 0.5, 20)    // dir_x,dir_y,steepness,length
        _WaveB ("WaveB", Vector) = (0.5, 1.0, 0.5, 40)
        _WaveC ("WaveC", Vector) = (0.2, 1.0, 0.4, 5)
        _Gravity ("Gravity", Float) = 9.8
    }
    SubShader
    {
        Tags { "IgnoreProjector"="True" "RenderType"="Opaque" "DisableBatching"="True"}
        Pass{
            Name "SimpleWave"
            Tags{"LightMode"="ForwardBase"}
            

            CGPROGRAM
            #include "UnityCustomRenderTexture.cginc"
            #pragma vertex CustomRenderTextureVertexShader
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #pragma target 3.0

            sampler2D _MainTex;

            half _Glossiness;
            half _Metallic;
            fixed4 _Color;
            fixed4 _Specular;            
            
            //float _Amplitude;
            //float _WaveSpeed;
            /**
             * float2 _Direction;
             * float _Steepness;
             * float _WaveLength;
            */
            float _Gravity;
            float4 _WaveA;
            float4 _WaveB;
            float4 _WaveC;

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

            float3 GerstnerWave( float4 wave, float3 pos, inout float3 tangent, inout float3 binormal)
            {
                float steepness = wave.z;
                float waveLength = wave.w;
                float k = 2 * UNITY_PI / waveLength;
                float c = sqrt( _Gravity / k);
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

            v2f vert(a2v v)
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
                //fixed3 reflectDir = normalize(reflect(-worldLightDir,worldNormal));

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                fixed3 diffuse = _Color.rgb * _LightColor0.rgb * saturate(dot(worldNormal, worldLightDir));
                fixed3 halfDir = normalize(worldLightDir + worldViewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(worldNormal, halfDir)), _Glossiness);
                
                return fixed4(ambient + diffuse + specular, 1.0);
            }
            ENDCG
        }
    }
}
