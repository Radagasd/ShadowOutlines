Shader "Unlit/ShadowOutlines"
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

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

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
                float3 col = float3(1, 1, 1);

                return float4(col, 1);
            }
            ENDHLSL
        }
    }
}