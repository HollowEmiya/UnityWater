Shader "Water/SinWaveShader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _Amplitude ("Amplitude", Float) = 1.0
        _WaveLength ("WaveLength", Float) = 10.0
        _WaveSpeed ("WaveSpeed", Float) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows vertex:vert addshadow

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        float _Amplitude;
        float _WaveLength;
        float _WaveSpeed;

        void vert(inout appdata_full vertexData)
        {
            float3 p = vertexData.vertex.xyz;
            float k = 2 * UNITY_PI / _WaveLength;
            // wave to right, sample to left,so kx - speed*time
            float f = k * (p.x - _WaveSpeed * _Time.y);
            p.x += _Amplitude * cos(f);
            p.y = _Amplitude * sin(f);
            // tangnet 是波的对x一次导数,画个图就知道了
            float3 tangent = normalize(float3(1 - k * _Amplitude * sin(f), k * _Amplitude * cos(f), 0));
            float3 normal = float3( -tangent.y, tangent.x, 0);  // z 方向恒定，模拟xy法线，切线和法线垂直
            
            vertexData.vertex.xyz = p;
            vertexData.normal = normal;
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
