Shader "Water/ToneWaterShader"
{
    Properties
    {
        // _MainTex ("Texture", 2D) = "white" {}
        _DepthGradientShallow ("Depth Gradient Shallow", Color) = (0.325, 0.807, 0.971, 0.725)
        _DepthGradientDeep ("Depth Gradient Deep", Color) = (0.086, 0.407, 1, 0.749)
        _DepthMaxDistance ("Depth Maximum Distance", Float) = 1.0
        _SurfaceNoiseCutoff("Surface Noise Cutoff", Range(0,1)) = 0.4
        _SurfaceNoise ("Surface Noise", 2D) = "white" {}
        //_FoamDistance ("Foam Distance", Float) = 0.2
        _FoamColor ("Foam Color", Color) = (1, 1, 1, 1)
        _FoamMinDistance ("Foam Min Distance", Float) = 0.08
        _FoamMaxDistance ("Foam Max Distance", Float) = 0.4
        _SurfaceDistortion ("Surface Distortion", 2D) = "white" {}
        _SurfaceNoiseScroll ("Surface Noise Scroll Amount", Vector) = ( 0.5, 0.5, 0, 0 )
        _SurfaceDistortionAmount ("Surface Distortion Amount", Range(0, 1)) = 0.3
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalRenderPipeline"
            //"RenderPipeline"="UniversalPipeline"softxm;
            // y因为我们使用了CameraDepth所以要注意RenderQueue要大于2500
            "Queue"="Transparent"
            "RenderType"="Transparent"
        }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"

        CBUFFER_START(UnityPerMaterial)
        //// float4 _MainTex_ST;
        float4 _SurfaceNoise_ST;
        float4 _SurfaceDistortion_ST;
        CBUFFER_END

        ENDHLSL        

        Pass
        {
            Name "ToneWaterShader"
            Tags { "LightMode"="UniversalForward" }

            Blend SrcAlpha OneMinusSrcAlpha
			ZWrite Off

            HLSLPROGRAM
            #define SMOOTHSTEP_STEP 0.01
            #pragma vertex vert
            #pragma fragment frag
            
            float4 _DepthGradientShallow;
            float4 _DepthGradientDeep;
            float _DepthMaxDistance;
            float _SurfaceNoiseCutoff;
            //float _FoamDistance;
            float4 _FoamColor;
            float _FoamMinDistance;
            float _FoamMaxDistance;
            float2 _SurfaceNoiseScroll;
            float _SurfaceDistortionAmount;

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
                float3 viewNormal : NORMAL;
                float4 screenPosition : TEXCOORD0;
                float2 noiseUV : TEXCOORD1;
                float2 distortUV : TEXCOORD2;
            };

            TEXTURE2D(_SurfaceNoise);
            SAMPLER(sampler_SurfaceNoise);
            TEXTURE2D(_SurfaceDistortion);
            SAMPLER(sampler_SurfaceDistortion);
            TEXTURE2D(_CameraDepthNormalsTexture);
            SAMPLER(sampler_CameraDepthNormalsTexture);
            
            float3 DecodeNormal(float4 enc)
            {
                float kScale = 1.7777;
                float3 nn = enc.xyz*float3(2*kScale,2*kScale,0) + float3(-kScale,-kScale,1);
                float g = 2.0 / dot(nn.xyz,nn.xyz);
                float3 n;
                n.xy = g*nn.xy;
                n.z = g-1;
                return n;
            }

            float4 AlphaBlend(float4 top, float4 bottom)
            {
                float3 color = (top.rgb * top.a) + (bottom.rgb * (1 - top.a));
                float alpha = top.a + bottom.a * (1 - top.a);

                return float4(color, alpha);
            }

            v2f vert (appdata v)
            {
                v2f o;
                VertexPositionInputs positionInputs = GetVertexPositionInputs(v.vertex.xyz); 
                VertexNormalInputs normalInputs = GetVertexNormalInputs(v.normal, v.tangent);
                
                o.vertex = positionInputs.positionCS;
                o.screenPosition = ComputeScreenPos(o.vertex);
                o.noiseUV = TRANSFORM_TEX(v.uv, _SurfaceNoise);
                o.distortUV = TRANSFORM_TEX(v.uv, _SurfaceDistortion);
                o.viewNormal = normalize(mul((float3x3)UNITY_MATRIX_IT_MV, v.normal));
                return o;
            }
            
            // https://zhuanlan.zhihu.com/p/410519787
            float4 frag (v2f i) : SV_Target
            {
                // sample the texture
                //float4 col = tex2D(_MainTex, i.uv);
                float2 scrNDCPos = i.screenPosition.xyz / i.screenPosition.w;
                float existingDepth01 = SampleSceneDepth(scrNDCPos.xy).r;
                float depth = LinearEyeDepth(existingDepth01,_ZBufferParams);
                /*
                * float3 ndcPos = i.screenPosition.xyz / i.screenPosition.w;
                * float2 screenUV = ndcPos.xy;
                * float depth = LinearEyeDepth(SampleSceneDepth(screenUV.xy), _ZBufferParams);
                */
                float depthDifference = depth - i.screenPosition.w;

                float waterDepthDifference01 = saturate(depthDifference / _DepthMaxDistance);
                float4 waterColor = lerp(_DepthGradientShallow, _DepthGradientDeep, waterDepthDifference01);
                
                // Wave
                float2 distortSample = (SAMPLE_TEXTURE2D(_SurfaceDistortion,sampler_SurfaceDistortion,i.distortUV).xy * 2 - 1) * _SurfaceDistortionAmount;
    
                float2 noiseUV = float2( (i.noiseUV.x + _Time.y * _SurfaceNoiseScroll.x) + distortSample.x,
                                    (i.noiseUV.y + _Time.y * _SurfaceNoiseScroll.y) + distortSample.y);
                
                // normalTexture 和 viewNormal 差距越大说明越到物体边缘，白沫就越多
                float3 existingNormal = DecodeNormal(SAMPLE_TEXTURE2D(_CameraDepthNormalsTexture,sampler_CameraDepthNormalsTexture,scrNDCPos.xy));
                float3 normalDot = saturate(dot(existingNormal,i.viewNormal));
                float foamDistance = lerp(_FoamMaxDistance, _FoamMinDistance, normalDot);
                // distance is larger, cut off is more strict
                // 法线差越大剔除标准越小
                float foamDepthDifference01 = saturate(depthDifference / foamDistance);
                float surfaceNoiseCutoff = foamDepthDifference01 * _SurfaceNoiseCutoff;
                float surfaceNoiseSample = SAMPLE_TEXTURE2D(_SurfaceNoise,sampler_SurfaceNoise,noiseUV).r;
                float surfaceNoise = smoothstep(surfaceNoiseCutoff - SMOOTHSTEP_STEP,
                    surfaceNoiseCutoff + SMOOTHSTEP_STEP, surfaceNoiseSample);   // 标准越小越容易为1
                
                float4 surfaceNoiseColor = _FoamColor;
                surfaceNoiseColor.a *= surfaceNoise;
                
                return AlphaBlend(surfaceNoiseColor,waterColor);
            }
            ENDHLSL
        }
    }
}
