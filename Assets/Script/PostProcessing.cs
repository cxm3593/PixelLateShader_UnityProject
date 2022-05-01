using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PostProcessing : MonoBehaviour
{
    public Material mat;
    public Texture2D noiseTex;
    public RenderTexture ID_texture;
    public List<Color> palette = new List<Color>();

    void Start()
    {
        //mat.SetTexture("_NoiseTex", noiseTex);
		Camera cam = GetComponent<Camera>();
		cam.depthTextureMode = cam.depthTextureMode | DepthTextureMode.Depth;

        ID_texture = new RenderTexture(Screen.width, Screen.height, 0) {
            antiAliasing = 1,
            filterMode = FilterMode.Point,
            autoGenerateMips = false,
            depth = 24
        };

        //palette = new Color[16];
    }

    void Update(){
        mat.SetColorArray("palette_color", palette.ToArray());
        mat.SetFloat("palette_color_number", palette.Count);
    }

    void FixedUpdate()
    {
        // Scale speed of water droplets
        //mat.SetFloat("_NoiseOffset", Time.time * 0.05f);
    }

    void OnRenderImage(RenderTexture src, RenderTexture dst)
    {
        Graphics.Blit(src, dst, mat);
        Graphics.Blit(src, ID_texture);
    }
}
