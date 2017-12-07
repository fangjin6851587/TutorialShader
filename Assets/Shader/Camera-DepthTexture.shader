Shader "Unlit/Camera-DepthTexture"
{
	SubShader
	{
		Tags { "RenderType"="Opaque" "IgnoreProjector"="True" }

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				#ifdef UNITY_MIGHT_NOT_HAVE_DEPTH_TEXTURE
				float2 depth : TEXCOORD0;
				#endif
				float4 pos : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

				//UNITY_TRANSFER_DEPTH(oo) oo = o.pos.zw
				//o.depth = o.pos.zw;
				UNITY_TRANSFER_DEPTH(o.depth);
				
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				//UNITY_OUTPUT_DEPTH(i) return i.x/i.y
				UNITY_OUTPUT_DEPTH(i.depth);
			}
			ENDCG
		}
	}
}
