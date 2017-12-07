Shader "Hidden/DepthOfField"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_BlurTex ("Texture", 2D) = "while" {}
	}

	CGINCLUDE			
	#include "UnityCG.cginc"

	struct appdata
	{
		float4 vertex : POSITION;
		float2 uv : TEXCOORD0;
	};

	struct v2f_blur
	{
		float2 uv : TEXCOORD0;
		float4 uv01 : TEXCOORD1;
		float4 uv23 : TEXCOORD2;
		float4 uv45 : TEXCOORD3;
		float4 vertex : SV_POSITION;
	};

	struct v2f_dof
	{
		float2 uv : TEXCOORD0;
		float2 uv1 : TEXCOORD1;
		float4 vertex : SV_POSITION;
	};

			
	sampler2D _MainTex;
	sampler2D _BlurTex;
	sampler2D _CameraDepthTexture;

	//Vector4(1 / width, 1 / height, width, height)
	float4 _MainTex_TexelSize;
	float4 _offsets;

	float _focalDistance;
	float _farBlurScale;
	float _nearBlurScale;

	v2f_blur vert_blur (appdata v)
	{
		v2f_blur o;
		_offsets *= _MainTex_TexelSize.xyxy;
		o.vertex = UnityObjectToClipPos(v.vertex);
		o.uv = v.uv;
		o.uv01 = v.uv.xyxy + _offsets.xyxy * float4(1, 1, -1, -1);
		o.uv23 = v.uv.xyxy + _offsets.xyxy * float4(1, 1, -1, -1) * 2.0;
		o.uv45 = v.uv.xyxy + _offsets.xyxy * float4(1, 1, -1, -1) * 3.0;

		return o;
	}

	fixed4 frag_blur (v2f_blur i) : SV_Target
	{
		fixed4 col = fixed4(0, 0, 0, 0);
		col += 0.40 * tex2D(_MainTex, i.uv);
		col += 0.15 * tex2D(_MainTex, i.uv01.xy);
		col += 0.15 * tex2D(_MainTex, i.uv01.zw);
		col += 0.10 * tex2D(_MainTex, i.uv23.xy);
		col += 0.10 * tex2D(_MainTex, i.uv23.zw);
		col += 0.05 * tex2D(_MainTex, i.uv45.xy);
		col += 0.05 * tex2D(_MainTex, i.uv45.zw);
		return col;
	}

	v2f_dof vert_dof(appdata v)
	{
		v2f_dof o;
		o.vertex = UnityObjectToClipPos(v.vertex);
		o.uv = v.uv;
		o.uv1 = o.uv;

		//在 D3D 上使用 AA 时，主纹理与场景深度纹理
		//将在不同垂直方向出现。
		//因此在这种情况下翻转纹理采样（主纹理
		//纹理元件大小将为 Y 轴负值）。
		#if UNITY_UV_STARTS_AT_TOP
		if(_MainTex_TexelSize.y < 0)
			o.uv.y = 1.0 - o.uv.y;
		#endif

		return o;
	}

	fixed4 frag_dof(v2f_dof i) : SV_Target
	{
		fixed4 ori = tex2D(_MainTex, i.uv1);
		fixed4 blur = tex2D(_BlurTex, i.uv);

		float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
		depth = Linear01Depth(depth);

		float focalComp = saturate(sign(depth - _focalDistance));
		fixed4 final = (1 - focalComp) * ori + focalComp * lerp(ori, blur, saturate((depth - _focalDistance) * _farBlurScale));
		final = focalComp * final + (1 - focalComp) * lerp(ori, blur, saturate((_focalDistance - depth) * _nearBlurScale));
		return final;
	}

	ENDCG

	SubShader
	{
		Pass
		{
			Cull Off 
			ZWrite Off 
			ZTest Off 
			Fog { Mode Off }

			CGPROGRAM
			#pragma vertex vert_blur
			#pragma fragment frag_blur
			#pragma fragmentoption ARB_precision_hint_fastest
			ENDCG
		}

		Pass
		{
			Cull Off 
			ZWrite Off 
			ZTest Off 
			Fog { Mode Off }
			ColorMask RGBA

			CGPROGRAM
			#pragma vertex vert_dof
			#pragma fragment frag_dof
			#pragma fragmentoption ARB_precision_hint_fastest
			ENDCG
		}
	}
}
