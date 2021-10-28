Shader "KelvinvanHoorn/ShadowOutlines_Finished"
{
    Properties
    {
        _ShadowStep ("Shadow step value", Range(0, 1)) = 0.1
        _ShadowMin ("Minimum shadow value", Range(0, 1)) = 0.2
        _OutlineColor ("Outline color", Color) = (0, 0, 0, 1)
        _ShadowDilation ("Shadow dilation", Range(0, 10)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalRenderPipeline"}
        Cull Back

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 vertex   : POSITION;
                float3 normal   : NORMAL;
            };

            struct Varyings
            {
                float4 posCS        : SV_POSITION;
                float3 posWS        : TEXCOORD0;
                float3 normalWS     : TEXCOORD1;
            };

            Varyings vert(Attributes IN)
			{
				Varyings OUT = (Varyings)0;;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(IN.vertex.xyz);
                OUT.posCS = vertexInput.positionCS;
                OUT.posWS = vertexInput.positionWS;

				VertexNormalInputs normalInput = GetVertexNormalInputs(IN.normal);
                OUT.normalWS = normalInput.normalWS;

				return OUT;
			}

            float _ShadowStep, _ShadowMin, _ShadowDilation;
            float3 _OutlineColor;

            // 3x3 sample points
            static float2 sobelSamplePoints[9] = {
                float2(-1, 1), float2(0, 1), float2(1, 1),
                float2(-1, 0), float2(0, 0), float2(1, 0),
                float2(-1, -1), float2(0, -1), float2(1, -1)
            };

            static float sobelXKernel[9] = {
                1, 0, -1,
                2, 0, -2,
                1, 0, -1
            };

            static float sobelYKernel[9] = {
                1, 2, 1,
                0, 0, 0,
                -1, -2, -1
            };

            // Calculate the Sobel operator of the shadowmap
            float ShadowSobelOperator(float4 shadowCoord, float dilation)
            {
                // Get the shadowmap texelsize
                ShadowSamplingData shadowSamplingData = GetMainLightShadowSamplingData();
                float4 shadowMap_TexelSize = shadowSamplingData.shadowmapSize;

                // Initialise results
                float sobelX = 0;
                float sobelY = 0;

                // Loop over sample points
                [unroll] for (int i = 0; i < 9; i++)
                {
                    // Sample shadowmap
                    float shadowImage = MainLightRealtimeShadow(float4(shadowCoord.xy + sobelSamplePoints[i] * dilation * shadowMap_TexelSize.xy, shadowCoord.zw));

                    // Sum the convolution values
                    sobelX += shadowImage * sobelXKernel[i];
                    sobelY += shadowImage * sobelYKernel[i];
                }

                // Return the magnitude
                return sqrt(sobelX * sobelX + sobelY * sobelY);
            }

            float4 frag (Varyings IN) : SV_Target
            {
                float4 shadowCoord = TransformWorldToShadowCoord(IN.posWS);
                float shadowMap = MainLightRealtimeShadow(shadowCoord);

                float NdotL = saturate(dot(_MainLightPosition.xyz, IN.normalWS));
                
                float combinedShadow = min(NdotL, shadowMap);
                float shadowValue = saturate(step(_ShadowStep, combinedShadow) + _ShadowMin);
                
                float shadowOutlineMask = ShadowSobelOperator(shadowCoord, _ShadowDilation / pow(2, shadowCoord.w));
                // Mask, 1 = shadowmap shadows, 0 = no shadowmap shadows
                shadowOutlineMask *= (1 - step(_ShadowStep, shadowMap));
                // Mask, 1 = no NdotL shadows, 0 = NdotL shadows
                shadowOutlineMask *= step(_ShadowStep, NdotL);

                float3 col = float3(1, 1, 1) * shadowValue;
                col = lerp(col, _OutlineColor, saturate(shadowOutlineMask));

                return float4(col, 1);
            }
            ENDHLSL
        }
        pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual
            ColorMask 0

            HLSLPROGRAM
 
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #pragma vertex vert
			#pragma fragment frag

            struct Attributes
            {
                float4 vertex   : POSITION;
                float3 normal   : NORMAL;
            };
 
            struct Varyings
            {
                float4 posCS        : SV_POSITION;
            };

            float3 _LightDirection;

            Varyings vert(Attributes IN)
			{
				    Varyings OUT = (Varyings)0;
                    VertexPositionInputs vertexInput = GetVertexPositionInputs(IN.vertex.xyz);
                    float3 posWS = vertexInput.positionWS;

                    VertexNormalInputs normalInput = GetVertexNormalInputs(IN.normal);
                    float3 normalWS = normalInput.normalWS;

                    // Shadow biased ClipSpace position
                    float4 positionCS = TransformWorldToHClip(ApplyShadowBias(posWS, normalWS, _LightDirection));

                    #if UNITY_REVERSED_Z
                        positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
                    #else
                        positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
                    #endif

                    OUT.posCS = positionCS;

                    return OUT;
			}
 
            float4 frag (Varyings IN) : SV_Target
            {
                return 0;
            }
            ENDHLSL
        }
    }
}