Shader "Hidden/Universal Render Pipeline/Blit"
{
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"}
        LOD 100

        Pass
        {
            Name "Blit"
            ZTest Always
            ZWrite Off
            Cull Off

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma vertex Vertex
            #pragma fragment Fragment

            #pragma multi_compile _ _LINEAR_TO_SRGB_CONVERSION _SRGB_TO_LINEAR_CONVERSION //Add by Yumiao, 加入MultiCompile, 否则不生效

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #if defined(_LINEAR_TO_SRGB_CONVERSION) || defined(_SRGB_TO_LINEAR_CONVERSION)
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #endif

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                half4 positionCS    : SV_POSITION;
                half2 uv            : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            TEXTURE2D_X(_BlitTex);
            SAMPLER(sampler_BlitTex);

            Varyings Vertex(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.uv = UnityStereoTransformScreenSpaceTex(input.uv);
                return output;
            }

            half4 Fragment(Varyings input) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                half4 col = SAMPLE_TEXTURE2D_X(_BlitTex, sampler_BlitTex, input.uv);
                
                //Add by Yumiao Todo 这里测试的时候复用Blit, 没有单独写一个BlitShader
                //后续看是否需要单独为sRGB修正做一个Blit着色器
                #ifdef _SRGB_TO_LINEAR_CONVERSION
                col = SRGBToLinear(col);
                #endif
                //End Add
                
                #ifdef _LINEAR_TO_SRGB_CONVERSION
                col = LinearToSRGB(col);
                #endif
                return col;
            }
            ENDHLSL
        }
    }
}
