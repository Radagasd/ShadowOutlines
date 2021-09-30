Shader "KelvinvanHoorn/ShadowOutlines_Finished"
{
    Properties
    {
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

            float4 frag (Varyings IN) : SV_Target
            {
                float4 shadowCoord = TransformWorldToShadowCoord(IN.posWS);
                float shadow = MainLightRealtimeShadow(shadowCoord);

                float3 col = float3(1, 1, 1) * shadow;

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