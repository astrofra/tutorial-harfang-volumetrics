-- world matrix of the mesh you're drawing (the volumetric cylinder)
local M      = node:GetTransform():GetWorld()
local invM   = hg.Inverse(M)  -- InverseFast is fine too
local camWS  = hg.GetT(camera:GetTransform():GetWorld())
local camOBJ = invM * camWS   -- point world -> object

bgfx.setUniform(uCamObj,  {camOBJ.x, camOBJ.y, camOBJ.z, 0.0})

-- set your cylinder dimensions in *object space*
-- if the mesh has radius Robj and height Hobj in OBJ space:
bgfx.setUniform(uCylDims, {Robj, yminOBJ, ymaxOBJ, edgeWidth})

-- raymarch params
bgfx.setUniform(uVolCyl,  {1.0, 16.0, 8.0, 0.1})
bgfx.setUniform(uVolTint, {1.0, 1.0, 1.0, 1.0})
