using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DepthOfFiled : PostEffectBase
{
    [Range(0.0f, 100.0f)]
    public float focalDistance = 10.0f;
    [Range(0.0f, 100.0f)]
    public float nearBlurScale = 0.0f;
    [Range(0.0f, 1000.0f)]
    public float farBlurScale = 50.0f;

    public int downSample = 1;
    public int sampleScale = 1;

    private Camera _mainCamera;

    public Camera MainCamera
    {
        get
        {
            if (_mainCamera == null)
            {
                _mainCamera = GetComponent<Camera>();
            }
            return _mainCamera;
        }
    }

    private void OnEnable()
    {
        MainCamera.depthTextureMode |= DepthTextureMode.Depth;
    }

    private void OnDisable()
    {
        MainCamera.depthTextureMode &= ~DepthTextureMode.Depth;
    }

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (_Material)
        {
            RenderTexture temp1 = RenderTexture.GetTemporary(src.width >> downSample, src.height >> downSample, 0, src.format);
            RenderTexture temp2 = RenderTexture.GetTemporary(src.width >> downSample, src.height >> downSample, 0, src.format);

            Graphics.Blit(src, temp1);

            _Material.SetVector("_offsets", new Vector4(0, sampleScale, 0, 0));
            Graphics.Blit(temp1, temp2, _Material, 0);
            temp1.DiscardContents();
            _Material.SetVector("_offsets", new Vector4(sampleScale, 0, 0, 0));
            Graphics.Blit(temp2, temp1, _Material, 0);

            _Material.SetTexture("_BlurTex", temp1);
            _Material.SetFloat("_focalDistance", FocalDistance01(focalDistance));
            _Material.SetFloat("_nearBlurScale", nearBlurScale);
            _Material.SetFloat("_farBlurScale", farBlurScale);
            Graphics.Blit(src, dest, _Material, 1);

            RenderTexture.ReleaseTemporary(temp1);
            RenderTexture.ReleaseTemporary(temp2);
        }
    }

    //计算设置的焦点被转换到01空间中的距离，以便shader中通过这个01空间的焦点距离与depth比较
    private float FocalDistance01(float distance)
    {
        return MainCamera.WorldToViewportPoint((distance - MainCamera.nearClipPlane) * MainCamera.transform.forward + MainCamera.transform.position).z / (MainCamera.farClipPlane - MainCamera.nearClipPlane);
    }
}
