using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Camera))]
[ExecuteInEditMode]
public class BrightnessSaturationContrast : MonoBehaviour
{
    //关联后期处理Shader;
    public Shader EffectShader;

    //亮度、饱和度、对比度属性
    public float Brightness = 1f;
    public float Saturation = 1f;
    public float Contrast = 1f;

    private Material EffectMaterial;

    // Start is called before the first frame update
    void Start()
    {
        EffectMaterial = new Material(EffectShader);
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        //判断有无关联Shader文件
        //如果有,则进行值传递
        //没有,不作任何处理

        if (EffectShader)
        {
            EffectMaterial.SetFloat("_Brightness", Brightness);
            EffectMaterial.SetFloat("_Saturation", Saturation);
            EffectMaterial.SetFloat("_Contrast", Contrast);

            Graphics.Blit(source, destination, EffectMaterial);
        }
        else
        {
            Graphics.Blit(source, destination);
        }
    }

    private void Update()
    {
        Brightness = Mathf.Clamp(Brightness, 0f, 2f);
        Saturation = Mathf.Clamp(Saturation, 0f, 2f);
        Contrast = Mathf.Clamp(Contrast, 0f, 2f);
    }
}
