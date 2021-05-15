using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class PostEffectsBase : MonoBehaviour
{
    protected void CheckResources()
    {
        bool isSupported = CheckSupport();
        if (isSupported == false)
        {
            NotSupported();
        }
    }

    protected bool CheckSupport()
    {
        //过时了,必然return true
        if(SystemInfo.supportsImageEffects == false || SystemInfo.supportsRenderTextures == false)
        {
            return false;
        }
        return true;
    }

    protected void NotSupported()
    {
        enabled = false;
    }

    // Start is called before the first frame update
    void Start()
    {
        CheckResources();
    }

    /// <summary>
    /// 生成一个新的material
    /// </summary>
    /// <param name="shader"></param>
    /// <param name="material"></param>
    /// <returns></returns>
    protected Material CheckShaderAndCreateMaterial(Shader shader,Material material)
    {
        if (shader == null)
        {
            return null;
        }
        if(shader.isSupported && material && material.shader == shader)
        {
            return material;
        }
        if (!shader.isSupported) return null;
        else
        {
            material = new Material(shader);
            material.hideFlags = HideFlags.DontSave;
            if (material) return material;
            else return null;
        }
    }
}
