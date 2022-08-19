using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraNormalsTexture : MonoBehaviour
{
    [SerializeField]
    Shader normalsShader;

    private RenderTexture renderTexture;
    private new Camera normalCamera;

    // Start is called before the first frame update
    void Start()
    {
        Camera thisCamera = GetComponent<Camera>();

        renderTexture = new RenderTexture(thisCamera.pixelWidth, thisCamera.pixelHeight, 24);
        Shader.SetGlobalTexture("_CameraNormalsTexture", renderTexture);

        GameObject copy = new GameObject("Noramls Camera");
        normalCamera = copy.AddComponent<Camera>();
        normalCamera.CopyFrom(thisCamera);
        normalCamera.transform.SetParent(transform);
        normalCamera.targetTexture = renderTexture;
        normalCamera.SetReplacementShader(normalsShader, "RenderType");
        normalCamera.depth = thisCamera.depth - 1;
    }
}
