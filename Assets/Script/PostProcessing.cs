using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PostProcessing : MonoBehaviour
{
    public Material mat;
    public Texture2D noiseTex;

    void Start()
    {
        //mat.SetTexture("_NoiseTex", noiseTex);
		Camera cam = GetComponent<Camera>();
		cam.depthTextureMode = cam.depthTextureMode | DepthTextureMode.Depth;
    }

    void FixedUpdate()
    {
        // Scale speed of water droplets
        //mat.SetFloat("_NoiseOffset", Time.time * 0.05f);
    }

    void OnRenderImage(RenderTexture src, RenderTexture dst)
    {
        Graphics.Blit(src, dst, mat);
    }
}
