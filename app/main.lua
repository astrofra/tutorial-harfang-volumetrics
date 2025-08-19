
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
local scene = hg.Scene()
hg.LoadSceneFromAssets("main.scn", scene, res, hg.GetForwardPipelineInfo())

local cylinder_node = scene:GetNode("cylinder")
local cylinder_material = cylinder_node:GetObject():GetMaterial(0)
local camera = scene:GetNode("Camera")

-- main loop
frame = 0

while not hg.ReadKeyboard():Key(hg.K_Escape) and hg.IsWindowOpen(win) do
	dt = hg.TickClock()

    -- world matrix of the mesh you're drawing (the volumetric cylinder)
    local M = cylinder_node:GetTransform():GetWorld()
    local _, invM = hg.Inverse(M) -- InverseFast is fine too
    local camWS = hg.GetT(camera:GetTransform():GetWorld())
    local camOBJ = invM * camWS -- point world -> object

    hg.SetMaterialValue(cylinder_material, 'uCamObj', camOBJ)

    -- -- set your cylinder dimensions in *object space*
    -- -- if the mesh has radius Robj and height Hobj in OBJ space:
    -- bgfx.setUniform(uCylDims, {Robj, yminOBJ, ymaxOBJ, edgeWidth})

	trs = scene:GetNode('cylinder'):GetTransform()
	trs:SetRot(trs:GetRot() + hg.Vec3(hg.Deg(5) * hg.time_to_sec_f(dt), hg.Deg(10) * hg.time_to_sec_f(dt), 0))

	scene:Update(dt)
	hg.SubmitSceneToPipeline(0, scene, hg.IntRect(0, 0, res_x, res_y), true, pipeline, res)

	frame = hg.Frame()
	hg.UpdateWindow(win)
end

hg.RenderShutdown()
hg.DestroyWindow(win)
