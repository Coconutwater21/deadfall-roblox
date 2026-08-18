--!strict
-- Client entry point: camera, input, HUD. Movement itself relies on
-- Roblox's default WASD character controller (see InputController).
local CameraController = require(script.Parent.CameraController)
local InputController = require(script.Parent.InputController)
local HUDMain = require(script.Parent.HUD.HUDMain)
local ShotEffects = require(script.Parent.ShotEffects)

CameraController.start()
InputController.start()
HUDMain.start()
ShotEffects.start()
