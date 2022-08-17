Shader "Water/ToneWaterShader"
{
    Properties
    {
        // _MainTex ("Texture", 2D) = "white" {}
        _SurfaceNoiseCutoff("Surface Noise Cutoff", Range(0,1)) = 0.4
        _SurfaceNoise ("Surface Noise", 2D) = "white" {}
        _DepthGradientShallow ("Depth Gradient Shallow", Color) = (0.325, 0.807, 0.971, 0.725)
        _DepthGradientDeep ("Depth Gradient Deep", Color) = (0.086, 0.407, 1, 0.749)
        _DepthMaxDistance ("Depth Maximum Distance", Float) = 1.0
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalRenderPipeline"
            //"RenderPipeline"="UniversalPipeline"softxm;
            "Queue"="Geometry"
            "RenderType"="Opaque"
        }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"

        CBUFFER_START(UnityPerMaterial)
        //// float4 _MainTex_ST;
        float4 _SurfaceNoise_ST;
        CBUFFER_END

        ENDHLSL        

        Pass
        {
            Name "ToneWaterShader"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            float4 _DepthGradientShallow;
            float4 _DepthGradientDeep;
            float _DepthMaxDistance;
            float _SurfaceNoiseCutoff;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 uv : TEXCOORD0;
            };

            struct v2f
            {
                //float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 screenPosition : TEXCOORD0;
                float2 noiseUV : TEXCOORD1;
            };

            TEXTURE2D(_SurfaceNoise);
            SAMPLER(sampler_SurfaceNoise);
            
            v2f vert (appdata v)
            {
                v2f o;
                VertexPositionInputs positionInputs = GetVertexPositionInputs(v.vertex.xyz); 
                VertexNormalInputs normalInputs = GetVertexNormalInputs(v.normal, v.tangent);
                
                o.vertex = positionInputs.positionCS;
                o.screenPosition = ComputeScreenPos(o.vertex);
                o.noiseUV = TRANSFORM_TEX(v.uv, _SurfaceNoise);
                return o;
            }
            
            // https://zhuanlan.zhihu.com/p/410519787
            float4 frag (v2f i) : SV_Target
            {
                // sample the texture
                //float4 col = tex2D(_MainTex, i.uv);
                float existingDepth01 = SampleSceneDepth(i.screenPosition.xy/i.screenPosition.w).r;
                float depth = LinearEyeDepth(existingDepth01,_ZBufferParams);
                /*
                * float3 ndcPos = i.screenPosition.xyz / i.screenPosition.w;
                * float2 screenUV = ndcPos.xy;
                * float depth = LinearEyeDepth(SampleSceneDepth(screenUV.xy), _ZBufferParams);
                */
                float depthDifference = depth - i.screenPosition.w;

                float waterDepthDifference01 = saturate(depthDifference / _DepthMaxDistance);
                float4 waterColor = lerp(_DepthGradientShallow, _DepthGradientDeep, waterDepthDifference01);

                float surfaceNoiseSample = SAMPLE_TEXTURE2D(_SurfaceNoise,sampler_SurfaceNoise,i.noiseUV).r > _SurfaceNoiseCutoff ? 0 : 1;

                return waterColor+surfaceNoiseSample;
            }
            ENDHLSL
        }
    }
}
