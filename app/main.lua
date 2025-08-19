
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
local camera_node = scene:GetNode("Camera")

local cylinder_material = cylinder_node:GetObject():GetMaterial(0)

-- main loop
frame = 0

while not hg.ReadKeyboard():Key(hg.K_Escape) and hg.IsWindowOpen(win) do
	dt = hg.TickClock()

    -- world matrix of the mesh you're drawing (the volumetric cylinder)
    local M = cylinder_node:GetTransform():GetWorld()
    local _, invM = hg.Inverse(M) -- InverseFast is fine too
    local camWS = hg.GetT(camera_node:GetTransform():GetWorld())
    local camOBJ = invM * camWS -- point world -> object

    hg.SetMaterialValue(cylinder_material, 'uCamObj', camOBJ)

	trs = scene:GetNode('cylinder'):GetTransform()
	trs:SetRot(trs:GetRot() + hg.Vec3(hg.Deg(3) * hg.time_to_sec_f(dt), hg.Deg(7) * hg.time_to_sec_f(dt), hg.Deg(15) * hg.time_to_sec_f(dt)))
	-- trs:SetRot(trs:GetRot() + hg.Vec3(0, hg.Deg(15) * hg.time_to_sec_f(dt), 0))
	trs:SetPos(hg.Vec3(2.0 * math.sin(hg.Deg(45) * hg.time_to_sec_f(hg.GetClock())) - 1.0, 0, 0))

	scene:Update(dt)
	hg.SubmitSceneToPipeline(0, scene, hg.IntRect(0, 0, res_x, res_y), true, pipeline, res)

	frame = hg.Frame()
	hg.UpdateWindow(win)
end

hg.RenderShutdown()
hg.DestroyWindow(win)
