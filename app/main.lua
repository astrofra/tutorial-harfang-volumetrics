
hg = require("harfang")

hg.InputInit()
hg.WindowSystemInit()

res_x, res_y = 1280, 720
win = hg.RenderInit('Volumetrics Scene', res_x, res_y, hg.RF_VSync | hg.RF_MSAA4X)

hg.AddAssetsFolder("assets_compiled")

--
pipeline = hg.CreateForwardPipeline()
res = hg.PipelineResources()


-- load scene
scene = hg.Scene()
hg.LoadSceneFromAssets("main.scn", scene, res, hg.GetForwardPipelineInfo())

-- AAA pipeline
pipeline_aaa_config = hg.ForwardPipelineAAAConfig()
pipeline_aaa = hg.CreateForwardPipelineAAAFromAssets("core", pipeline_aaa_config, hg.BR_Equal, hg.BR_Equal)
pipeline_aaa_config.sample_count = 1

-- main loop
frame = 0

while not hg.ReadKeyboard():Key(hg.K_Escape) and hg.IsWindowOpen(win) do
	dt = hg.TickClock()

    -- -- world matrix of the mesh you're drawing (the volumetric cylinder)
    -- local M      = node:GetTransform():GetWorld()
    -- local invM   = hg.Inverse(M)  -- InverseFast is fine too
    -- local camWS  = hg.GetT(camera:GetTransform():GetWorld())
    -- local camOBJ = invM * camWS   -- point world -> object

    -- bgfx.setUniform(uCamObj,  {camOBJ.x, camOBJ.y, camOBJ.z, 0.0})

    -- -- set your cylinder dimensions in *object space*
    -- -- if the mesh has radius Robj and height Hobj in OBJ space:
    -- bgfx.setUniform(uCylDims, {Robj, yminOBJ, ymaxOBJ, edgeWidth})

    -- -- raymarch params
    -- bgfx.setUniform(uVolCyl,  {1.0, 16.0, 8.0, 0.1})
    -- bgfx.setUniform(uVolTint, {1.0, 1.0, 1.0, 1.0})

	trs = scene:GetNode('cylinder'):GetTransform()
	trs:SetRot(trs:GetRot() + hg.Vec3(0, hg.Deg(15) * hg.time_to_sec_f(dt), 0))

	scene:Update(dt)
	hg.SubmitSceneToPipeline(0, scene, hg.IntRect(0, 0, res_x, res_y), true, pipeline, res, pipeline_aaa, pipeline_aaa_config, frame)

	frame = hg.Frame()
	hg.UpdateWindow(win)
end

hg.RenderShutdown()
hg.DestroyWindow(win)
