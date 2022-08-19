using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

// ²Î¿¼:https://www.jianshu.com/p/ef5dfa7c7e0b
// Maybe this is the best way for NormalsTexture
// https://ever17.xyz/SSR/
public class URPCameraNormalTexture : ScriptableRendererFeature
{
    // the pass we used
    CameraNormalTexturePass cameraNormalTexPass;
    // save shader's date
    
    class CameraNormalTexturePass : ScriptableRenderPass
    {
        
        
        // This method is called before executing the render pass.
        // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
        // When empty this render pass will render to the active camera render target.
        // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
        // The render pipeline will ensure target setup and clearing happens in a performant manner.
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
        }

        public void SetUp(RenderTargetIdentifier source)
        {
            
        }

        // Here you can implement the rendering logic.
        // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
        // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
        // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {

        }

        // Cleanup any allocated resources that were created during the execution of this render pass.
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
        }
    }

    
    /// <inheritdoc/>
    public override void Create()
    {
        cameraNormalTexPass = new CameraNormalTexturePass();

        // Configures where the render pass should be injected.
        cameraNormalTexPass.renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if(cameraNormalTexPass == null)
        {
            return;
        }
        var src = renderer.cameraColorTarget;

        renderer.EnqueuePass(cameraNormalTexPass);
    }
}


