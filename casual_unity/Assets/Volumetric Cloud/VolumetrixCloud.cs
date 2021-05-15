using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class VolumetrixCloud : MonoBehaviour
{
    public Mesh drawMesh;
    public Material meshMat;
    
    [HideInInspector]
    private int drawLayer = 20;
    [HideInInspector]
    private float layerDist = 0.003f;
    [HideInInspector]
    private float alphaEnhance = 0.04f;

    MaterialPropertyBlock block;
    Matrix4x4[] mat4X4;

    private bool isOpetional = false;
    // Start is called before the first frame update
    void Start()
    {
        BuildVolumetrixCloud();
    }

    // Update is called once per frame
    void Update()
    {
        if (isOpetional)
        {
            Graphics.DrawMeshInstanced(drawMesh, 0, meshMat, mat4X4, drawLayer, block);
        }
    }

    void BuildVolumetrixCloud()
    {
        block = new MaterialPropertyBlock();
        mat4X4 = new Matrix4x4[drawLayer];
        float[] alphaClip = new float[drawLayer];
        float[] height = new float[drawLayer];

        for(int i = 0; i < drawLayer; ++i)
        {
            mat4X4[i] = Matrix4x4.TRS(Vector3.zero, Quaternion.Euler(-90,0,0), new Vector3(10,10,10));
            //alphaClip[i] = i * alphaEnhance;

            alphaClip[i] = alphaEnhance*i;

            height[i] = i * layerDist;
        }
        block.SetFloatArray("_Height", height);
        block.SetFloatArray("_AlphaClipThreshold", alphaClip);
        isOpetional = true;
    }
}
